import GRDB
import PhotosUI
import SwiftUI

enum ProjectEvent {
  case UpdatedProjectTitle(String)
  case StoreNewSection(projectId: Int64)
  case AddNewSection(section: SectionRecord)
  case StoreUpdatedSectionName(section: SectionRecord, oldName: String)
  case markSectionForDeletion(SectionRecord)
  case RemoveSection(Int64)
  case StoreNewSectionItem(item: SectionItem, sectionId: Int64)
  case StoreSectionItem(text: String, note: String?, sectionId: Int64)
  case StoreUpdatedSectionItemText(item: SectionItem, sectionId: Int64)
  case StoreUpdatedSectionItemTextWithNewNote(
    item: SectionItemRecord,
    newNote: String,
    sectionId: Int64
  )
  case UpdateSectionItemText(item: SectionItem, sectionId: Int64)
  case toggleSectionItemCompletionStatus(SectionItemRecord, sectionId: Int64)
  case UpdateSectionItem(item: SectionItemRecord, sectionId: Int64)
  case toggleSelectedSectionItem(withId: Int64, fromSectionWithId: Int64)
  case deleteSelectedSectionItemsFromStorage(selected: Set<Int64>, sectionId: Int64)
  case removeDeletedSectionItems(deletedIds: Set<Int64>, sectionId: Int64)
  case HandleImagePicker(photoPicker: PhotosPickerItem?)
  case AddImage(projectImage: ProjectImage)
  case ShowDeleteImagesView(initialSelectedImageId: Int64)
  case DeleteImagesFromStorage
  case DeleteImages
  case UpdateImagesPreview(ProjectImagePreviews)
  case CancelImageDeletion
  case ToggleImageSelection(imageId: Int64)
  case ProjectError(ProjectError)
}

enum ProjectsEvent {
  case projectEvent(projectId: Int64, ProjectEvent)
  case navigation
  case createProject
  case addProjectToState(ProjectMetadata)

}

extension StateStore {
  public func handleProjectsEvent(_ event: ProjectsEvent, state: ProjectsState) -> Effect? {
    switch event {
      case .projectEvent(let projectId, let projectEvent):
        guard let project = state.selectedProject else {
          return nil
        }

        if projectId != project.projectData.data.id {
          return nil
        }

        return handleProjectEvent(projectEvent, project: project)
      case .navigation:
        print("navigating")
        return nil
      case .createProject:
        return .createProject

      case .addProjectToState(let newProject):
        state.navigation.append(.project(newProject.id))
        return nil

    }
  }

  public func handleProjectEvent(_ event: ProjectEvent, project: ProjectViewModel) -> Effect? {
    switch event {
      case .UpdatedProjectTitle(let newTitle):
        project.projectData.data.name = newTitle
        return Effect.updateProjectTitle(projectData: project.projectData.data)

      case .StoreNewSection(let projectId):
        let now = Date()
        let sectionsCount = project.projectData.sections.count
        let sectionInput = SectionInputRecord(
          projectId: projectId,
          name: "Section \(sectionsCount + 1)",
          createDate: now,
          updateDate: now
        )
        return .StoreNewSection(section: sectionInput)

      case .AddNewSection(let sectionRecord):
        let section = ProjectSection(name: sectionRecord)
        project.projectData.sections.append(section)

        return nil

      case .StoreUpdatedSectionName(let section, let oldName):
        if let index = project.projectData.sections.firstIndex(where: {
          $0.section.id == section.id
        }) {
          project.projectData.sections[index].section.name = section.name
        }
        return .updateSectionName(section: section, oldName: oldName)

      case .markSectionForDeletion(let section):
        if let index = project.projectData.sections.firstIndex(where: {
          $0.section.id == section.id
        }) {
          project.projectData.sections[index].isBeingDeleted = true
        }
        return .deleteSection(section: section)

      case .RemoveSection(let sectionId):
        project.projectData.sections.removeAll(where: {
          $0.section.id == sectionId && $0.isBeingDeleted
        })
        project.projectData.cancelDeleteSection()
        return nil

      case .ProjectError(let error):
        switch error {
          case .addSection:
            break
          case .addSectionItem:
            break
          case .deleteImages:
            project.projectImages.cancelDeleteMode()
            project.handleError(error: error)
            break
          case .deleteSection(let section):
            if let index = project.projectData.sections.firstIndex(where: {
              $0.section.id == section.id
            }) {
              project.projectData.sections[index].isBeingDeleted = false
            }
            project.projectData.cancelDeleteSection()
            project.handleError(error: error)

          case .deleteSectionItems:
            break
          case .genericError:
            break
          case .importImage:
            break
          case .loadImages:
            break
          case .reOrderSectionItems:
            break
          case .renameProject:
            break
          case .renameSectionName(let sectionId, let originalName):
            if let index = project.projectData.sections.firstIndex(where: {
              $0.section.id == sectionId
            }) {
              project.projectData.sections[index].section.name = originalName
            }
            project.handleError(error: error)
          case .updateSectionItemCompletion:
            break
          case .updateSectionItemText:
            break
        }
        return nil

      case .StoreSectionItem(let text, let note, let sectionId):
        guard
          let index = project.projectData.sections.firstIndex(where: { section in
            section.section.id == sectionId
          })
        else {
          // TODO log an error here because this shouldn't be possible
          return nil
        }
        let order = project.projectData.sections[index].items.count
        return .SaveSectionItem(
          text: text.trimmingCharacters(in: .whitespacesAndNewlines),
          note: note,
          order: Int64(order),
          sectionId: sectionId,
          projectId: project.projectData.data.id
        )

      case .StoreNewSectionItem(let item, let sectionId):
        guard
          let index = project.projectData.sections.firstIndex(where: { section in
            section.section.id == sectionId
          })
        else {
          // TODO log an error here because this shouldn't be possible
          return nil
        }
        project.projectData.sections[index].items.append(item)
        return nil

      case .StoreUpdatedSectionItemText(item: let sectionItem, let sectionId):
        return .SaveSectionItemTextUpdate(
          item: sectionItem,
          sectionId: sectionId,
          projectId: project.projectData.data.id
        )

      case .StoreUpdatedSectionItemTextWithNewNote(let item, let newNote, let sectionId):
        let noteRecordInput = SectionItemNoteInputRecord(text: newNote, sectionItemId: item.id)
        return .SaveSectionItemUpdateWithNewNote(
          item: item,
          note: noteRecordInput,
          sectionId: sectionId,
          projectId: project.projectData.data.id
        )

      case .UpdateSectionItemText(let updatedItem, let sectionId):
        guard
          let index = project.projectData.sections.firstIndex(where: { section in
            section.section.id == sectionId
          })
        else {
          // TODO log an error here because this shouldn't be possible
          // or even panic
          return nil
        }

        guard
          let itemIndex = project.projectData.sections[index].items.firstIndex(where: {
            $0.record.id == updatedItem.record.id
          })
        else {
          // TODO log error or panic shouldn't be possible at this point
          return nil
        }

        project.projectData.sections[index].items[itemIndex] = updatedItem
        return nil

      case .toggleSectionItemCompletionStatus(var updatedItem, let sectionId):
        updatedItem.isComplete.toggle()
        return .SaveSectionItemUpdate(
          updatedItem,
          sectionId: sectionId,
          projectId: project.projectData.data.id
        )
      case .UpdateSectionItem(let updatedItem, let sectionId):
        guard
          let index = project.projectData.sections.firstIndex(where: { section in
            section.section.id == sectionId
          })
        else {
          // TODO log an error here because this shouldn't be possible
          // or even panic
          return nil
        }

        guard
          let itemIndex = project.projectData.sections[index].items.firstIndex(where: {
            $0.record.id == updatedItem.id
          })
        else {
          // TODO log error or panic shouldn't be possible at this point
          return nil
        }

        project.projectData.sections[index].items[itemIndex].record = updatedItem
        return nil

      case .toggleSelectedSectionItem(let itemId, let sectionId):
        guard
          let sectionIndex = project.projectData.sections.firstIndex(where: { section in
            section.section.id == sectionId
          })
        else {
          // TODO log an error here because this shouldn't be possible
          // or even panic
          return nil
        }

        if project.projectData.sections[sectionIndex].selectedItems.contains(itemId) {
          project.projectData.sections[sectionIndex].selectedItems.remove(itemId)
        } else {
          project.projectData.sections[sectionIndex].selectedItems.insert(itemId)
        }

        return nil

      case .deleteSelectedSectionItemsFromStorage(let selectedIds, let sectionId):
        guard
          let sectionIndex = project.projectData.sections.firstIndex(where: { section in
            section.section.id == sectionId
          })
        else {
          // TODO log an error here because this shouldn't be possible
          // or even panic
          return nil
        }
        var selected: [SectionItem] = []
        for item in project.projectData.sections[sectionIndex].items {
          if selectedIds.contains(item.record.id) {
            selected.append(item)
          }
        }
        return .deleteSectionItems(
          selected: selected,
          sectionId: sectionId,
          projectId: project.projectData.data.id
        )

      case .removeDeletedSectionItems(let deletedIds, let sectionId):
        guard
          let sectionIndex = project.projectData.sections.firstIndex(where: { section in
            section.section.id == sectionId
          })
        else {
          // TODO log an error here because this shouldn't be possible
          // or even panic
          return nil
        }
        let updatedItems = project.projectData.sections[sectionIndex].items.filter({
          !deletedIds.contains($0.record.id)
        })
        withAnimation(.easeOut(duration: 0.12)) {
          project.projectData.sections[sectionIndex].items = updatedItems
          project.projectData.sections[sectionIndex].isEditingSection = false
          project.projectData.sections[sectionIndex].selectedItems.removeAll()
        }
        return nil

      case .HandleImagePicker(let photoPicker):
        return .HandleImagePicker(photoPicker: photoPicker, projectId: project.projectData.data.id)

      case .AddImage(let projectImage):
        project.projectImages.images.append(projectImage)
        if project.projectImages.images.count >= 1 && project.projectImagePreviews == nil {
          return .GenerateImagesPreview(
            projectImage.record,
            projectId: project.projectData.data.id
          )
        }
        return nil

      case .ShowDeleteImagesView(let initialSelectedImagePath):
        project.projectImages.setDeleteMode(true)
        project.projectImages.selectedImages.insert(initialSelectedImagePath)

        return nil

      case .DeleteImagesFromStorage:
        if project.projectImages.selectedImagesIsEmpty {
          return nil
        }

        for imageId in project.projectImages.selectedImages {
          if let index = project.projectImages.images.firstIndex(where: { $0.record.id == imageId })
          {
            let image = project.projectImages.images.remove(at: index)
            project.projectImages.deletedImages.append(image)
          }
        }
        return .DeleteImages(
          project.projectImages.deletedImages,
          projectId: project.projectData.data.id
        )

      case .DeleteImages:
        project.projectImages.cancelDeleteMode()
        if project.projectImages.deletedImages.firstIndex(where: {
          $0.record.id == project.projectImagePreviews?.mainImage.record.id
        }) != nil {
          project.projectImages.deletedImages.removeAll()
          project.projectImagePreviews = nil
          // TODO return an effect to regenerate preview
          if let firstImageRecord = project.projectImages.images.first {
            return .GenerateImagesPreview(
              firstImageRecord.record,
              projectId: project.projectData.data.id
            )
          }
        }
        project.projectImages.deletedImages.removeAll()
        return nil

      case .CancelImageDeletion:
        project.projectImages.cancelDeleteMode()
        return nil

      case .ToggleImageSelection(let imageId):
        if !project.projectImages.selectedImages.contains(imageId) {
          project.projectImages.selectedImages.insert(imageId)
        } else {
          project.projectImages.selectedImages.remove(imageId)
        }

        return nil

      case .UpdateImagesPreview(let preview):
        project.projectImagePreviews = preview
        return nil
    }
  }

}
