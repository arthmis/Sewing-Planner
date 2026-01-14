//
//  AppFiles.swift
//  Sewing Planner
//
//  Created by Art on 9/20/24.
//

// import AppKit
import Foundation
import SwiftUI
import System

enum AppFilesError: Error {
  case fileSave(String)
  case fileRead(String)
  case genericError(String)
}

struct AppFiles {
  // only used when the schema is changed during development
  // ensures the images don't conflict with new images
  func deleteImagesFolder() {
    let directory = getPhotosDirectoryPath()
    let fileManager = FileManager.default
    if fileManager.fileExists(atPath: directory.path()) {
      try! fileManager.removeItem(at: directory)
    }
  }

  func saveProjectImage(projectId: Int64, image: ProjectImageInput) throws -> (String, String)? {
    let fileManager = FileManager.default
    let usersPhotosUrl = getPhotosDirectoryPath()

    if !photoDirectoryExists() {
      do {
        try fileManager.createDirectory(
          at: usersPhotosUrl,
          withIntermediateDirectories: true,
          attributes: nil
        )
      } catch {
        print("Error \(error)")
        return nil
      }
    }

    let imagesFolderForProject = getProjectPhotoDirectoryPath(projectId: projectId)
    if !projectPhotoDirectoryExists(id: projectId) {
      try fileManager.createDirectory(
        at: imagesFolderForProject,
        withIntermediateDirectories: true,
        attributes: nil
      )
    }

    // get image's new file path
    let fileIdentifier = UUID().uuidString
    let newFilePath = imagesFolderForProject.appendingPathComponent(fileIdentifier)
      .appendingPathExtension(for: .png)

    let thumbnailSize = image.image.scaleDimensions(maxDimension: 300)
    let thumbnailIdentifier = UUID().uuidString

    // TODO: do this resize and create thumbnail in a background task
    let thumbnail = image.image.resizeImageTo(size: thumbnailSize)
    do {
      try createThumbnailForImage(
        withIdentifier: thumbnailIdentifier,
        forProject: projectId,
        withContents: thumbnail.pngData()
      )
    } catch {
      // TODO: figure out better logging
      NSLog("couldn't create thumbnail for image: \(fileIdentifier) for project: \(projectId)")
    }
    //        image.image.prepareThumbnail(of: thumbnailSize) { thumbnailImage in
    //            if let thumbnail = thumbnailImage {
    //                let data = thumbnail.pngData()
    //                do {
    //                    try createThumbnailForImage(withIdentifier: thumbnailIdentifier, forProject: projectId, withContents: data)
    //                } catch {
    //                    // TODO: figure out better logging
    //                    NSLog("couldn't create thumbnail for image: \(fileIdentifier) for project: \(projectId)")
    //                }
    //            }
    //        }

    let data = image.image.pngData()
    let createFileSuccess = fileManager.createFile(atPath: newFilePath.path(), contents: data)

    if !createFileSuccess {
      print("couldn't create file at file path: \(newFilePath)")
      return nil
    }

    return (fileIdentifier, thumbnailIdentifier)
  }

  func getPathForImage(forProject project: Int64, fileIdentifier: String) -> URL {
    let projectPhotosPath = getProjectPhotoDirectoryPath(projectId: project)
    return projectPhotosPath.appendingPathComponent(fileIdentifier).appendingPathExtension(
      for: .png
    )
  }

  func getImage(for file: String, fromProject projectId: Int64) -> UIImage? {
    let fileManager = FileManager.default
    let filePath = getPathForImage(forProject: projectId, fileIdentifier: file)

    if let data = fileManager.contents(atPath: filePath.path()) {
      return UIImage(data: data)
    }

    return nil
  }

  func getThumbnailImage(for file: String, fromProject projectId: Int64) throws(AppFilesError)
    -> UIImage?
  {
    let fileManager = FileManager.default
    let filePath = try getPathForThumbnail(withIdentifier: file, forProject: projectId)

    if let data = fileManager.contents(atPath: filePath.path()) {
      let image = UIImage(data: data)
      return image
    }

    return nil
  }

  func deleteImage(projectId: Int64, image: ProjectImage) throws {
    let fileManager = FileManager.default
    let filePath = getPathForImage(forProject: projectId, fileIdentifier: image.record.filePath)

    try fileManager.removeItem(at: filePath)
  }
}

extension AppFiles {
  private func getPhotosDirectoryPath() -> URL {
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let usersPhotosUrl = documentsURL.appendingPathComponent("ProjectPhotos")

    return usersPhotosUrl
  }

  func getProjectPhotoDirectoryPath(projectId: Int64) -> URL {
    let photosDirectory = getPhotosDirectoryPath()

    return photosDirectory.appendingPathComponent(String(projectId))
  }

  private func photoDirectoryExists() -> Bool {
    FileManager.default.fileExists(atPath: getPhotosDirectoryPath().path())
  }

  private func projectPhotoDirectoryExists(id: Int64) -> Bool {
    FileManager.default.fileExists(atPath: getProjectPhotoDirectoryPath(projectId: id).path())
  }
}

extension AppFiles {
  private func getAppPhotosThumbnailDirectoryPath() throws(AppFilesError) -> URL {
    do {
      let cacheUrl = try FileManager.default.url(
        for: .cachesDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: false
      )
      return cacheUrl.appendingPathComponent("ProjectPhotosThumbnails")
    } catch let error as NSError {
      switch error.code {
        case NSFileReadNoPermissionError:
          throw AppFilesError.fileRead(error.localizedDescription)
        default:
          throw AppFilesError.genericError(error.localizedDescription)
      }
    } catch {
      throw AppFilesError.genericError(error.localizedDescription)
    }
  }

  private func appPhotoThumbnailsDirectoryExists() throws(AppFilesError) -> Bool {
    try FileManager.default.fileExists(atPath: getAppPhotosThumbnailDirectoryPath().path())
  }

  private func projectPhotosThumbnailsDirectoryExists(id: Int64) throws(AppFilesError) -> Bool {
    try FileManager.default.fileExists(atPath: getProjectPhotosThumbnailsPath(projectId: id).path())
  }

  private func getProjectPhotosThumbnailsPath(projectId: Int64) throws(AppFilesError) -> URL {
    let thumbnailsDirectory = try getAppPhotosThumbnailDirectoryPath()

    return thumbnailsDirectory.appendingPathComponent(String(projectId))
  }

  func getPathForThumbnail(withIdentifier fileIdentifier: String, forProject project: Int64)
    throws(AppFilesError) -> URL
  {
    let projectPhotosPath = try getProjectPhotosThumbnailsPath(projectId: project)
    return projectPhotosPath.appendingPathComponent(fileIdentifier).appendingPathExtension(
      for: .png
    )
  }

  private func createThumbnailForImage(
    withIdentifier thumbnailIdentifier: String,
    forProject projectId: Int64,
    withContents data: Data?
  ) throws(AppFilesError) {
    let fileManager = FileManager.default

    let thumbnailsFolderForProject = try getProjectPhotosThumbnailsPath(projectId: projectId)
    if try !projectPhotosThumbnailsDirectoryExists(id: projectId) {
      do {
        try fileManager.createDirectory(
          at: thumbnailsFolderForProject,
          withIntermediateDirectories: true,
          attributes: nil
        )
      } catch {
        fatalError("Error \(error)")
      }
    }

    let thumbnailPath = try getPathForThumbnail(
      withIdentifier: thumbnailIdentifier,
      forProject: projectId
    )
    // TODO: deal with createFileSuccess
    let createFileSuccess = fileManager.createFile(atPath: thumbnailPath.path(), contents: data)
    if !createFileSuccess {
      throw .fileSave("Couldn't create thumbnail for imported image")
    }
  }
}
