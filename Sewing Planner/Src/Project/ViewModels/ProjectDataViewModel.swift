//
//  ProjectDataViewModel.swift
//  Sewing Planner
//
//  Created by Art on 10/11/24.
//

import Foundation
import GRDB
import PhotosUI
import SwiftUI

@Observable
final class ProjectData {
  var data: ProjectMetadata
  var sections: [Section] = .init()
  var bindedName = ""
  var selectedSectionForDeletion: SectionRecord?
  var showDeleteSectionDialog = false

  init(data: ProjectMetadata) {
    self.data = data
  }

  init(data: ProjectMetadata, projectSections: [Section]) {
    self.data = data
    sections = projectSections
  }

  func addSection(db: AppDatabase) throws {
    try db.getWriter().write { db in
      let now = Date()
      var sectionInput = SectionInputRecord(
        projectId: data.id,
        name: "Section \(sections.count + 1)",
        createDate: now,
        updateDate: now
      )
      try sectionInput.save(db)
      let sectionRecord = SectionRecord(from: sectionInput)
      let section = Section(id: UUID(), name: sectionRecord)
      sections.append(section)
    }
  }

  func cancelDeleteSection() {
    selectedSectionForDeletion = nil
    showDeleteSectionDialog = false
  }

  static func getProject(with id: Int64, from db: AppDatabase) throws -> ProjectData? {
    do {
      if let project = try db.getProject(id: id) {
        let sections = try db.getSections(projectId: id)
        return ProjectData(data: project, projectSections: sections)
      }

    } catch {
      print("error retrieving data: \(error)")
    }
    return nil
  }
}
