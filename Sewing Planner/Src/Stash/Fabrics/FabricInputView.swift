import PhotosUI
import SwiftUI

struct FabricInputView: View {
  @Environment(\.dismiss) var dismiss
  @Environment(StateStore.self) var stateStore
  @Environment(\.db) private var db
  @State var name = ""
  @State var length = ""
  @State var width = ""
  @State var description = ""
  @State var color = ""
  @State var fibersTextInput = ""
  @State var selectedFibers: [FiberType] = [.abaca, .bamboo, .cashmere]
  @State var searchResults: [FiberType] = FiberType.knownTypes
  @State var pattern = ""
  @State var stretch = ""
  @State var imageSelection: PhotosPickerItem? = nil
  @State var store = ""
  @State var link = ""
  @State var price = ""
  @FocusState var fiberTextFieldFocus: Bool

  var addButtonDisabled: Bool {
    name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      || Float64(length) == nil
  }

  var body: some View {
    NavigationStack {
      Form {
        Section(header: Text("Photos")) {
          Button {
            print("show picker view")
          } label: {
            Label("Add Image", systemImage: "folder.badge.plus")
          }

        }
        Section(header: Text("Details")) {
          TextField("Name", text: $name, prompt: Text("Name"))
          TextField("Length", text: $length)
            .keyboardType(.decimalPad)
          TextField("Width", text: $width)
            .keyboardType(.decimalPad)
          TextField("Description", text: $description)
        }

        Section(header: Text("Composition")) {
          TextField("Color", text: $color, prompt: Text("Color"))
          NavigationLink(destination: selectFibersView) {
            VStack(alignment: .leading) {
              Text("Fiber Content")
                .foregroundStyle(.placeholder)
                .font(.subheadline)
              WrappingHStack {
                ForEach($selectedFibers, id: \.self) { fiber in
                  Button {
                    selectedFibers = selectedFibers.filter({ $0 != fiber.wrappedValue })
                  } label: {
                    HStack {
                      Text(fiber.wrappedValue.displayName)
                      Image(systemName: "xmark")
                    }
                  }
                  .buttonStyle(.bordered)
                }
              }
            }
          }
          TextField("Pattern", text: $pattern, prompt: Text("Pattern"))
          TextField("Stretch", text: $stretch, prompt: Text("Stretch"))
        }

        Section(header: Text("Purchase Information")) {
          TextField("Store", text: $store)
          TextField("Link", text: $link)
          TextField("Price", text: $price)
          // TextField("Purchase Date", text: $purchaseDate)
        }
      }
      .navigationTitle("New Fabric")
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarItems(leading: cancelAddFabricButton)
      .navigationBarItems(trailing: addFabricButton)
    }
  }

  var selectFibersView: some View {
    VStack(alignment: .leading, spacing: 0) {
      if !fiberTextFieldFocus {
        Group {
          Text("Selected fibers:")
            .font(.subheadline)
            .padding(.bottom, 2)
          WrappingHStack(horizontalSpacing: 4) {
            ForEach($selectedFibers, id: \.self) { fiber in
              Button {
                selectedFibers = selectedFibers.filter({ $0 != fiber.wrappedValue })
              } label: {
                HStack {
                  Text(fiber.wrappedValue.displayName)
                  Image(systemName: "xmark")
                }
              }
              .buttonStyle(.bordered)
            }
          }
          .padding(.bottom, 8)
        }
        .transition(.revealFrom(edge: .top))
      } else {
        WrappingHStack(horizontalSpacing: 4) {
          ForEach($selectedFibers, id: \.self) { fiber in
            Button {
              selectedFibers = selectedFibers.filter({ $0 != fiber.wrappedValue })
            } label: {
              HStack {
                Text(fiber.wrappedValue.displayName)
                  .font(.caption)
                Image(systemName: "xmark")
                  .font(.caption)
              }
            }
            .buttonStyle(.bordered)
          }
        }
        .padding(.bottom, 4)
        .transition(.revealFrom(edge: .bottom))
      }

      HStack {
        TextField("Fibers", text: $fibersTextInput, prompt: Text("Fiber Content"))
          .focused($fiberTextFieldFocus)
          .onSubmit {
            withAnimation {
              if let first = searchResults.first {
                selectedFibers.append(first)
              }
            }
          }
          .debouncedTextField(observedValue: $fibersTextInput) { searchText in
            print(searchText)
            searchResults.removeAll()
            searchResults.append(FiberType.knownTypes.randomElement()!)
            searchResults.append(FiberType.knownTypes.randomElement()!)
            searchResults.append(FiberType.knownTypes.randomElement()!)
            searchResults.append(FiberType.knownTypes.randomElement()!)
          }
          .padding(.leading, 8)
        Button {
          fiberTextFieldFocus = false
          fibersTextInput = ""
        } label: {
          Label("Close", systemImage: "xmark")
            .labelStyle(.iconOnly)
        }
        .padding(.horizontal, 8)
      }
      .padding(.vertical, 4)
      .background(.white)
      .overlay {
        RoundedRectangle(cornerRadius: 4)
          .stroke(.gray, lineWidth: 1)
      }
      .padding(.bottom, 4)
      List($searchResults, id: \.self) { result in
        let containsResult = selectedFibers.contains(where: { $0 == result.wrappedValue })
        let backgroundColor = containsResult ? Color.blue : Color.clear
        let textColor = containsResult ? Color.white : Color.black
        Button(result.wrappedValue.displayName) {
          if containsResult {
            selectedFibers = selectedFibers.filter({ $0 != result.wrappedValue })
          } else {
            selectedFibers.append(result.wrappedValue)
            fiberTextFieldFocus = false
          }
        }
        .foregroundStyle(textColor)
        .listRowBackground(
          RoundedRectangle(cornerRadius: 8)
            .foregroundStyle(backgroundColor)
        )
      }
      .listStyle(.inset)
      Spacer()
    }
    .padding(.horizontal, 8)
    .background(Color.gray.opacity(0.1))
    .animation(.easeOut(duration: 0.15), value: fiberTextFieldFocus)
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
  // FabricInputView()
  VStack {
    FabricInputView().selectFibersView
  }
}
