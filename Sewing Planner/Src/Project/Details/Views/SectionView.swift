//
//  SectionView.swift
//  Sewing Planner
//
//  Created by Art on 10/11/24.
//

import SwiftUI

struct SectionView: View {
  @Environment(ProjectViewModel.self) var project
  @Binding var model: Section
  let db: AppDatabase
  @State private var showDeleteItemsDialog = false

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      SectionTitleView(
        model: $model,
        db: db,
        showDeleteItemsDialog: $showDeleteItemsDialog,
      )
      .overlay(
        Divider()
          .frame(maxWidth: .infinity, maxHeight: 1)
          .background(Color(red: 230, green: 230, blue: 230)),
        alignment: .bottom
      )
      SectionItemsListView(model: $model, db: db)
      AddItemView(
        isAddingItem: $model.isAddingItem,
        addItem: model.addItem,
        sectionId: model.section.id
      )
      .padding(.top, 8)
    }
    .animation(.easeOut(duration: 0.15), value: model.isAddingItem)
    .confirmationDialog(
      "Delete Items",
      isPresented: $showDeleteItemsDialog
    ) {
      Button("Delete", role: .destructive) {
        project.send(
          event: .deleteSelectedTasks(selected: model.selectedItems, sectionId: model.section.id),
          db: db
        )
      }
      Button("Cancel", role: .cancel) {
        showDeleteItemsDialog = false
      }
    } message: {
      if model.selectedItems.count > 1 {
        Text("Delete \(model.selectedItems.count) Items")
      } else {
        Text("Delete Item")
      }
    }
  }
}

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

struct DropSectionItemViewDelegate: DropDelegate {
  var item: SectionItem
  @Binding var data: [SectionItem]
  @Binding var draggedItem: SectionItem?
  var saveNewOrder: (AppDatabase) throws -> Void
  let db: AppDatabase

  func dropEntered(info _: DropInfo) {
    guard item != draggedItem,
      let current = draggedItem,
      let from = data.firstIndex(of: current),
      let to = data.firstIndex(of: item)
    else {
      return
    }
    if data[to] != current {
      withAnimation {
        data.move(fromOffsets: IndexSet(integer: from), toOffset: (to > from) ? to + 1 : to)
      }
    }
  }

  func dropUpdated(info _: DropInfo) -> DropProposal? {
    DropProposal(operation: .move)
  }

  func performDrop(info _: DropInfo) -> Bool {
    do {
      try saveNewOrder(db)
      draggedItem = nil
      return true
    } catch {
      // TODO: add logging for error
      return false
    }
  }
}
