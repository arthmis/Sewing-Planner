import PhotosUI
import SwiftUI

struct FabricInputView: View {
  @Environment(\.dismiss) var dismiss
  @Environment(StateStore.self) var stateStore
  @Environment(\.db) private var db
  @State var name = ""
  @State var length = ""
  @State var imageSelection: PhotosPickerItem? = nil

  var addButtonDisabled: Bool {
    name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      || Float64(length) == nil
  }

  var body: some View {
    NavigationStack {
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
          TextField(text: $length, prompt: Text("Length")) {
            Text("Length")
          }
          .keyboardType(.decimalPad)
        }
      }
      .frame(maxWidth: .infinity)
      .navigationTitle("New Fabric")
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarItems(leading: cancelAddFabricButton)
      .navigationBarItems(trailing: addFabricButton)
    }
  }

  var addFabricButton: some View {
    Button("Add") {
      do {
        let fabricInput = try FabricInput(name: name, length: length)
        stateStore.send(event: .fabrics(.storeFabric(fabricInput)), db: db)
        dismiss()
      } catch {
        print("error")
        // display error
      }
    }
    .disabled(addButtonDisabled)
  }
  var cancelAddFabricButton: some View {
    Button("Cancel") {
      dismiss()
    }
  }
}

struct FabricInput {
  let name: String
  let length: Float64

  init(name: String, length: String) throws(FabricInputError) {
    let sanitizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    if sanitizedName.isEmpty {
      throw .emptyName
    }
    self.name = sanitizedName

    guard let parsedLength = Float64(length) else {
      throw .invalidLength
    }
    self.length = parsedLength
  }
}

enum FabricInputError: Error {
  case emptyName
  case invalidLength
}

#Preview {
  FabricInputView()
}
