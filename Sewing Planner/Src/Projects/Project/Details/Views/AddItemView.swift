//
//  AddItemView.swift
//  Sewing Planner
//
//  Created by Art on 11/29/24.
//

import SwiftUI

struct AddItemView: View {
  @Environment(StateStore.self) var store
  @Environment(\.db) var db
  @Binding var isAddingItem: Bool
  @State var newItem = ""
  @State var showErrorText = false
  @State var itemNote = ""
  let sectionId: Int64
  let errorText = "Item text can't be empty."

  private var isNewItemTextValid: Bool {
    !newItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  func add() {
    guard isNewItemTextValid else {
      showErrorText = true
      return
    }

    let validText = newItem.trimmingCharacters(in: .whitespacesAndNewlines)
    let validNoteText = itemNote.trimmingCharacters(in: .whitespacesAndNewlines)
    let noteText = validNoteText.isEmpty ? nil : validNoteText
    if let projectId = store.projectsState.selectedProject?.projectData.data.id {
      store.send(
        event: .projects(
          .projectEvent(
            projectId: projectId,
            .StoreSectionItem(text: validText, note: noteText, sectionId: sectionId)
          )
        ),
        db: db
      )
    }
    showErrorText = false
    isAddingItem = false
    newItem = ""
    itemNote = ""
  }

  var body: some View {
    if isAddingItem {
      VStack(alignment: .leading) {
        VStack {
          HStack {
            TextField("Task", text: $newItem, axis: .vertical).onSubmit {
              withAnimation(.easeOut(duration: 0.15)) {
                add()
              }
            }
            .textFieldStyle(.plain)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
            Button {
              withAnimation(.easeOut(duration: 0.15)) {
                showErrorText = false
                isAddingItem = false
                newItem = ""
                itemNote = ""
              }
            } label: {
              Image(systemName: "xmark.circle")
                .foregroundStyle(Color.red)
                .font(.system(size: 24, weight: Font.Weight.thin))
            }
            .padding([.trailing], 8)
          }
          .contentShape(Rectangle())
          TextField("Note", text: $itemNote, axis: .vertical)
            .onSubmit {}
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
            withAnimation(.easeOut(duration: 0.25)) {
              add()
            }
          } label: {
            Image(systemName: "arrow.up.circle.fill")
              .font(.system(size: 32))
          }
          .disabled(!isNewItemTextValid)
          .padding([.trailing, .bottom], 8)
        }
        .frame(maxWidth: .infinity, alignment: .bottomTrailing)
      }
      .background(Color(hex: 0xF2F2F2, opacity: 0.9))
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .transition(.revealFrom(edge: .top))
    } else {
      Button {
        withAnimation(.easeOut(duration: 0.3)) {
          isAddingItem = true
        }
      } label: {
        HStack {
          Image(systemName: "plus")
          Text("New Item")
        }
      }
      .buttonStyle(SecondaryButtonStyle())
      .accessibilityIdentifier("NewStepButton")
      .transition(.revealFrom(edge: .bottom))
    }
  }
}

struct SecondaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    let isPressed = configuration.isPressed
    configuration.label
      .padding([.vertical], 8)
      .padding([.horizontal], 8)
      .background(Color(hex: 0xD9D9D9, opacity: 0.5))
      .foregroundColor(.black)
      .clipShape(RoundedRectangle(cornerRadius: 4))
      .scaleEffect(isPressed ? 0.95 : 1)
      .brightness(isPressed ? -0.05 : 0)
      //            .shadow(color: Color(hex: 0xCFCFCF), radius: isPressed ? 1.5 : 3, x: 1, y: 3)
      .animation(.easeIn(duration: 0.1), value: isPressed)
  }
}

struct SheetPrimaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    let isPressed = configuration.isPressed
    configuration.label
      .padding([.top, .bottom], 16)
      .padding([.leading, .trailing], 16)
      .frame(maxWidth: .infinity)
      //      .background(Color(hex: 0xEFEFEF, opacity: 0.5))
      .background(Color(hex: 0x131944, opacity: 1.0))
      .foregroundColor(.white)
      .clipShape(RoundedRectangle(cornerRadius: 4))
      .scaleEffect(isPressed ? 0.95 : 1)
      .brightness(isPressed ? -0.05 : 0)
      //            .shadow(color: Color(hex: 0xCFCFCF), radius: isPressed ? 1.5 : 3, x: 1, y: 3)
      .animation(.easeIn(duration: 0.1), value: isPressed)
  }
}

//#Preview {
//  @Previewable @State var isAddingItem = true
//  @Previewable @State var newItem = ""
//
//  AddItemView(isAddingItem: $isAddingItem, addItem: { val, _ throws in print(val) })
//    .frame(height: 300)
//    .padding(8)
//}
