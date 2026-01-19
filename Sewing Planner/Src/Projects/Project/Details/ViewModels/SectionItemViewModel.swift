//
//  SectionItemViewModel.swift
//  Sewing Planner
//
//  Created by Art on 9/29/25.
//

import Foundation
import GRDB

struct SectionItem: Decodable, FetchableRecord, Hashable {
  var record: SectionItemRecord
  var note: SectionItemNoteRecord?

  func update(text: String, noteText: String?) -> SectionItem {
    var item = self
    item.record.text = text
    if let noteText = noteText {
      item.note?.text = noteText
    }

    return item
  }
}
