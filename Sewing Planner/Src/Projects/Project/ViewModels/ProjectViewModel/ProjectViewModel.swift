import GRDB
import PhotosUI
import SwiftUI

@Observable @MainActor
final class ProjectViewModel {
  var projectData: ProjectData
  var projectsNavigation: [ProjectsNavigation]
  var projectImages: ProjectImages
  var projectImagePreviews: ProjectImagePreviews?
  var pickerItem: PhotosPickerItem?
  private var photosAppSelectedImage: Data?
  var showPhotoPicker = false
  var projectError: ProjectError?

  init(
    data: ProjectData,
    projectsNavigation: [ProjectsNavigation],
    projectImages: ProjectImages,
    projectImagePreviews: ProjectImagePreviews? = nil
  ) {
    projectData = data
    self.projectsNavigation = projectsNavigation
    self.projectImages = projectImages
    self.projectImagePreviews = projectImagePreviews
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

}

struct ProjectImagePreviews {
  let mainImage: ProjectImage
}
