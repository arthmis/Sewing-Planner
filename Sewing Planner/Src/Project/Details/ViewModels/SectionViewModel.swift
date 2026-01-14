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

  func addItem(text: String, note: String?, db: AppDatabase) throws {
    try db.getWriter().write { db in
      // TODO: do this in a transaction or see if the write is already a transaction
      let order = Int64(items.count)
      var recordInput = SectionItemInputRecord(
        text: text.trimmingCharacters(in: .whitespacesAndNewlines),
        order: order,
        sectionId: section.id
      )
      recordInput.sectionId = section.id
      try recordInput.save(db)
      let record = SectionItemRecord(from: recordInput)

      if let noteText = note {
        var noteInputRecord = SectionItemNoteInputRecord(
          text: noteText.trimmingCharacters(in: .whitespacesAndNewlines),
          sectionItemId: record.id
        )
        try noteInputRecord.save(db)
        let noteRecord = SectionItemNoteRecord(from: noteInputRecord)
        let sectionItem = SectionItem(record: record, note: noteRecord)
        items.append(sectionItem)
      } else {
        let sectionItem = SectionItem(record: record, note: nil)
        items.append(sectionItem)
      }
    }
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
