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
