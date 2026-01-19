//
//  SectionViewModel.swift
//  Sewing Planner
//
//  Created by Art on 10/30/24.
//

import SwiftUI

enum FocusField {
  case header
  case addItem
}

@Observable
class Section {
  var section: SectionRecord
  var items: [SectionItem] = []
  var deletedItems: [SectionItemRecord] = []
  var selectedItems: Set<Int64> = []
  var isAddingItem = false
  var draggedItem: SectionItem?
  var isEditingSection = false
  var isBeingDeleted = false

  init(name: SectionRecord) {
    section = name
  }

  init(section: SectionRecord, items: [SectionItem]) {
    self.section = section
    self.items = items
  }

  var hasSelections: Bool {
    !selectedItems.isEmpty
  }

  func saveOrder(db: AppDatabase) throws {
    try db.getWriter().write { db in
      for case (let i, var item) in items.enumerated() {
        item.record.order = Int64(i)
        try item.record.update(db)
      }
    }
  }
}
