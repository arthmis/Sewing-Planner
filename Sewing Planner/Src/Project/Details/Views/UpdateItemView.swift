//
//  UpdateItemView.swift
//  Sewing Planner
//
//  Created by Art on 11/29/24.
//

import SwiftUI

struct UpdateItemView: View {
  @Environment(ProjectViewModel.self) var project
  @Environment(\.db) var db
  @Binding var data: SectionItem
  @Binding var isEditing: Bool
  @Binding var newText: String
  @Binding var newNoteText: String
  @State var showErrorText = false
  let sectionId: Int64
  let errorText = "Item text can't be empty."

  private var isNewTextValid: Bool {
    newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  func update() {
    guard !isNewTextValid else {
      showErrorText = true
      return
    }

    let validText = newText.trimmingCharacters(in: .whitespacesAndNewlines)
    let validNoteText = newNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
    let noteText = validNoteText.isEmpty ? nil : validNoteText
    let updatedSectionItem = data.update(text: validText, noteText: noteText)

    project.send(
      event: .StoreUpdatedSectionItemText(item: updatedSectionItem, sectionId: sectionId),
      db: db
    )

    showErrorText = false
    isEditing = false
  }

  var body: some View {
    VStack(alignment: .leading) {
      VStack {
        HStack {
          TextField("Task", text: $newText, axis: .vertical)
            .textFieldStyle(.plain)
            .onSubmit {
              update()
            }
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
          Button {
            showErrorText = false
            isEditing = false
            newText = ""
            newNoteText = ""
          } label: {
            Image(systemName: "xmark.circle")
              .foregroundStyle(Color.red)
              .font(.system(size: 24, weight: Font.Weight.thin))
          }
          .padding([.trailing], 8)
        }
        TextField("Note", text: $newNoteText, axis: .vertical)
          .padding(.vertical, 4)
      }
      .padding(4)
      if showErrorText {
        Text(errorText)
          .padding(.leading, 8)
          .foregroundStyle(Color.red)
      }
      HStack(alignment: .lastTextBaseline) {
        Button {
          update()
        } label: {
          Image(systemName: "arrow.up.circle.fill")
            .font(.system(size: 32))
        }
        .disabled(isNewTextValid)
        .padding([.trailing, .bottom], 8)
      }
      .frame(maxWidth: .infinity, alignment: .bottomTrailing)
    }
    .background(Color(hex: 0xF2F2F2, opacity: 0.9))
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }
}

// #Preview {
//    @Previewable @State var record = SectionItem(record: SectionItemRecord(id: 1, text: "something", order: 0), note: SectionItemNoteRecord(text: "nonte", sectionItemId: 1))
//    @Previewable @State var isEditing = true
//    @Previewable @State var newText = ""
//    @Previewable @State var newNoteText = ""
//    UpdateItemView(data: $record, isEditing: $isEditing, newText: $newText, newNoteText: $newNoteText, updateText: { id, text, _ throws in print(id, text) }, resetToPreviousText: { () in print("resetting") })
//        .frame(height: 300)
// }
