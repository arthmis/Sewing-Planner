import GRDB
import PhotosUI
import SwiftUI

enum Effect: Equatable {
  case AddNewSection(section: SectionInputRecord)
  case deleteSection(section: SectionRecord)
  case updateProjectTitle(projectData: ProjectMetadata)
  case updateSectionName(section: SectionRecord, oldName: String)
  case SaveSectionItem(text: String, note: String?, order: Int64, sectionId: Int64)
  case SaveSectionItemTextUpdate(item: SectionItem, sectionId: Int64)
  case SaveSectionItemUpdateWithNewNote(
    item: SectionItemRecord,
    note: SectionItemNoteInputRecord,
    sectionId: Int64
  )
  case SaveSectionItemUpdate(SectionItemRecord, sectionId: Int64)
  case deleteSectionItems(selected: [SectionItem], sectionId: Int64)
  case HandleImagePicker(photoPicker: PhotosPickerItem?, projectId: Int64)
  case DeleteImages([ProjectImage], projectId: Int64)
  case doNothing
}

extension ProjectViewModel {

  nonisolated public func handleEffect(effect: Effect?, db: AppDatabase) {
    guard let effect = effect else {
      return
    }

    switch effect {
      case .AddNewSection(let sectionInput):
        Task {
          do {
            let record = try await db.getWriter().write { [sectionInput] db in
              return try sectionInput.saved(db)
            }

            let sectionRecord = SectionRecord(from: record)
            await MainActor.run {
              _ = self.handleEvent(.AddSectionToState(section: sectionRecord))
            }
          } catch {
            await MainActor.run {
              _ = self.handleEvent(.ProjectError(ProjectError.addSection))
            }
          }
        }

      case .deleteSection(let section):
        Task {
          do {
            try await db.deleteProjectSection(section: section)
            await MainActor.run {
              _ = self.handleEvent(.RemoveSection(section.id))
            }
          } catch {
            await MainActor.run {
              _ = self.handleEvent(.ProjectError(.deleteSection(section)))
            }
          }
        }
        return

      case .updateProjectTitle(let projectData):
        Task {
          do {
            try await db.updateProjectTitle(projectData: projectData)
            try self.updateProjectNameInSharedExtensionProjectList(project: projectData)
          } catch {
            await MainActor.run {
              self.handleError(error: .renameProject)
            }
          }
        }
        return

      case .updateSectionName(let section, let oldName):
        Task {
          do {
            try await db.updateSectionName(sectionId: section.id, newName: section.name)
          } catch {
            await MainActor.run {
              _ = self.handleEvent(
                .ProjectError(.renameSectionName(sectionId: section.id, originalName: oldName))
              )
            }
          }
        }
        return

      case .doNothing:
        return
      case .SaveSectionItem(let text, let note, let order, let sectionId):
        Task {
          do {
            let sectionItem: SectionItem = try await db.getWriter().write { db in
              var recordInput = SectionItemInputRecord(
                text: text,
                order: order,
                sectionId: sectionId
              )
              try recordInput.save(db)
              let record = SectionItemRecord(from: recordInput)

              if let noteText = note {
                var noteInputRecord = SectionItemNoteInputRecord(
                  text: noteText.trimmingCharacters(in: .whitespacesAndNewlines),
                  sectionItemId: record.id
                )
                try noteInputRecord.save(db)
                let noteRecord = SectionItemNoteRecord(from: noteInputRecord)
                let sectionItem = SectionItem(record: record, note: noteRecord)
                return sectionItem
              } else {
                let sectionItem = SectionItem(record: record, note: nil)
                return sectionItem
              }
            }

            await MainActor.run {
              _ = self.handleEvent(
                .AddSectionItem(item: sectionItem, sectionId: sectionId)
              )
            }
          } catch {
            await MainActor.run {
              _ = self.handleEvent(.ProjectError(.addSectionItem))
            }
          }
        }
        return

      case .SaveSectionItemTextUpdate(let item, let sectionId):
        Task {
          do {
            try await db.getWriter().write { db in
              try item.record.update(db)
              try item.note?.update(db)
            }

            await MainActor.run {
              _ = self.handleEvent(.UpdateSectionItemText(item: item, sectionId: sectionId))
            }
          } catch {
            await MainActor.run {
              _ = self.handleEvent(.ProjectError(.updateSectionItemText))
            }
          }
        }
      case .SaveSectionItemUpdateWithNewNote(let item, let newNote, let sectionId):
        Task {
          do {
            let savedNote = try await db.getWriter().write { [newNote] db in
              try item.update(db)
              return try newNote.saved(db)
            }

            let note = SectionItemNoteRecord(from: savedNote)
            let sectionItem = SectionItem(record: item, note: note)
            await MainActor.run {
              _ = self.handleEvent(.UpdateSectionItemText(item: sectionItem, sectionId: sectionId))
            }
          } catch {
            await MainActor.run {
              _ = self.handleEvent(.ProjectError(.updateSectionItemText))
            }
          }
        }

      case .SaveSectionItemUpdate(let updatedItem, let sectionId):
        Task {
          do {
            try await db.getWriter().write { db in
              try updatedItem.update(db)
            }

            await MainActor.run {
              _ = self.handleEvent(.UpdateSectionItem(item: updatedItem, sectionId: sectionId))
            }
          } catch {
            await MainActor.run {
              // TODO: give this its own error type, also used in case above this
              _ = self.handleEvent(.ProjectError(.updateSectionItemText))
            }
          }
        }

      case .deleteSectionItems(let selected, let sectionId):
        Task {
          do {
            let deletedIds = try await db.getWriter().write { db in
              var deletedIds: Set<Int64> = Set()
              for item in selected {
                try item.record.delete(db)
                deletedIds.insert(item.record.id)
              }
              return deletedIds
            }

            await MainActor.run {
              _ = self.handleEvent(
                .removeDeletedSectionItems(deletedIds: deletedIds, sectionId: sectionId)
              )
            }
          } catch {
            await MainActor.run {
              _ = self.handleEvent(.ProjectError(.deleteSectionItems))
            }
          }
        }
      case .HandleImagePicker(let photoPicker, let projectId):
        Task {
          guard let photoPicker = photoPicker else {
            return
          }

          do {
            let result = try await photoPicker.loadTransferable(type: Data.self)
            switch result {
              case .some(let files):
                // show a better error if this fails, shouldn't happen though
                guard let img = UIImage(data: files) else {
                  await MainActor.run {
                    _ = self.handleEvent(.ProjectError(.importImage))
                  }
                  return
                }
                // TODO: potential performance problem here, look into scaling the images in a background task
                let resizedImage = img.scaleToAppImageMaxDimension()
                let projectImage = ProjectImageInput(image: resizedImage)

                let images = [projectImage]
                for image in images {
                  let projectImage: ProjectImage? = try await db.getWriter().write { db in
                    do {
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

                      return projectImage
                    } catch {
                      // TODO: put this error in an error array and log it and show to user if it makes sense
                      return nil
                    }
                  }
                  if let projectImage = projectImage {
                    await MainActor.run {
                      _ = self.handleEvent(.AddImage(projectImage: projectImage))
                    }
                  }
                }
              case .none:
                await MainActor.run {
                  _ = self.handleEvent(.ProjectError(.importImage))
                }
            }
          }
        }
      case .DeleteImages(let deletedImages, let projectId):
        Task {
          do {
            try await db.getWriter().write { [deletedImages] db in
              for image in deletedImages {
                try AppFiles().deleteImage(projectId: projectId, image: image)
                try image.record.delete(db)
              }
            }
            await MainActor.run {
              _ = self.handleEvent(.CompleteImageDeletion)
            }
          } catch {
            await MainActor.run {
              _ = self.handleEvent(.ProjectError(.deleteImages))
            }
          }
        }
    }
  }
}
