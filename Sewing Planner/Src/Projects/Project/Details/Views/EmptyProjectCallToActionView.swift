import SwiftUI

struct EmptyProjectCallToActionView: View {
  @Environment(StateStore.self) var store
  @Environment(\.db) var db

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Image(systemName: "list.bullet.rectangle")
        .font(.system(size: 32, weight: .light))
      Text("Sections")
        .font(.system(size: 20, weight: .semibold))
        .padding(.top, 20)

      Text(
        "Create sections to organize and define the important tasks and details of your project."
      )
      .frame(maxWidth: .infinity, alignment: .leading)
      .font(.system(size: 16))
      .padding(.top, 8)
      Button("Create new section") {
        guard let projectId = store.projectsState.selectedProject?.projectData.data.id else {
          return
        }
        store.send(
          event: .projects(
            .projectEvent(projectId: projectId, .StoreNewSection(projectId: projectId))
          ),
          db: db
        )
      }
      .buttonStyle(PrimaryButtonStyle(fontSize: 16))
      .padding(.top, 28)
    }
  }

}
