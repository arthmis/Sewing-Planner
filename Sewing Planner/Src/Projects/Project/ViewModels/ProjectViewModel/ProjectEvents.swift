import GRDB
import PhotosUI
import SwiftUI

enum ProjectEvent {
  case UpdatedProjectTitle(String)
  case AddSection(projectId: Int64)
  case AddSectionToState(section: SectionRecord)
  case UpdateSectionName(section: SectionRecord, oldName: String)
  case markSectionForDeletion(SectionRecord)
  case RemoveSection(Int64)
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
  case deleteSelectedTasks(selected: Set<Int64>, sectionId: Int64)
  case removeDeletedSectionItems(deletedIds: Set<Int64>, sectionId: Int64)
  case AddSectionItem(item: SectionItem, sectionId: Int64)
  case HandleImagePicker(photoPicker: PhotosPickerItem?)
  case AddImage(projectImage: ProjectImage)
  case ShowDeleteImagesView(initialSelectedImageId: Int64)
  case DeleteImages
  case CompleteImageDeletion
  case CancelImageDeletion
  case ToggleImageSelection(imageId: Int64)
  case ProjectError(ProjectError)
}

enum ProjectsEvent {
  case projectEvent(ProjectEvent)
  case navigation
}

extension StateStore {
  public func handleProjectsEvent(_ event: ProjectsEvent, state: ProjectsState) -> Effect? {
    switch event {
      case .projectEvent(let projectEvent):
        guard let project = state.selectedProject else {
          return nil
        }

        return handleProjectEvent(projectEvent, project: project)
      case .navigation:
        print("navigating")
        return nil
    }
  }

  public func handleProjectEvent(_ event: ProjectEvent, project: ProjectViewModel) -> Effect? {
    switch event {

      case .UpdatedProjectTitle(let newTitle):
        project.projectData.data.name = newTitle
        return Effect.updateProjectTitle(projectData: project.projectData.data)

      case .AddSection(let projectId):
        let now = Date()
        let sectionsCount = project.projectData.sections.count
        let sectionInput = SectionInputRecord(
          projectId: projectId,
          name: "Section \(sectionsCount + 1)",
          createDate: now,
          updateDate: now
        )
        return .AddNewSection(section: sectionInput)

      case .AddSectionToState(let sectionRecord):
        let section = Section(name: sectionRecord)
        project.projectData.sections.append(section)

        return nil

      case .UpdateSectionName(let section, let oldName):
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
          sectionId: sectionId
        )

      case .AddSectionItem(let item, let sectionId):
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
        return .SaveSectionItemTextUpdate(item: sectionItem, sectionId: sectionId)

      case .StoreUpdatedSectionItemTextWithNewNote(let item, let newNote, let sectionId):
        let noteRecordInput = SectionItemNoteInputRecord(text: newNote, sectionItemId: item.id)
        return .SaveSectionItemUpdateWithNewNote(
          item: item,
          note: noteRecordInput,
          sectionId: sectionId
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
        return .SaveSectionItemUpdate(updatedItem, sectionId: sectionId)
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

      case .deleteSelectedTasks(let selectedIds, let sectionId):
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
        return .deleteSectionItems(selected: selected, sectionId: sectionId)

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
        return nil

      case .ShowDeleteImagesView(let initialSelectedImagePath):
        project.projectImages.setDeleteMode(true)
        project.projectImages.selectedImages.insert(initialSelectedImagePath)

        return nil

      case .DeleteImages:
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

      case .CompleteImageDeletion:
        project.projectImages.cancelDeleteMode()
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
    }
  }

}
