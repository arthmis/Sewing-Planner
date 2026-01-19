//
//  ItemView.swift
//  Sewing Planner
//
//  Created by Art on 10/11/24.
//

import SwiftUI

struct ItemView: View {
  @Binding var data: SectionItem
  @Environment(ProjectViewModel.self) var project
  @Environment(\.db) var db
  @State var isEditing = false
  @State var newText = ""
  @State var newNoteText = ""
  let sectionId: Int64

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
    VStack {
      if isEditing {
        UpdateItemView(
          data: $data,
          isEditing: $isEditing,
          newText: $newText,
          newNoteText: $newNoteText,
          sectionId: sectionId,
        )
        .transition(.revealFrom(edge: .top).combined(with: .opacity))
      } else {
        VStack(alignment: .leading, spacing: 0) {
          HStack(alignment: .firstTextBaseline) {
            Toggle(data.record.text, isOn: $data.record.isComplete).toggleStyle(
              CheckboxStyle(
                id: data.record.id,
                hasNote: hasNote,
                toggleCompletedState: toggleCompletedState,
                isSelected: false
              )
            )
            Spacer()
          }
        }
        .contentShape(Rectangle())
        .onTapGesture {
          if !isEditing {
            isEditing = true
            newText = data.record.text
            newNoteText =
              if let note = data.note {
                note.text
              } else {
                ""
              }
          }
        }
      }
    }
    .animation(.easeOut(duration: 0.075), value: isEditing)
  }
}

struct CheckboxStyle: ToggleStyle {
  @Environment(ProjectViewModel.self) var project
  @Environment(\.db) var db
  var id: Int64
  var hasNote: Bool
  var toggleCompletedState: () -> Void
  let isSelected: Bool

  func makeBody(configuration: Configuration) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
      Button {
        // TODO: move this side effect out of the checkbox
        // doesn't make sense for it to be here
        // might even need to make my own checkbox view
        toggleCompletedState()

        configuration.isOn.toggle()
      } label: {
        Image(systemName: configuration.isOn ? "checkmark.square" : "square")
      }
      VStack(spacing: 0) {
        configuration.label
          .frame(maxWidth: .infinity, alignment: .topLeading)
        if hasNote {
          Image(systemName: "note.text")
            .font(.system(size: 14, weight: Font.Weight.light))
            .foregroundStyle(isSelected ? Color.white : Color.gray)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
      }
    }
  }
}

// #Preview {
//    @Previewable @State var val = SectionItem(record: SectionItemRecord(text: "This is really long task to see how it gets displayed. Making this message way longer because it still isn't long enough", order: 1), note: SectionItemNoteRecord(text: "string", sectionItemId: 1))
//    var updateText: (Int64, String, String?) throws -> Void
//    var updateCompletedState: (Int64) throws -> Void
//
//    ItemView(data: $val) { id, _, _ in
//        print(id)
//    } updateCompletedState: { id in
//        print(id)
//    }
//    .padding(30)
//    .border(Color.black, width: 1)
//    .frame(maxWidth: 400, maxHeight: 400)
//    .background(.white)
// }
