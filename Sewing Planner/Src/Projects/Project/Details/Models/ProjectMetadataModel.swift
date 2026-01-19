//
//  ProjectMetadataModel.swift
//  Sewing Planner
//
//  Created by Art on 10/30/24.
//

import GRDB
import SwiftUI

struct ProjectMetadata: Hashable, Codable, EncodableRecord, FetchableRecord,
  MutablePersistableRecord, TableRecord
{
  var id: Int64
  var name: String
  var completed: Bool
  var isDeleted: Bool
  var createDate: Date
  var updateDate: Date
  static let databaseTableName = "project"

  init(id: Int64, name: String, completed: Bool, createDate: Date, updateDate: Date) {
    self.id = id
    self.name = name
    self.completed = completed
    self.createDate = createDate
    self.updateDate = updateDate
    isDeleted = false
  }

  init(from input: ProjectMetadataInput) {
    id = input.id!
    name = input.name
    completed = input.completed
    createDate = input.createDate
    updateDate = input.updateDate
    isDeleted = input.isDeleted
  }
}

struct ProjectMetadataInput: Hashable, Codable, EncodableRecord, MutablePersistableRecord,
  TableRecord
{
  var id: Int64?
  var name: String
  var completed: Bool
  var isDeleted: Bool
  var createDate: Date
  var updateDate: Date
  static let databaseTableName = "project"

  mutating func didInsert(_ inserted: InsertionSuccess) {
    id = inserted.rowID
  }

  init(id: Int64?, name: String, completed: Bool, createDate: Date, updateDate: Date) {
    self.id = id
    self.name = name
    self.completed = completed
    self.createDate = createDate
    self.updateDate = updateDate
    isDeleted = false
  }

  init() {
    name = "Project Name"
    completed = false
    let now = Date()
    createDate = now
    updateDate = now
    isDeleted = false
  }
}

enum ProjectColumns: String, ColumnExpression {
  case id
  case name
  case completed
  case updateDate
  case createDate
}
