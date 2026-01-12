import SwiftUI

struct SelectedSectionItemView: View {
  @Environment(ProjectViewModel.self) var project
  @Environment(\.db) var db
  @Binding var data: SectionItem
  @State var newText = ""
  @Binding var selected: Set<Int64>
  let sectionId: Int64

  var isSelected: Bool {
    selected.contains(data.record.id)
  }

  private var hasNote: Bool {
    data.note != nil
  }

  func toggleCompletedState() {
    project.send(
      event: .toggleSectionItemCompletionStatus(data.record, sectionId: sectionId),
      db: db
    )
  }

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      Toggle(data.record.text, isOn: $data.record.isComplete)
        .toggleStyle(
          CheckboxStyle(
            id: data.record.id,
            hasNote: hasNote,
            toggleCompletedState: toggleCompletedState,
            isSelected: isSelected
          )
        )
        .foregroundStyle(isSelected ? Color.white : Color.black)
      Spacer()
      Image(systemName: "line.3.horizontal")
        .padding(.trailing, 4)
        .foregroundStyle(isSelected ? Color.white : Color.black)
    }
    .contentShape(Rectangle())
    .padding(6)
    .background(isSelected ? Color.blue.opacity(0.5) : Color.white)
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .onTapGesture {
      project.send(
        event: .toggleSelectedSectionItem(withId: data.record.id, fromSectionWithId: sectionId),
        db: db
      )
    }
    .animation(.easeOut(duration: 0.1), value: isSelected)
  }
}
