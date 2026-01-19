import SwiftUI

@Observable
class ProjectsState {
  var projects: ProjectsViewModel
  var navigation: [ProjectMetadata] = []
  var selectedProject: ProjectViewModel?
  let db: AppDatabase

  init(db: AppDatabase) {
    projects = ProjectsViewModel()
    self.db = db
  }

  func addProject() throws(AppError) {
    do {
      try db.getWriter().write { db in
        var newProjectInput = ProjectMetadataInput()
        try newProjectInput.save(db)

        let newProject = ProjectMetadata(from: newProjectInput)
        navigation.append(newProject)

        try updateShareExtensionProjectList(project: newProject)
      }
    } catch {
      throw AppError.addProject
    }
  }

  private func updateShareExtensionProjectList(project: ProjectMetadata) throws {
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
