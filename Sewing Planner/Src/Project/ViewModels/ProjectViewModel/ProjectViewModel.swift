import GRDB
import PhotosUI
import SwiftUI

@Observable @MainActor
final class ProjectViewModel {
  var projectData: ProjectData
  var projectsNavigation: [ProjectMetadata]
  var projectImages: ProjectImages
  var currentView = CurrentView.details
  var name = ""
  var showAddTextboxPopup = false
  var doesProjectHaveName = false
  var pickerItem: PhotosPickerItem?
  private var photosAppSelectedImage: Data?
  var showPhotoPicker = false
  var projectError: ProjectError?

  init(
    data: ProjectData,
    projectsNavigation: [ProjectMetadata],
    projectImages: ProjectImages
  ) {
    projectData = data
    self.projectsNavigation = projectsNavigation
    self.projectImages = projectImages
  }

  func addSection(db: AppDatabase) {
    do {
      try projectData.addSection(db: db)
    } catch {
      projectError = .addSection
    }
  }

  func showDeleteSectionConfirmationDialog(section: SectionRecord) {
    projectData.selectedSectionForDeletion = section
    projectData.showDeleteSectionDialog = true
  }

  func handleError(error: ProjectError) {
    projectError = error
  }

  func showPhotoPickerView() {
    showPhotoPicker = true
  }

  @MainActor func handleOnChangePickerItem(db: AppDatabase) async {
    do {
      try await handleOnChangePickerItemInner(db: db)
    } catch {
      projectError = .importImage
    }
  }

  @MainActor private func handleOnChangePickerItemInner(db: AppDatabase) async throws {
    let result = try await pickerItem?.loadTransferable(type: Data.self)

    switch result {
      case .some(let files):
        // fix this unwrap by throwing an error, display to user
        guard let img = UIImage(data: files) else {
          throw ProjectError.importImage
        }
        // TODO: Performance problem here, scale the images in a background task
        let resizedImage = img.scaleToAppImageMaxDimension()
        let projectImage = ProjectImageInput(image: resizedImage)
        try projectImages.importImages([projectImage], db: db)
      case .none:
        // TODO: think about how to deal with path that couldn't become an image
        // I'm thinking display an error alert that lists every image that couldn't be uploaded
        projectError = .importImage
    // errorToast = ErrorToast(show: true, message: "Error importing images. Please try again later")
    // log error
    }
  }

  private func removeSection(section: SectionRecord) {
    let updatedSections = projectData.sections.filter {
      projectSection in
      section.id != projectSection.section.id
    }
    projectData.sections = updatedSections
    projectData.cancelDeleteSection()
  }

  private func cancelSectionDeletion(withError error: ProjectError) {
    projectError = error
    projectData.cancelDeleteSection()
  }

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
