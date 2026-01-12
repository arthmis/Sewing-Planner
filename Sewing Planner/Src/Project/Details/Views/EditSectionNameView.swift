import SwiftUI

struct EditSectionNameView: View {
  @Binding var isEditingSectionName: Bool
  @Binding var bindedName: String
  @Binding var validationError: String
  let saveNewName: () -> Void

  var body: some View {
    VStack {
      HStack {
        Spacer()
        Button {
          isEditingSectionName = false
        } label: {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 32))
            .foregroundStyle(.gray)
        }
      }
      TextField("Section Name", text: $bindedName)
        .onSubmit {
          saveNewName()
        }
        .textFieldStyle(.automatic)
        .padding(.vertical, 12)
        .font(.custom("SourceSans3-Medium", size: 16))
        .overlay(
          Rectangle()
            .frame(maxWidth: .infinity, maxHeight: 1)
            .foregroundStyle(Color.gray.opacity(0.5)),
          alignment: .bottom
        )
      HStack {
        Text(validationError)
          .foregroundStyle(.red)
          .padding(.top, 2)
        Spacer()
      }
      .transition(.move(edge: .top))

      Button("Save") {
        withAnimation(.easeOut(duration: 0.13)) {
          saveNewName()
        }
      }
      .buttonStyle(SheetPrimaryButtonStyle())
      .font(.system(size: 20))
      .padding(.top, 16)
    }

  }
}
