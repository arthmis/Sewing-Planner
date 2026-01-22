import GRDB
import PhotosUI
import SwiftUI

enum Effect: Equatable {
  case createProject
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
  case StoreFabric(FabricRecordInput)
  case retrieveAllFabrics
  case doNothing
}
