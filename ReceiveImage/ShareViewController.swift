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
    let imageDataType = UTType.data.identifier
    if itemProvider.hasItemConformingToTypeIdentifier(imageDataType) {
      itemProvider.loadItem(forTypeIdentifier: imageDataType, options: nil) {
        providedImage,
        error in
        if let importError = error {
          return
        }

        if let url = providedImage as? NSURL {
          do {
            let data = try Data(contentsOf: url as URL)

            func dismissView() {
              self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            }

            DispatchQueue.main.async {
              // host the SwiftU view
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
          } catch {
            // TODO: show an error view that says couldn't load image
          }
        }
      }
    } else {
      close()
      return
    }
  }

  /// Close the Share Extension
  func close() {
    extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
  }
}
