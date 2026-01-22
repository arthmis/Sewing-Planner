import GRDB
import SwiftUI

@Observable @MainActor
class StateStore {
  var projectsState: ProjectsState
  var stashState: StashState
  var appError: AppError?
  var appSection: AppSection = .stash

  init() {
    projectsState = ProjectsState()
    stashState = StashState()
  }

}

extension StateStore {
  public func handleEvent(_ event: AppEvent) -> Effect? {
    switch event {
      case .fabrics(let event):
        return handleFabricsEvent(event, state: self.stashState.fabrics)
      case .projects(let event):
        return handleProjectsEvent(event, state: self.projectsState)
    }
  }

  func send(event: AppEvent, db: AppDatabase) {
    let effect = handleEvent(event)
    handleEffect(effect: effect, db: db)
  }

}

extension StateStore {
  nonisolated public func handleEffect(effect: Effect?, db: AppDatabase) {
    guard let effect = effect else {
      return
    }

    switch effect {
      case .StoreFabric(let fabricInput):
        Task {
          do {
            let fabricRecord = try await db.getWriter().write { [fabricInput] db in
              let savedFabric = try fabricInput.saved(db)
              return FabricRecord(from: savedFabric)
            }

            await MainActor.run {
              _ = self.handleEvent(.fabrics(.addFabricToState(fabricRecord)))
            }
          } catch {
            print(error)
            // todo: handle app error
          }
        }

      case .retrieveAllFabrics:
        Task {
          do {
            let fabrics = try await db.reader.read { db in
              let fabrics = try FabricRecord.all().fetchAll(db)
              return fabrics
            }

            await MainActor.run {
              _ = self.handleEvent(.fabrics(.addFabricsToState(fabrics)))
            }
          }
        }

      case .createProject:
        Task {
          do {
            let newProject = try await db.getWriter().write { db in
              var newProjectInput = ProjectMetadataInput()
              try newProjectInput.save(db)

              return ProjectMetadata(from: newProjectInput)
            }
            try await MainActor.run {
              _ = self.handleEvent(.projects(.addProjectToState(newProject)))
              // TODO update this so it can be updated asynchronously
              // it shouldn't be necessary to run this on the main thread, might need a bigger refactor
              // also handle the dual write problem, possible to save project but not update the shared list of
              // projects in the file
              try self.projectsState.updateShareExtensionProjectList(project: newProject)
            }
          } catch {
            throw AppError.addProject
          }
        }

      case .AddNewSection(let sectionInput):
        Task {
          do {
            let record = try await db.getWriter().write { [sectionInput] db in
              return try sectionInput.saved(db)
            }

            let sectionRecord = SectionRecord(from: record)
            await MainActor.run {
              _ = self.handleEvent(
                .projects(.projectEvent(.AddSectionToState(section: sectionRecord)))
              )
            }
          } catch {
            await MainActor.run {
              _ = self.handleEvent(.projects(.projectEvent(.ProjectError(ProjectError.addSection))))
            }
          }
        }

      case .deleteSection(let section):
        Task {
          do {
            try await db.deleteProjectSection(section: section)
            await MainActor.run {
              _ = self.handleEvent(.projects(.projectEvent(.RemoveSection(section.id))))
            }
          } catch {
            await MainActor.run {
              _ = self.handleEvent(.projects(.projectEvent(.ProjectError(.deleteSection(section)))))
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
              self.projectsState.selectedProject?.handleError(
                error: .renameProject
              )
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
                .projects(
                  .projectEvent(
                    .ProjectError(.renameSectionName(sectionId: section.id, originalName: oldName))
                  )
                )
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
                .projects(.projectEvent(.AddSectionItem(item: sectionItem, sectionId: sectionId)))
              )
            }
          } catch {
            await MainActor.run {
              _ = self.handleEvent(.projects(.projectEvent(.ProjectError(.addSectionItem))))
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
              _ = self.handleEvent(
                .projects(.projectEvent(.UpdateSectionItemText(item: item, sectionId: sectionId)))
              )
            }
          } catch {
            await MainActor.run {
              _ = self.handleEvent(.projects(.projectEvent(.ProjectError(.updateSectionItemText))))
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
              _ = self.handleEvent(
                .projects(
                  .projectEvent(.UpdateSectionItemText(item: sectionItem, sectionId: sectionId))
                )
              )
            }
          } catch {
            await MainActor.run {
              _ = self.handleEvent(.projects(.projectEvent(.ProjectError(.updateSectionItemText))))
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
              _ = self.handleEvent(
                .projects(
                  .projectEvent(.UpdateSectionItem(item: updatedItem, sectionId: sectionId))
                )
              )
            }
          } catch {
            await MainActor.run {
              // TODO: give this its own error type, also used in case above this
              _ = self.handleEvent(.projects(.projectEvent(.ProjectError(.updateSectionItemText))))
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
                .projects(
                  .projectEvent(
                    .removeDeletedSectionItems(deletedIds: deletedIds, sectionId: sectionId)
                  )
                )
              )
            }
          } catch {
            await MainActor.run {
              _ = self.handleEvent(.projects(.projectEvent(.ProjectError(.deleteSectionItems))))
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
                    _ = self.handleEvent(.projects(.projectEvent(.ProjectError(.importImage))))
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
                      _ = self.handleEvent(
                        .projects(.projectEvent(.AddImage(projectImage: projectImage)))
                      )
                    }
                  }
                }
              case .none:
                await MainActor.run {
                  _ = self.handleEvent(.projects(.projectEvent(.ProjectError(.importImage))))
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
              _ = self.handleEvent(.projects(.projectEvent(.CompleteImageDeletion)))
            }
          } catch {
            await MainActor.run {
              _ = self.handleEvent(.projects(.projectEvent(.ProjectError(.deleteImages))))
            }
          }
        }
    }
  }
}

extension StateStore {
  nonisolated func updateProjectNameInSharedExtensionProjectList(project: ProjectMetadata)
    throws
  {
    let fileData = try SharedPersistence().getFile(fileName: "projects")
    guard let data = fileData else {
      // TODO: figure out what I want to do here if no file is found
      // let projectsList = [Project(id: project.id, name: project.name)]
      // let encoder = JSONEncoder()
      // let updatedProjectsList = try encoder.encode(projectsList)
      // try SharedPersistence().writeFile(data: updatedProjectsList, fileName: "projects")

      return
    }

    let decoder = JSONDecoder()
    guard var projectsList = try? decoder.decode([SharedProject].self, from: data) else {
      throw ShareError.emptyFile("Couldn't get shared projects list file")
    }

    guard let index = projectsList.firstIndex(where: { $0.id == project.id })
    else {
      return
    }

    let updatedProject = SharedProject(id: project.id, name: project.name)
    projectsList[index] = updatedProject

    let encoder = JSONEncoder()
    let updatedProjectsList = try encoder.encode(projectsList)
    try SharedPersistence().writeFile(data: updatedProjectsList, fileName: "projects")
  }
}

enum AppEvent {
  case fabrics(FabricsEvent)
  case projects(ProjectsEvent)
}

enum AppError: Error {
  case projectCards
  case loadProject
  case addProject
  case unexpectedError
}

enum AppSection {
  case projects
  case stash
  case shoppingList
}
