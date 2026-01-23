import SwiftUI

struct LoadProjectView: View {
  // used for dismissing a view(basically the back button)
  @Environment(\.dismiss) private var dismiss
  @Environment(\.db) private var appDatabase
  @Environment(StateStore.self) private var store
  @Binding var projectsNavigation: [ProjectsNavigation]
  let projectId: Int64
  let fetchProjects: () -> Void
  // @State var isLoading = true

  var body: some View {
    VStack {
      if let project = store.projectsState.selectedProject {
        ProjectView(
          project: project,
          projectsNavigation: $projectsNavigation,
          fetchProjects: fetchProjects
        )
      } else {
        ProgressView()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .onAppear {
      if store.projectsState.selectedProject != nil {
        return
      }

      do {
        let maybeProjectData = try ProjectData.getProject(
          with: projectId,
          from: appDatabase
        )
        if let projectData = maybeProjectData {
          let projectImages = try ProjectImages.getImages(with: projectId, from: appDatabase)

          store.projectsState.selectedProject = ProjectViewModel(
            data: projectData,
            projectsNavigation: projectsNavigation,
            projectImages: projectImages
          )
        } else {
          dismiss()
          store.appError = .loadProject
          // TODO: show an error
        }
      } catch {
        dismiss()
        store.appError = .loadProject
        // TODO: show an error
      }
    }
  }
}
