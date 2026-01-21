import SwiftUI

struct LoadProjectView: View {
  // used for dismissing a view(basically the back button)
  @Environment(\.dismiss) private var dismiss
  @Environment(\.db) private var appDatabase
  @Environment(StateStore.self) private var store
  @Binding var projectsNavigation: [ProjectMetadata]
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
    // clicking anywhere will remove focus from whatever may have focus
    // mostly using this to remove focus from textfields when you click outside of them
    // using a frame using all the available space to make it more effective
    //        .onTapGesture {
    //            NSApplication.shared.keyWindow?.makeFirstResponder(nil)
    //        }
    .onAppear {
      if let id = projectsNavigation.last?.id {
        do {
          let maybeProjectData = try ProjectData.getProject(
            with: id,
            from: appDatabase
          )
          if let projectData = maybeProjectData {

            let projectImages = try ProjectImages.getImages(with: id, from: appDatabase)

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
      } else {
        dismiss()
        store.appError = .loadProject
        // navigate back to main view and show an error
        // this basically shouldn't happen because there must be a project in projects navigation at this point, which means
        // there is an id
      }
    }
  }
}
