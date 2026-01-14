import SwiftUI

struct EmptyProjectCallToActionView: View {
  @Environment(ProjectViewModel.self) var project
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
        project.send(event: .AddSection(projectId: project.projectData.data.id), db: db)
      }
      .buttonStyle(PrimaryButtonStyle(fontSize: 16))
      .padding(.top, 28)
    }
  }

}
