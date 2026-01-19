import SwiftUI

struct CreateProjectCTAView: View {
  var body: some View {
    VStack {
      Text("Welcome to Sewing Planner!")
        .frame(maxWidth: .infinity, alignment: .leading)
        .font(.system(size: 40))
        .padding(.top, 28)
        .padding(.horizontal, 16)

      Text(
        "Get started with a project by tapping New Project below."
      )
      .frame(maxWidth: .infinity, alignment: .leading)
      .font(.system(size: 16))
      .padding(.top, 8)
      .padding(.horizontal, 16)
      Image(
        "vecteezy_crossed-sewing-needles-with-thread-silhouette_"
      )
      .resizable()
      .aspectRatio(contentMode: .fit)
      .padding([.bottom, .horizontal], 68)
    }
  }
}
