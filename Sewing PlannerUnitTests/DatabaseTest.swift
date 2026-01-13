//
//  DatabaseTest.swift
//  Sewing PlannerTests
//
//  Created by Art on 9/9/24.
//

import Foundation
import GRDB
import Testing

@testable import Sewing_Planner

struct Sewing_PlannerDatabaseTests {
  @Test("Test add project")
  func testAddProject() throws {
    let db = AppDatabase.empty()

    let now = Date()
    var projectInput = ProjectMetadataInput(
      id: nil,
      name: "Project 1",
      completed: false,
      createDate: now,
      updateDate: now
    )
    let project = try db.addProject(project: &projectInput)

    #expect(project.id == 1)
    #expect(project.name == "Project 1")
  }
}
