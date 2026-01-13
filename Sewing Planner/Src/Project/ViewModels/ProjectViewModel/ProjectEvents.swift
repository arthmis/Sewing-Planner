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

extension ProjectViewModel {
  public func handleEvent(_ event: ProjectEvent) -> Effect? {
    switch event {

      case .UpdatedProjectTitle(let newTitle):
        projectData.data.name = newTitle
        return Effect.updateProjectTitle(projectData: projectData.data)

      case .AddSection(let projectId):
        let now = Date()
        let sectionsCount = self.projectData.sections.count
        let sectionInput = SectionInputRecord(
          projectId: projectId,
          name: "Section \(sectionsCount + 1)",
          createDate: now,
          updateDate: now
        )
        return .AddNewSection(section: sectionInput)

      case .AddSectionToState(let sectionRecord):
        let section = Section(name: sectionRecord)
        self.projectData.sections.append(section)

        return nil

      case .UpdateSectionName(let section, let oldName):
        if let index = self.projectData.sections.firstIndex(where: { $0.section.id == section.id })
        {
          self.projectData.sections[index].section.name = section.name
        }
        return .updateSectionName(section: section, oldName: oldName)

      case .markSectionForDeletion(let section):
        if let index = self.projectData.sections.firstIndex(where: { $0.section.id == section.id })
        {
          self.projectData.sections[index].isBeingDeleted = true
        }
        return .deleteSection(section: section)

      case .RemoveSection(let sectionId):
        self.projectData.sections.removeAll(where: {
          $0.section.id == sectionId && $0.isBeingDeleted
        })
        self.projectData.cancelDeleteSection()

      case .ProjectError(let error):
        switch error {
          case .addSection:
            break
          case .addSectionItem:
            break
          case .deleteImages:
            self.projectImages.cancelDeleteMode()
            self.handleError(error: error)
            break
          case .deleteSection(let section):
            if let index = self.projectData.sections.firstIndex(where: {
              $0.section.id == section.id
            }) {
              self.projectData.sections[index].isBeingDeleted = false
            }
            self.projectData.cancelDeleteSection()
            self.handleError(error: error)

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
            if let index = self.projectData.sections.firstIndex(where: {
              $0.section.id == sectionId
            }) {
              self.projectData.sections[index].section.name = originalName
            }
            self.handleError(error: error)
          case .updateSectionItemCompletion:
            break
          case .updateSectionItemText:
            break
        }

      case .StoreSectionItem(let text, let note, let sectionId):
        guard
          let index = self.projectData.sections.firstIndex(where: { section in
            section.section.id == sectionId
          })
        else {
          // TODO log an error here because this shouldn't be possible
          return nil
        }
        let order = self.projectData.sections[index].items.count
        return .SaveSectionItem(
          text: text.trimmingCharacters(in: .whitespacesAndNewlines),
          note: note,
          order: Int64(order),
          sectionId: sectionId
        )

      case .AddSectionItem(let item, let sectionId):
        guard
          let index = self.projectData.sections.firstIndex(where: { section in
            section.section.id == sectionId
          })
        else {
          // TODO log an error here because this shouldn't be possible
          return nil
        }
        self.projectData.sections[index].items.append(item)
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
          let index = self.projectData.sections.firstIndex(where: { section in
            section.section.id == sectionId
          })
        else {
          // TODO log an error here because this shouldn't be possible
          // or even panic
          return nil
        }

        guard
          let itemIndex = self.projectData.sections[index].items.firstIndex(where: {
            $0.record.id == updatedItem.record.id
          })
        else {
          // TODO log error or panic shouldn't be possible at this point
          return nil
        }

        self.projectData.sections[index].items[itemIndex] = updatedItem
        return nil

      case .toggleSectionItemCompletionStatus(var updatedItem, let sectionId):
        updatedItem.isComplete.toggle()
        return .SaveSectionItemUpdate(updatedItem, sectionId: sectionId)
      case .UpdateSectionItem(let updatedItem, let sectionId):
        guard
          let index = self.projectData.sections.firstIndex(where: { section in
            section.section.id == sectionId
          })
        else {
          // TODO log an error here because this shouldn't be possible
          // or even panic
          return nil
        }

        guard
          let itemIndex = self.projectData.sections[index].items.firstIndex(where: {
            $0.record.id == updatedItem.id
          })
        else {
          // TODO log error or panic shouldn't be possible at this point
          return nil
        }

        self.projectData.sections[index].items[itemIndex].record = updatedItem
        return nil

      case .toggleSelectedSectionItem(let itemId, let sectionId):
        guard
          let sectionIndex = self.projectData.sections.firstIndex(where: { section in
            section.section.id == sectionId
          })
        else {
          // TODO log an error here because this shouldn't be possible
          // or even panic
          return nil
        }

        if self.projectData.sections[sectionIndex].selectedItems.contains(itemId) {
          self.projectData.sections[sectionIndex].selectedItems.remove(itemId)
        } else {
          self.projectData.sections[sectionIndex].selectedItems.insert(itemId)
        }

        return nil

      case .deleteSelectedTasks(let selectedIds, let sectionId):
        guard
          let sectionIndex = self.projectData.sections.firstIndex(where: { section in
            section.section.id == sectionId
          })
        else {
          // TODO log an error here because this shouldn't be possible
          // or even panic
          return nil
        }
        var selected: [SectionItem] = []
        for item in self.projectData.sections[sectionIndex].items {
          if selectedIds.contains(item.record.id) {
            selected.append(item)
          }
        }
        return .deleteSectionItems(selected: selected, sectionId: sectionId)

      case .removeDeletedSectionItems(let deletedIds, let sectionId):
        guard
          let sectionIndex = self.projectData.sections.firstIndex(where: { section in
            section.section.id == sectionId
          })
        else {
          // TODO log an error here because this shouldn't be possible
          // or even panic
          return nil
        }
        let updatedItems = self.projectData.sections[sectionIndex].items.filter({
          !deletedIds.contains($0.record.id)
        })
        withAnimation(.easeOut(duration: 0.12)) {
          self.projectData.sections[sectionIndex].items = updatedItems
          self.projectData.sections[sectionIndex].isEditingSection = false
          self.projectData.sections[sectionIndex].selectedItems.removeAll()
        }
        return nil

      case .HandleImagePicker(let photoPicker):
        return .HandleImagePicker(photoPicker: photoPicker, projectId: self.projectData.data.id)

      case .AddImage(let projectImage):
        self.projectImages.images.append(projectImage)
        return nil

      case .ShowDeleteImagesView(let initialSelectedImagePath):
        self.projectImages.setDeleteMode(true)
        self.projectImages.selectedImages.insert(initialSelectedImagePath)

        return nil

      case .DeleteImages:
        if self.projectImages.selectedImagesIsEmpty {
          return nil
        }

        for imageId in self.projectImages.selectedImages {
          if let index = self.projectImages.images.firstIndex(where: { $0.record.id == imageId }) {
            let image = self.projectImages.images.remove(at: index)
            self.projectImages.deletedImages.append(image)
          }
        }
        return .DeleteImages(self.projectImages.deletedImages, projectId: self.projectData.data.id)

      case .CompleteImageDeletion:
        self.projectImages.cancelDeleteMode()
        self.projectImages.deletedImages.removeAll()
        return nil

      case .CancelImageDeletion:
        self.projectImages.cancelDeleteMode()
        return nil

      case .ToggleImageSelection(let imageId):
        if !self.projectImages.selectedImages.contains(imageId) {
          self.projectImages.selectedImages.insert(imageId)
        } else {
          self.projectImages.selectedImages.remove(imageId)
        }
    }

    return nil
  }

  func send(event: ProjectEvent, db: AppDatabase) {
    let effect = handleEvent(event)
    handleEffect(effect: effect, db: db)
  }

}
