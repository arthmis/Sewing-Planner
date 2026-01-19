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
