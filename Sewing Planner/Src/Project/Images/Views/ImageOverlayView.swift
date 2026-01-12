import SwiftUI

struct ImageOverlayView: View {
  @Environment(\.db) private var db
  @Environment(ProjectViewModel.self) private var project
  @Binding var model: ProjectImages
  let item: OverlayedImage
  let transitionNameSpace: Namespace.ID

  var body: some View {
    VStack {
      HStack(alignment: .firstTextBaseline) {
        Button {
          model.exitOverlayedImageView()
        } label: {
          Image(systemName: "xmark.circle")
            .font(.system(size: 22, weight: Font.Weight.thin))
            .foregroundStyle(Color.red)
        }
        .padding(.bottom, 8)
      }
      .padding([.top, .leading], 16)
      .frame(maxWidth: .infinity, alignment: .leading)

      // TODO: figure out what to do if image doesn't exist, some default image
      Image(uiImage: model.getImage(imageIdentifier: item.id))
        .resizable()
        .interpolation(.low)
        .scaledToFit()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
    .navigationTransition(.zoom(sourceID: item.id, in: transitionNameSpace))
  }
}

struct OverlayedImage: Identifiable, Hashable {
  var id: String {
    return body
  }

  var body: String
}
