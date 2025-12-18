//
//  ShareViewController.swift
//  ReceiveImage
//
//  Created by Art on 10/24/25.
//

import Social
import SwiftUI
import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()

    // Ensure access to extensionItem and itemProvider
    guard
      let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
      let itemProvider = extensionItem.attachments?.first
    else {
      // TODO: do some error handling
      close()
      return
    }

    // Check type identifier
    let imageDataType = UTType.image.identifier
    let urlDataType = UTType.url.identifier
    let jpegDataType = UTType.jpeg.identifier
    let pngDataType = UTType.png.identifier
    print(itemProvider.registeredTypeIdentifiers())
    if itemProvider.hasItemConformingToTypeIdentifier(imageDataType) {
      itemProvider.loadItem(forTypeIdentifier: imageDataType, options: nil) {
        providedItem,
        error in
        if let importError = error {
          print("import error")
          return
        }

        var imageData: Data?

        if let url = providedItem as? URL {
          imageData = try? Data(contentsOf: url)
        } else if let data = providedItem as? Data {
          imageData = data
        } else if let image = providedItem as? UIImage {
          imageData = image.pngData()
        }

        if let data = imageData {
          DispatchQueue.main.async {
            self.displayView(data: data)
          }
        } else {
          // TODO: show an error view that says couldn't load image
          print("error reading image data")
        }
      }
    } else if itemProvider.hasItemConformingToTypeIdentifier(urlDataType) {
      itemProvider.loadItem(forTypeIdentifier: urlDataType, options: nil) {
        providedItem,
        error in
        if let importError = error {
          print("import error")
          return
        }

        guard let url = providedItem as? URL else {
          print("somehow not a url")
          return
        }

        print(url)
        if url.isFileURL {
          let imageData = try? Data(contentsOf: url)

          if let data = imageData {
            DispatchQueue.main.async {
              self.displayView(data: data)
            }
          } else {
            // TODO: show an error view that says couldn't load image
            print("error reading image data")
          }
        } else {
          let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
              print("Failed to download image: \(error?.localizedDescription ?? "unknown")")
              return
            }

            DispatchQueue.main.async {
              self.displayView(data: data)
            }
          }
          task.resume()
        }
      }
    }
  }

  func displayView(data: Data) {
    func dismissView() {
      self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    // host the SwiftUI view
    let contentView = UIHostingController(
      rootView: ReceiveImageView(image: data, dismiss: dismissView)
    )
    self.addChild(contentView)
    self.view.addSubview(contentView.view)
    contentView.view.backgroundColor = UIColor.white
    contentView.view.isOpaque = true

    // set up constraints
    contentView.view.translatesAutoresizingMaskIntoConstraints = false
    contentView.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
    contentView.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive =
      true
    contentView.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
    contentView.view.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive =
      true
  }

  /// Close the Share Extension
  func close() {
    extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
  }
}
