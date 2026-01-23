import SwiftUI

struct SectionTitleView: View {
  @Environment(StateStore.self) var store
  @Environment(ProjectViewModel.self) var project
  @Binding var model: Section
  let db: AppDatabase
  @State private var isEditingSectionName = false
  @State private var bindedName: String = ""
  @State private var validationError = ""
  @Binding var showDeleteItemsDialog: Bool
  @State private var size: CGFloat = 0

  private func sanitize(_ val: String) -> String {
    return val.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func saveNewName() {
    let sanitizedName = sanitize(bindedName)
    guard !sanitizedName.isEmpty else {
      validationError = "Section name can't be empty."
      return
    }

    var section = model.section
    section.name = sanitizedName
    store.send(
      event: .projects(
        .projectEvent(
          projectId: project.projectData.data.id,
          .StoreUpdatedSectionName(section: section, oldName: model.section.name)
        )
      ),
      db: db
    )

    isEditingSectionName = false
    validationError = ""
  }

  var body: some View {
    HStack {
      Text(model.section.name)
        .font(.custom("SourceSans3-Medium", size: 16))
        .frame(maxWidth: .infinity, maxHeight: 30, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
          withAnimation(.easeOut(duration: 0.1)) {
            if !isEditingSectionName && !model.isEditingSection {
              bindedName = model.section.name
              isEditingSectionName = true
            }
          }
        }
        .sheet(isPresented: $isEditingSectionName) {
          validationError = ""
        } content: {
          EditSectionNameView(
            isEditingSectionName: $isEditingSectionName,
            bindedName: $bindedName,
            validationError: $validationError,
            saveNewName: saveNewName
          )
          .padding(12)
          .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
          } action: { newValue in
            withAnimation(.easeOut(duration: 0.1)) {
              size = newValue
            }
          }
          .presentationDetents([.height(size)])
        }

      if model.isEditingSection {
        HStack {
          Button("Cancel") {
            withAnimation(.easeOut(duration: 0.1)) {
              model.isEditingSection = false
              model.selectedItems.removeAll()
            }
          }
          Button {
            showDeleteItemsDialog = true
          } label: {
            Image(systemName: "trash")
              .foregroundStyle(Color.red)
              .padding(.horizontal, 8)
          }
          .disabled(!model.hasSelections)
        }
      }

      Menu {
        Button("Delete") {
          // TODO: try to remove usage of this question mark
          store.projectsState.selectedProject?.showDeleteSectionConfirmationDialog(
            section: model.section
          )
        }
        Button("Delete Items") {
          model.isEditingSection = true
        }
      } label: {
        Image(systemName: "ellipsis")
          .font(.system(size: 24))
      }
      .padding(.trailing, 16)
      .padding(.vertical, 8)
    }
  }
}
