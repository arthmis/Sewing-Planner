//
//  SectionView.swift
//  Sewing Planner
//
//  Created by Art on 10/11/24.
//

import SwiftUI

struct SectionView: View {
  @Binding var model: Section
  @Environment(ProjectViewModel.self) var project
  let db: AppDatabase
  @State private var isEditingSectionName = false
  @State private var bindedName: String = ""
  @State private var validationError = ""
  @State private var size: CGFloat = 0
  @State private var showDeleteItemsDialog = false

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
    project.send(
      event: .UpdateSectionName(section: section, oldName: model.section.name),
      db: db
    )

    isEditingSectionName = false
    validationError = ""
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(model.section.name)
          .font(.custom("SourceSans3-Medium", size: 16))
          .frame(maxWidth: .infinity, maxHeight: 30, alignment: .leading)
          .contentShape(Rectangle())
          .onTapGesture {
            if !isEditingSectionName && !model.isEditingSection {
              bindedName = model.section.name
              isEditingSectionName = true
            }
          }
          .sheet(isPresented: $isEditingSectionName) {
            validationError = ""
          } content: {
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
            .padding(12)
            .onGeometryChange(for: CGFloat.self) { proxy in
              proxy.size.height
            } action: { newValue in
              withAnimation(.easeOut(duration: 0.15)) {
                size = newValue
              }
            }
            .presentationDetents([.height(size)])
          }

        if model.isEditingSection {
          HStack {
            Button("Cancel") {
              withAnimation(.smooth(duration: 0.2)) {
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
            project.showDeleteSectionConfirmationDialog(section: model.section)
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
      .overlay(
        Divider()
          .frame(maxWidth: .infinity, maxHeight: 1)
          .background(Color(red: 230, green: 230, blue: 230)),
        alignment: .bottom
      )
      VStack(spacing: 0) {
        ForEach($model.items, id: \.self.record.id) { $item in
          if !model.isEditingSection {
            ItemView(
              data: $item,
              sectionId: model.section.id,
              updateCompletedState: model.updateCompletedState,
            )
            .contentShape(Rectangle())
            .onLongPressGesture {
              withAnimation(.smooth(duration: 0.2)) {
                model.isEditingSection = true
                model.selectedItems.insert(item.record.id)
              }
            }
            .padding(.top, 4)
          } else {
            let appDatabase = db
            SelectedSectionItemView(
              data: $item,
              selected: $model.selectedItems,
              updateText: model.updateText,
              updateCompletedState: model.updateCompletedState
            )
            .contentShape(Rectangle())
            .onDrag {
              model.draggedItem = item
              return NSItemProvider(object: "\(item.hashValue)" as NSString)
            }
            .onDrop(
              of: [.text],
              delegate: DropSectionItemViewDelegate(
                item: item,
                data: $model.items,
                draggedItem: $model.draggedItem,
                saveNewOrder: model.saveOrder,
                db: appDatabase,
              )
            )
            .padding(.top, 4)
          }
        }
        .frame(maxWidth: .infinity)
      }
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
        do {
          try model.deleteSelectedItems(db: db)
          withAnimation(.easeOut(duration: 0.2)) {
            model.isEditingSection = false
            model.selectedItems.removeAll()
          }
        } catch {
          project.handleError(error: .deleteSectionItems)
        }
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
  @Binding var data: SectionItem
  @State var newText = ""
  @Binding var selected: Set<Int64>
  var updateText: (Int64, String, String?, AppDatabase) throws -> Void
  var updateCompletedState: (Int64, AppDatabase) throws -> Void

  var isSelected: Bool {
    selected.contains(data.record.id)
  }

  private var hasNote: Bool {
    data.note != nil
  }

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      Toggle(data.record.text, isOn: $data.record.isComplete)
        .toggleStyle(
          CheckboxStyle(
            id: data.record.id,
            hasNote: hasNote,
            updateCompletedState: updateCompletedState,
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
      if !isSelected {
        selected.insert(data.record.id)
      } else {
        selected.remove(data.record.id)
      }
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
