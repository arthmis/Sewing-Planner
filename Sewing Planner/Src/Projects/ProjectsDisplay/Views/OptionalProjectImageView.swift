import SwiftUI

struct MaybeProjectImageView: View {
  let projectImage: ProjectDisplayImage?

  var image: UIImage {
    let displayedImage =
      if let imageData = projectImage, let image = imageData.image {
        image
      } else {
        UIImage(named: "sewing-machine-no-project-image")
      }
    return displayedImage!
  }

  var body: some View {
    Image(uiImage: image)
      .resizable()
      .interpolation(.high)
      .aspectRatio(contentMode: .fit)
      .frame(
        minWidth: 100,
        maxWidth: .infinity,
        minHeight: 150,
        maxHeight: 200,
        alignment: .center
      )
      .clipShape(
        RoundedRectangle(cornerRadius: 4)
      )
      .padding(4)
  }
}
