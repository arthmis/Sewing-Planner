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
  private func seedProject(project: ProjectMetadataInput, db: AppDatabase) throws {
    var project = project
    _ = try db.addProject(project: &project)
  }

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

  @Test("Test get project")
  func testGetProject() throws {
    let db = AppDatabase.empty()
    let now = Date()
    let projectInput = ProjectMetadataInput(
      id: nil,
      name: "Project 1",
      completed: false,
      createDate: now,
      updateDate: now
    )
    try seedProject(project: projectInput, db: db)
    let projectInput2 = ProjectMetadataInput(
      id: nil,
      name: "Project 2",
      completed: true,
      createDate: now,
      updateDate: now
    )
    try seedProject(project: projectInput2, db: db)

    var project = try db.getProject(id: 1)!

    #expect(project.name == "Project 1")
    #expect(project.completed == false)

    project = try db.getProject(id: 2)!

    #expect(project.name == "Project 2")
    #expect(project.completed == true)
  }
}
