import PhotosUI
import SwiftUI

struct FabricInputView: View {
  @State var name = ""
  @State var length: Float64 = 3.0
  @State var imageSelection: PhotosPickerItem? = nil
  var body: some View {
    VStack {
      Button {
        print("show picker view")
      } label: {
        Label("Add Image", systemImage: "folder.badge.plus")
      }
      Form {
        TextField(text: $name, prompt: Text("Name")) {
          Text("Fabric Name")
        }
        TextField(text: $name, prompt: Text("Length")) {
          Text("Length")
        }
        .keyboardType(.decimalPad)
      }
    }
    .frame(maxWidth: .infinity)
  }
}

#Preview {
  FabricInputView()
}
