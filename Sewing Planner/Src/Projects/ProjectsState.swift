import SwiftUI

@Observable
class ProjectsState {
  var projects: ProjectsViewModel
  var navigation: [ProjectMetadata] = []
  var selectedProject: ProjectViewModel?

  init(selectedProject: ProjectViewModel? = nil) {
    projects = ProjectsViewModel()
    self.selectedProject = selectedProject
  }

  func updateShareExtensionProjectList(project: ProjectMetadata) throws {
    let fileData = try SharedPersistence().getFile(fileName: "projects")
    guard let data = fileData else {
      let projectsList = [SharedProject(id: project.id, name: project.name)]
      let encoder = JSONEncoder()
      let updatedProjectsList = try encoder.encode(projectsList)
      try SharedPersistence().writeFile(data: updatedProjectsList, fileName: "projects")

      return
    }

    let decoder = JSONDecoder()
    guard var projectsList = try? decoder.decode([SharedProject].self, from: data) else {
      throw ShareError.emptyFile("Couldn't get shared projects list file")
    }

    projectsList.append(SharedProject(id: project.id, name: project.name))
    let encoder = JSONEncoder()
    let updatedProjectsList = try encoder.encode(projectsList)
    try SharedPersistence().writeFile(data: updatedProjectsList, fileName: "projects")
  }
}
