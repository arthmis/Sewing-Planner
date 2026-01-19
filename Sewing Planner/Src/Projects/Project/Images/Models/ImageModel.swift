//
//  ImageModel.swift
//  Sewing Planner
//
//  Created by Art on 10/30/24.
//

import GRDB
import SwiftUI

struct ProjectImageRecord: Identifiable, Codable, EncodableRecord, FetchableRecord,
  MutablePersistableRecord, TableRecord
{
  var id: Int64
  var projectId: Int64
  var filePath: String
  var thumbnail: String
  var isDeleted: Bool
  var createDate: Date
  var updateDate: Date
  static let databaseTableName = "projectImage"

  init(from input: ProjectImageRecordInput) {
    id = input.id!
    projectId = input.projectId
    filePath = input.filePath
    thumbnail = input.thumbnail
    isDeleted = input.isDeleted
    createDate = input.createDate
    updateDate = input.updateDate
  }
}

struct ProjectImageRecordInput: Identifiable, Codable, EncodableRecord, MutablePersistableRecord,
  TableRecord
{
  var id: Int64?
  var projectId: Int64
  var filePath: String
  var thumbnail: String
  var isDeleted: Bool
  var createDate: Date
  var updateDate: Date
  static let databaseTableName = "projectImage"

  mutating func didInsert(_ inserted: InsertionSuccess) {
    id = inserted.rowID
  }
}
