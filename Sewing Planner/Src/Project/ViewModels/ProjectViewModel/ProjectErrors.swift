enum ProjectError: Error, Equatable {
  case addSection
  case addSectionItem
  case updateSectionItemText
  case updateSectionItemCompletion
  case importImage
  case deleteSection(SectionRecord)
  case deleteSectionItems
  case reOrderSectionItems
  case renameProject
  case renameSectionName(sectionId: Int64, originalName: String)
  case deleteImages
  case loadImages
  case genericError
}
