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

  private func seedSection(section: SectionInputRecord, db: AppDatabase) throws {
    var sectionInput = section

    try db.getWriter().write { db in
      try sectionInput.save(db)
    }
  }

  private func seedSections(sections: [SectionInputRecord], db: AppDatabase) throws {
    try sections.forEach { section in
      try seedSection(section: section, db: db)
    }
  }

  private func seedSectionItems(
    section: [(SectionItemInputRecord, SectionItemNoteInputRecord?)],
    db: AppDatabase
  ) throws {
    try db.getWriter().write { db in
      try section.forEach { itemInput in
        var (item, note) = itemInput
        try item.insert(db)

        if var note = note {
          try note.insert(db)
        }
      }
    }
  }

  // MARK: - Project Image Records Tests

  private func seedProjectImage(image: ProjectImageRecordInput, db: AppDatabase) throws {
    var imageInput = image

    try db.getWriter().write { db in
      try imageInput.save(db)
    }
  }

  private func seedProjectImages(images: [ProjectImageRecordInput], db: AppDatabase) throws {
    try images.forEach { image in
      try seedProjectImage(image: image, db: db)
    }
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

  @Test("Test get project that doesn't exist")
  func testGetProjectThatDoesNotExist() throws {
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

    let project = try db.getProject(id: 2)
    #expect(project == nil)

  }

  @Test("Test get project section item")
  func testGetProjectSectionItem() throws {
    let appDb = AppDatabase.empty()
    let now = Date()
    let projectInput = ProjectMetadataInput(
      id: nil,
      name: "Project 1",
      completed: false,
      createDate: now,
      updateDate: now
    )
    try seedProject(project: projectInput, db: appDb)

    let sectionRecordInput = SectionInputRecord(
      id: nil,
      projectId: 1,
      name: "Section 1",
      isDeleted: false,
      createDate: now,
      updateDate: now
    )
    try seedSection(section: sectionRecordInput, db: appDb)

    let sectionItemInput: [(SectionItemInputRecord, SectionItemNoteInputRecord?)] = [
      (SectionItemInputRecord(text: "text", order: 0, sectionId: 1), nil)
    ]
    try seedSectionItems(section: sectionItemInput, db: appDb)

    let sectionItems = try appDb.reader.read { db in
      let sectionItems = try appDb.getSectionItems(sectionId: 1, from: db)
      return sectionItems
    }

    #expect(sectionItems.count == 1)
    #expect(sectionItems[0].record.text == "text")
  }

  @Test("Test get project section items")
  func testGetProjectSectionItems() throws {
    let appDb = AppDatabase.empty()
    let now = Date()
    let projectInput = ProjectMetadataInput(
      id: nil,
      name: "Project 1",
      completed: false,
      createDate: now,
      updateDate: now
    )
    try seedProject(project: projectInput, db: appDb)

    let sectionRecordInput = SectionInputRecord(
      id: nil,
      projectId: 1,
      name: "Section 1",
      isDeleted: false,
      createDate: now,
      updateDate: now
    )
    try seedSection(section: sectionRecordInput, db: appDb)

    let sectionItemInput: [(SectionItemInputRecord, SectionItemNoteInputRecord?)] = [
      (SectionItemInputRecord(text: "text", order: 0, sectionId: 1), nil),
      (
        SectionItemInputRecord(text: "text 2", order: 1, sectionId: 1),
        SectionItemNoteInputRecord(text: "note 2", sectionItemId: 2)
      ),
      (
        SectionItemInputRecord(text: "text 3", order: 2, sectionId: 1),
        nil
      ),
    ]
    try seedSectionItems(section: sectionItemInput, db: appDb)

    let sectionItems = try appDb.reader.read { db in
      let sectionItems = try appDb.getSectionItems(sectionId: 1, from: db)
      return sectionItems
    }

    #expect(sectionItems.count == 3)
    #expect(sectionItems[1].record.text == "text 2")
    #expect(sectionItems[1].note?.text == "note 2")
    #expect(sectionItems[2].note == nil)
  }

  @Test("Test get project section items order")
  func testGetProjectSectionItemsOrder() throws {
    let appDb = AppDatabase.empty()
    let now = Date()
    let projectInput = ProjectMetadataInput(
      id: nil,
      name: "Project 1",
      completed: false,
      createDate: now,
      updateDate: now
    )
    try seedProject(project: projectInput, db: appDb)

    let sectionRecordInput = SectionInputRecord(
      id: nil,
      projectId: 1,
      name: "Section 1",
      isDeleted: false,
      createDate: now,
      updateDate: now
    )
    try seedSection(section: sectionRecordInput, db: appDb)

    let sectionItemInput: [(SectionItemInputRecord, SectionItemNoteInputRecord?)] = [
      (SectionItemInputRecord(text: "text", order: 0, sectionId: 1), nil),
      (
        SectionItemInputRecord(text: "text 2", order: 1, sectionId: 1),
        SectionItemNoteInputRecord(text: "note 2", sectionItemId: 2)
      ),
      (
        SectionItemInputRecord(text: "text 3", order: 2, sectionId: 1),
        nil
      ),
    ]
    try seedSectionItems(section: sectionItemInput, db: appDb)

    let sectionItems = try appDb.reader.read { db in
      let sectionItems = try appDb.getSectionItems(sectionId: 1, from: db)
      return sectionItems
    }

    var startingOrder = sectionItems[0].record.order
    let iter = sectionItems.makeIterator().dropFirst()
    for item in iter {
      #expect(item.record.order > startingOrder)
      startingOrder = item.record.order
    }
  }

  @Test("Test get project sections")
  func testGetProjectSections() throws {
    let appDb = AppDatabase.empty()
    let now = Date()
    let projectInput = ProjectMetadataInput(
      id: nil,
      name: "Project 1",
      completed: false,
      createDate: now,
      updateDate: now
    )
    try seedProject(project: projectInput, db: appDb)

    let sectionsInput = [
      SectionInputRecord(
        id: nil,
        projectId: 1,
        name: "Section 1",
        isDeleted: false,
        createDate: now,
        updateDate: now
      )
    ]

    try seedSections(sections: sectionsInput, db: appDb)

    let sections = try appDb.getSections(projectId: 1)

    #expect(sections.count == 1)
    #expect(sections[0].items.isEmpty)
  }

  @Test("Test get project sections only returns sections for specified project")
  func testGetProjectSectionsFiltersByProject() throws {
    let appDb = AppDatabase.empty()
    let now = Date()

    let projectInput1 = ProjectMetadataInput(
      id: nil,
      name: "Project 1",
      completed: false,
      createDate: now,
      updateDate: now
    )
    try seedProject(project: projectInput1, db: appDb)

    let projectInput2 = ProjectMetadataInput(
      id: nil,
      name: "Project 2",
      completed: false,
      createDate: now,
      updateDate: now
    )
    try seedProject(project: projectInput2, db: appDb)

    let sectionsInput = [
      SectionInputRecord(
        id: nil,
        projectId: 1,
        name: "Project 1 Section A",
        isDeleted: false,
        createDate: now,
        updateDate: now
      ),
      SectionInputRecord(
        id: nil,
        projectId: 1,
        name: "Project 1 Section B",
        isDeleted: false,
        createDate: now,
        updateDate: now
      ),
      SectionInputRecord(
        id: nil,
        projectId: 2,
        name: "Project 2 Section A",
        isDeleted: false,
        createDate: now,
        updateDate: now
      ),
    ]
    try seedSections(sections: sectionsInput, db: appDb)

    let project1Sections = try appDb.getSections(projectId: 1)

    #expect(project1Sections.count == 2)
    #expect(project1Sections[0].section.name == "Project 1 Section A")
    #expect(project1Sections[0].section.projectId == 1)
    #expect(project1Sections[1].section.name == "Project 1 Section B")
    #expect(project1Sections[1].section.projectId == 1)

    let project2Sections = try appDb.getSections(projectId: 2)

    #expect(project2Sections.count == 1)
    #expect(project2Sections[0].section.name == "Project 2 Section A")
    #expect(project2Sections[0].section.projectId == 2)
  }

  @Test("Test get project sections returns empty array for project with no sections")
  func testGetProjectSectionsReturnsEmptyForProjectWithNoSections() throws {
    let appDb = AppDatabase.empty()
    let now = Date()

    let projectInput1 = ProjectMetadataInput(
      id: nil,
      name: "Project with sections",
      completed: false,
      createDate: now,
      updateDate: now
    )
    try seedProject(project: projectInput1, db: appDb)

    let projectInput2 = ProjectMetadataInput(
      id: nil,
      name: "Project without sections",
      completed: false,
      createDate: now,
      updateDate: now
    )
    try seedProject(project: projectInput2, db: appDb)

    let sectionsInput = [
      SectionInputRecord(
        id: nil,
        projectId: 1,
        name: "Section A",
        isDeleted: false,
        createDate: now,
        updateDate: now
      )
    ]
    try seedSections(sections: sectionsInput, db: appDb)

    let project2Sections = try appDb.getSections(projectId: 2)

    #expect(project2Sections.isEmpty)
  }

  @Test("Test get section items only returns items for specified section")
  func testGetSectionItemsFiltersBySection() throws {
    let appDb = AppDatabase.empty()
    let now = Date()

    let projectInput = ProjectMetadataInput(
      id: nil,
      name: "Project 1",
      completed: false,
      createDate: now,
      updateDate: now
    )
    try seedProject(project: projectInput, db: appDb)

    let sectionsInput = [
      SectionInputRecord(
        id: nil,
        projectId: 1,
        name: "Section 1",
        isDeleted: false,
        createDate: now,
        updateDate: now
      ),
      SectionInputRecord(
        id: nil,
        projectId: 1,
        name: "Section 2",
        isDeleted: false,
        createDate: now,
        updateDate: now
      ),
    ]
    try seedSections(sections: sectionsInput, db: appDb)

    // Add items to both sections
    let section1Items: [(SectionItemInputRecord, SectionItemNoteInputRecord?)] = [
      (SectionItemInputRecord(text: "Section 1 Item A", order: 0, sectionId: 1), nil),
      (SectionItemInputRecord(text: "Section 1 Item B", order: 1, sectionId: 1), nil),
    ]
    try seedSectionItems(section: section1Items, db: appDb)

    let section2Items: [(SectionItemInputRecord, SectionItemNoteInputRecord?)] = [
      (SectionItemInputRecord(text: "Section 2 Item A", order: 0, sectionId: 2), nil),
      (SectionItemInputRecord(text: "Section 2 Item B", order: 1, sectionId: 2), nil),
      (SectionItemInputRecord(text: "Section 2 Item C", order: 2, sectionId: 2), nil),
    ]
    try seedSectionItems(section: section2Items, db: appDb)

    let section1SectionItems = try appDb.reader.read { db in
      try appDb.getSectionItems(sectionId: 1, from: db)
    }

    #expect(section1SectionItems.count == 2)
    #expect(section1SectionItems[0].record.text == "Section 1 Item A")
    #expect(section1SectionItems[0].record.sectionId == 1)
    #expect(section1SectionItems[1].record.text == "Section 1 Item B")
    #expect(section1SectionItems[1].record.sectionId == 1)

    let section2SectionItems = try appDb.reader.read { db in
      try appDb.getSectionItems(sectionId: 2, from: db)
    }

    #expect(section2SectionItems.count == 3)
    #expect(section2SectionItems[0].record.text == "Section 2 Item A")
    #expect(section2SectionItems[0].record.sectionId == 2)
    #expect(section2SectionItems[1].record.text == "Section 2 Item B")
    #expect(section2SectionItems[1].record.sectionId == 2)
    #expect(section2SectionItems[2].record.text == "Section 2 Item C")
    #expect(section2SectionItems[2].record.sectionId == 2)
  }

  @Test("Test get section items returns empty array for section with no items")
  func testGetSectionItemsReturnsEmptyForSectionWithNoItems() throws {
    let appDb = AppDatabase.empty()
    let now = Date()

    let projectInput = ProjectMetadataInput(
      id: nil,
      name: "Project 1",
      completed: false,
      createDate: now,
      updateDate: now
    )
    try seedProject(project: projectInput, db: appDb)

    let sectionsInput = [
      SectionInputRecord(
        id: nil,
        projectId: 1,
        name: "Section with items",
        isDeleted: false,
        createDate: now,
        updateDate: now
      ),
      SectionInputRecord(
        id: nil,
        projectId: 1,
        name: "Section without items",
        isDeleted: false,
        createDate: now,
        updateDate: now
      ),
    ]
    try seedSections(sections: sectionsInput, db: appDb)

    let section1Items: [(SectionItemInputRecord, SectionItemNoteInputRecord?)] = [
      (SectionItemInputRecord(text: "Item A", order: 0, sectionId: 1), nil)
    ]
    try seedSectionItems(section: section1Items, db: appDb)

    let section2Items = try appDb.reader.read { db in
      try appDb.getSectionItems(sectionId: 2, from: db)
    }

    #expect(section2Items.isEmpty)
  }

  @Test("Test get project image records with images")
  func testGetProjectImageRecordsWithImages() throws {
    let appDb = AppDatabase.empty()
    let now = Date()

    let projectInput = ProjectMetadataInput(
      id: nil,
      name: "Project 1",
      completed: false,
      createDate: now,
      updateDate: now
    )
    try seedProject(project: projectInput, db: appDb)

    let imagesInput = [
      ProjectImageRecordInput(
        id: nil,
        projectId: 1,
        filePath: "/path/to/image1.jpg",
        thumbnail: "/path/to/thumb1.jpg",
        isDeleted: false,
        createDate: now,
        updateDate: now
      ),
      ProjectImageRecordInput(
        id: nil,
        projectId: 1,
        filePath: "/path/to/image2.jpg",
        thumbnail: "/path/to/thumb2.jpg",
        isDeleted: false,
        createDate: now,
        updateDate: now
      ),
    ]
    try seedProjectImages(images: imagesInput, db: appDb)

    let imageRecords = try appDb.getProjectImageRecords(projectId: 1)

    #expect(imageRecords.count == 2)
    #expect(imageRecords[0].filePath == "/path/to/image1.jpg")
    #expect(imageRecords[0].thumbnail == "/path/to/thumb1.jpg")
    #expect(imageRecords[1].filePath == "/path/to/image2.jpg")
    #expect(imageRecords[1].thumbnail == "/path/to/thumb2.jpg")
  }

  @Test("Test get project image records with no images")
  func testGetProjectImageRecordsWithNoImages() throws {
    let appDb = AppDatabase.empty()
    let now = Date()

    let projectInput = ProjectMetadataInput(
      id: nil,
      name: "Project 1",
      completed: false,
      createDate: now,
      updateDate: now
    )
    try seedProject(project: projectInput, db: appDb)

    let imageRecords = try appDb.getProjectImageRecords(projectId: 1)

    #expect(imageRecords.isEmpty)
  }

  @Test("Test get project image records ordering")
  func testGetProjectImageRecordsOrdering() throws {
    let appDb = AppDatabase.empty()
    let now = Date()

    let projectInput = ProjectMetadataInput(
      id: nil,
      name: "Project 1",
      completed: false,
      createDate: now,
      updateDate: now
    )
    try seedProject(project: projectInput, db: appDb)

    let imagesInput = [
      ProjectImageRecordInput(
        id: nil,
        projectId: 1,
        filePath: "/path/to/first.jpg",
        thumbnail: "/path/to/thumb_first.jpg",
        isDeleted: false,
        createDate: now,
        updateDate: now
      ),
      ProjectImageRecordInput(
        id: nil,
        projectId: 1,
        filePath: "/path/to/second.jpg",
        thumbnail: "/path/to/thumb_second.jpg",
        isDeleted: false,
        createDate: now,
        updateDate: now
      ),
      ProjectImageRecordInput(
        id: nil,
        projectId: 1,
        filePath: "/path/to/third.jpg",
        thumbnail: "/path/to/thumb_third.jpg",
        isDeleted: false,
        createDate: now,
        updateDate: now
      ),
    ]
    try seedProjectImages(images: imagesInput, db: appDb)

    let imageRecords = try appDb.getProjectImageRecords(projectId: 1)

    #expect(imageRecords.count == 3)

    // Verify ordering by id (ascending)
    var previousId = imageRecords[0].id
    let iter = imageRecords.makeIterator().dropFirst()
    for record in iter {
      #expect(record.id > previousId)
      previousId = record.id
    }
  }

  @Test("Test get project image records only returns images for specified project")
  func testGetProjectImageRecordsFiltersByProject() throws {
    let appDb = AppDatabase.empty()
    let now = Date()

    let projectInput1 = ProjectMetadataInput(
      id: nil,
      name: "Project 1",
      completed: false,
      createDate: now,
      updateDate: now
    )
    try seedProject(project: projectInput1, db: appDb)

    let projectInput2 = ProjectMetadataInput(
      id: nil,
      name: "Project 2",
      completed: false,
      createDate: now,
      updateDate: now
    )
    try seedProject(project: projectInput2, db: appDb)

    let imagesInput = [
      ProjectImageRecordInput(
        id: nil,
        projectId: 1,
        filePath: "/path/to/project1_image.jpg",
        thumbnail: "/path/to/project1_thumb.jpg",
        isDeleted: false,
        createDate: now,
        updateDate: now
      ),
      ProjectImageRecordInput(
        id: nil,
        projectId: 2,
        filePath: "/path/to/project2_image.jpg",
        thumbnail: "/path/to/project2_thumb.jpg",
        isDeleted: false,
        createDate: now,
        updateDate: now
      ),
    ]
    try seedProjectImages(images: imagesInput, db: appDb)

    let project1Images = try appDb.getProjectImageRecords(projectId: 1)

    #expect(project1Images.count == 1)
    #expect(project1Images[0].filePath == "/path/to/project1_image.jpg")
    #expect(project1Images[0].projectId == 1)

    let project2Images = try appDb.getProjectImageRecords(projectId: 2)

    #expect(project2Images.count == 1)
    #expect(project2Images[0].filePath == "/path/to/project2_image.jpg")
    #expect(project2Images[0].projectId == 2)
  }

}
