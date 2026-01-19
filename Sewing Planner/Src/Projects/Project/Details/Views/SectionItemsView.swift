import SwiftUI

struct SectionItemsListView: View {
  @Binding var model: Section
  let db: AppDatabase

  var body: some View {
    VStack(spacing: 0) {
      ForEach($model.items, id: \.self.record.id) { $item in
        if !model.isEditingSection {
          ItemView(
            data: $item,
            sectionId: model.section.id,
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
          SelectedSectionItemView(
            data: $item,
            selected: $model.selectedItems,
            sectionId: model.section.id
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
              db: db,
            )
          )
          .padding(.top, 4)
        }
      }
      .frame(maxWidth: .infinity)
    }
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
