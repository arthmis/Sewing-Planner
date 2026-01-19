import SwiftUI

struct EmptyProjectImagesCallToActionView: View {
  @Environment(ProjectViewModel.self) var project
  @Environment(\.db) var db

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Image(systemName: "photo.on.rectangle.angled")
        .font(.system(size: 32, weight: .light))
      Text("Photos")
        .font(.system(size: 20, weight: .semibold))
        .padding(.top, 20)

      Text(
        "Import photos for references and inspiration. You can share photos from the photos app or web directly to your projects."
      )
      .frame(maxWidth: .infinity, alignment: .leading)
      .font(.system(size: 16))
      .padding(.top, 8)
      Button("Add photos") {
        // TODO use an event for this instead
        project.showPhotoPickerView()
      }
      .buttonStyle(PrimaryButtonStyle(fontSize: 16))
      .padding(.top, 28)
      Spacer()
    }
    .padding(.top, 20)
  }
}
