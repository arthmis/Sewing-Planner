//
//  ImageViewModel.swift
//  Sewing Planner
//
//  Created by Art on 10/30/24.
//

import GRDB
import PhotosUI
import SwiftUI

@MainActor @Observable
class ProjectImages {
  let projectId: Int64
  var images: [ProjectImage] = []
  var deletedImages: [ProjectImage] = []

  var selectedImages: Set<String?> = []
  var overlayedImage: OverlayedImage?
  var pickerItem: PhotosPickerItem?
  var photosAppSelectedImage: Data?
  var inDeleteMode = false

  init(projectId: Int64) {
    self.projectId = projectId
  }

  init(projectId: Int64, images: [ProjectImage]) {
    self.projectId = projectId
    self.images = images
  }

  static func getImages(with id: Int64, from db: AppDatabase) throws -> ProjectImages {
    let records = try db.getProjectImageRecords(projectId: id)

    if records.isEmpty {
      return ProjectImages(
        projectId: id
      )
    }

    let projectImages = records.map { record in
      return ProjectImage(record: record, path: record.filePath)
    }

    return ProjectImages(projectId: id, images: projectImages)
  }

  func importImages(_ newImages: [ProjectImageInput], db: AppDatabase) throws {
    let savedImages = try saveImages(images: newImages, db: db)
    images.append(contentsOf: savedImages)
  }

  private func saveImages(images: [ProjectImageInput], db: AppDatabase) throws -> [ProjectImage] {
    var savedImages: [ProjectImage] = []
    try db.getWriter().write { db in
      for image in images {
        do {
          if image.record == nil {
            let (imagePath, thumbnailPath) = try AppFiles().saveProjectImage(
              projectId: projectId,
              image: image
            )!
            let now = Date.now
            var input = ProjectImageRecordInput(
              id: nil,
              projectId: projectId,
              filePath: imagePath,
              thumbnail: thumbnailPath,
              isDeleted: false,
              createDate: now,
              updateDate: now
            )
            try input.save(db)
            let record = ProjectImageRecord(from: consume input)
            let projectImage = ProjectImage(
              record: consume record,
              path: imagePath,
              image: image.image
            )
            savedImages.append(projectImage)
          }
        } catch {
          // TODO: turn this into an error for the toast
          print("error saving image")
        }
      }
    }

    return savedImages
  }

  func deleteImages(db: AppDatabase) throws {
    try db.getWriter().write { db in
      for image in deletedImages {
        do {
          try AppFiles().deleteImage(projectId: projectId, image: image)
          try image.record.delete(db)
        } catch {
          throw ProjectError.deleteImages
        }
      }
    }

    deletedImages.removeAll()
  }

  var isInDeleteMode: Bool {
    inDeleteMode
  }

  var selectedImagesIsEmpty: Bool {
    selectedImages.isEmpty
  }

  func cancelDeleteMode() {
    selectedImages = Set()
    inDeleteMode = false
  }

  func handleDeleteImage(db: AppDatabase) throws {
    if selectedImagesIsEmpty {
      return
    }

    for imagePath in selectedImages {
      if let index = images.firstIndex(where: { $0.path == imagePath }) {
        let image = images.remove(at: index)
        deletedImages.append(image)
      }
    }
    try deleteImages(db: db)

    inDeleteMode = false
    selectedImages = Set()
  }

  func setDeleteMode(_ mode: Bool) {
    inDeleteMode = mode
  }

  func exitOverlayedImageView() {
    overlayedImage = nil
  }

  func getImage(imageIdentifier: String) -> UIImage {
    AppFiles().getImage(for: imageIdentifier, fromProject: projectId) ?? UIImage()
  }

  func loadProjectImages(db: AppDatabase) async throws {
    let records = self.images.map { image in
      return image.record
    }

    var sharedImages: [ProjectImage] = []
    do {
      sharedImages = try loadSharedImages(db: db)
    } catch {
      print("failed to load shared image")
      // TODO: decide what I want to do here
    }

    var images = db.getProjectThumbnails(projectId: projectId, records: records)
    images.append(contentsOf: sharedImages)

    await MainActor.run {
      self.images = images
    }

  }

  private func loadSharedImages(db: AppDatabase) throws -> [ProjectImage] {
    let sharedImagesFileName = "sharedImages"
    let sharedPersistence = try SharedPersistence()
    guard let fileData = try sharedPersistence.getFile(fileName: sharedImagesFileName) else {
      // TODO: return or throw
      return []
    }
    let decoder = JSONDecoder()
    guard let sharedImages = try? decoder.decode([SharedImage].self, from: fileData) else {
      throw ShareError.emptyFile("Couldn't get shared images list file")
    }

    if sharedImages.isEmpty {
      return []
    }

    var savedImages: [ProjectImage] = []
    for sharedImage in sharedImages {
      if sharedImage.projectId == projectId {
        let data = try sharedPersistence.getImage(withIdentifier: sharedImage.fileIdentifier)
        // extension shouldn't have saved anything that wasn't an image so should be safe
        // to unwrap this here
        let image = UIImage(data: data)!
        let savedImage = try saveImages(images: [ProjectImageInput(image: image)], db: db)
        savedImages.append(contentsOf: savedImage)
        try sharedPersistence.deleteImage(withIdentifier: sharedImage.fileIdentifier)
      }
    }

    let updatedSharedImages = sharedImages.filter { $0.projectId != projectId }
    let encoder = JSONEncoder()
    let data = try encoder.encode(updatedSharedImages)
    try sharedPersistence.writeFile(data: data, fileName: sharedImagesFileName)

    return savedImages
  }
}

// TODO: make this a class since storing data like an image is too expensive to be copying
struct ProjectImage {
  var record: ProjectImageRecord
  var path: String
  var image: UIImage?

  init(record: ProjectImageRecord, path: String, image: UIImage) {
    self.record = record
    self.image = image
    self.path = path
  }

  init(record: ProjectImageRecord, path: String) {
    self.record = record
    self.image = nil
    self.path = path
  }
}

extension ProjectImage: Hashable {
  static func == (lhs: ProjectImage, rhs: ProjectImage) -> Bool {
    // TODO: figure out a better way to compare image if image can be nil
    return lhs.path == rhs.path && lhs.image == rhs.image
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(path)
  }
}

struct ProjectImageInput {
  var record: ProjectImageRecord?
  var image: UIImage

  init(image: UIImage) {
    self.image = image
  }

  init(record: ProjectImageRecord, image: UIImage) {
    self.record = record
    self.image = image
  }
}
