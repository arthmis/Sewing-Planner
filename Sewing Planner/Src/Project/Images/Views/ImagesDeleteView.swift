import SwiftUI

struct InlineImagesDeleteDialogView: View {
  @Environment(\.db) private var db
  @Environment(ProjectViewModel.self) private var project
  let deleteDisabled: Bool

  @Binding var showDeleteImagesDialog: Bool

  var body: some View {
    HStack(alignment: .center) {
      Button("Cancel") {
        project.send(event: .CancelImageDeletion, db: db)
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
