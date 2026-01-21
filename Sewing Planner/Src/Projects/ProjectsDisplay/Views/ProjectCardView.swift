import SwiftUI

struct ProjectCardView: View {
  @Environment(StateStore.self) private var store
  var projectData: ProjectCardViewModel
  @Binding var projectsNavigation: [ProjectMetadata]

  var body: some View {
    HStack {
      if !projectData.error {
        MaybeProjectImageView(projectImage: projectData.image)
        HStack(alignment: .firstTextBaseline) {
          Text(projectData.project.name)
            .accessibilityIdentifier("ProjectName")
        }
        .padding([.bottom, .horizontal], 8)
        .frame(
          minWidth: 100,
          maxWidth: .infinity,
          maxHeight: .infinity,
          alignment: .leading
        )
      } else {
        Text("Error loading project image")
        // TODO: add a button or make the card clickable to retry loading the image
      }
    }
    .frame(
      minWidth: 100,
      maxWidth: .infinity,
      minHeight: 200,
      maxHeight: 200,
      alignment: .center
    )
    .background(
      RoundedRectangle(cornerRadius: 8)
        .stroke(.gray, lineWidth: 1)
        .fill(.white)
        .shadow(radius: 2, y: 5)
    )
    .padding(8)
    .onTapGesture {
      projectsNavigation.append(projectData.project)
    }
  }
}
