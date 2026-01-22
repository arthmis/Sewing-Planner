import SwiftUI

struct InlineImagesDeleteDialogView: View {
  @Environment(\.db) private var db
  @Environment(StateStore.self) private var store
  let deleteDisabled: Bool

  @Binding var showDeleteImagesDialog: Bool

  var body: some View {
    HStack(alignment: .center) {
      Button("Cancel") {
        store.send(event: .projects(.projectEvent(.CancelImageDeletion)), db: db)
      }
      .buttonStyle(SecondaryButtonStyle())
      Spacer()
      Button {
        showDeleteImagesDialog = true
      } label: {
        HStack {
          Text("Delete")
          Image(systemName: "trash")
            .font(.system(size: 20, weight: Font.Weight.medium))
            .foregroundStyle(Color.white)
        }
      }
      .disabled(deleteDisabled)
      .buttonStyle(DeleteButtonStyle())
    }
    .padding(.top, 16)
  }
}
