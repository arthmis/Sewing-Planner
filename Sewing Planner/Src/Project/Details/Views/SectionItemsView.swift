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
