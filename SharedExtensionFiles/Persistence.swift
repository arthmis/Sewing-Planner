//
//  Persistence.swift
//  Sewing Planner
//
//  Created by Art on 10/26/25.
//

import Foundation
import UIKit
import UniformTypeIdentifiers

struct SharedProject: Identifiable, Codable {
  let id: Int64
  let name: String
}

struct SharedImage: Codable {
  let projectId: Int64
  let fileIdentifier: String
}

enum ShareError: Error {
  case getFile(String)
  case emptyFile(String)
  case cannotFindAppGroupContainer(String)
}

struct SharedPersistence {
  let fileManager: FileManager
  let appGroup: String
  var sharedLocation: URL

  init(_ fileManager: FileManager? = nil, _ appGroup: String? = nil) throws {
    self.fileManager = fileManager ?? FileManager.default
    self.appGroup = appGroup ?? "group.SewingPlanner"
    // swift doesn't understand that sharedLocation will either be initialized or the function throws
    // it requires that I initialize it first before I can use, somehow initializing it after getPersistenceLocation
    // call doesn't count as initialization
    // so I'm using a url that should be correct to initialize it first
    self.sharedLocation = URL(string: "http://example.com")!

    guard let appGroupLocation = try getPersistenceLocation(self.appGroup) else {
      throw ShareError.cannotFindAppGroupContainer(
        "Couldn't get the location of the shared container for the app group"
      )
    }
    self.sharedLocation = appGroupLocation
  }

  func getFile(fileName: String) throws -> Data? {
    let fileUrl = constructFileLocation(
      location: self.sharedLocation,
      fileName: fileName
    )
    let data = self.fileManager.contents(atPath: fileUrl.path())
    return data
  }

  func writeFile(data: Data, fileName: String) throws {
    let fileUrl = constructFileLocation(
      location: self.sharedLocation,
      fileName: fileName
    )
    let _ = self.fileManager.createFile(
      atPath: fileUrl.path(),
      contents: data
    )
  }

  func saveImage(fileIdentifier: String, image: Data) throws {
    let imagesDirectory = try createImagesDirectory(at: "SharedImages")
    let imagePath = imagesDirectory.appending(path: fileIdentifier)
      .appendingPathExtension(for: .png)
    let success = self.fileManager.createFile(
      atPath: imagePath.path(),
      contents: image
    )

    if !success {
      // TODO: throw an error or do something
    }
  }

  func getImage(withIdentifier fileIdentifier: String) throws -> Data {
    let imagesDirectory = try createImagesDirectory(at: "SharedImages")
    let imagePath = imagesDirectory.appending(path: fileIdentifier)
      .appendingPathExtension(for: .png)
    guard let data = self.fileManager.contents(atPath: imagePath.path()) else {
      throw ShareError.getFile("Couldn't get shared image")
    }

    return data
  }

  func deleteImage(withIdentifier fileIdentifier: String) throws {
    let imagesDirectory = try createImagesDirectory(at: "SharedImages")
    let imagePath = imagesDirectory.appending(path: fileIdentifier)
      .appendingPathExtension(for: .png)
    try self.fileManager.removeItem(atPath: imagePath.path())
  }

  private func createImagesDirectory(at directory: String) throws -> URL {
    let imagesDirectory = sharedLocation.appending(path: directory)
    try self.fileManager.createDirectory(
      at: imagesDirectory,
      withIntermediateDirectories: true,
      attributes: nil
    )

    return imagesDirectory
  }

  private func constructFileLocation(location: URL, fileName: String) -> URL {
    let fileLocation = location.appending(path: fileName)
      .appendingPathExtension(for: .json)

    return fileLocation
  }

  private func getPersistenceLocation(_ appGroup: String) throws -> URL? {
    return self.fileManager.containerURL(
      forSecurityApplicationGroupIdentifier: appGroup
    )
  }

  #if DEBUG
    func removeSharedData() throws {
      let fileManager = FileManager.default

      let projectsUrl = constructFileLocation(
        location: self.sharedLocation,
        fileName: "projects"
      )
      do {

        try fileManager.removeItem(
          at: projectsUrl
        )
      } catch {
        print(error.localizedDescription)
      }

      let sharedImagesFileUrl = constructFileLocation(
        location: self.sharedLocation,
        fileName: "sharedImages"
      )
      do {

        try fileManager.removeItem(
          atPath: sharedImagesFileUrl.path(),
        )
      } catch {
        print(error.localizedDescription)
      }

      let imagesFolderPath = self.sharedLocation.appending(
        path: "SharedImages"
      )
      do {

        try fileManager.removeItem(at: imagesFolderPath)
      } catch {
        print(error.localizedDescription)
      }
    }
  #endif
}
