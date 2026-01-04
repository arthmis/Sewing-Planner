//
//  Sewing_PlannerUnitTests.swift
//  Sewing PlannerUnitTests
//
//  Created by Art on 10/29/25.
//

import Foundation
import Testing

@testable import Sewing_Planner

struct Sewing_PlannerUnitTests {
  @MainActor private func initializeProjectViewModel() -> ProjectViewModel {
    let now = Date()
    let sections = [
      Section(
        id: UUID(),
        name: SectionRecord(
          id: 1,
          projectId: 1,
          name: "Section 1",
          isDeleted: false,
          createDate: now,
          updateDate: now
        )
      )
    ]
    let projectMetadata = ProjectMetadata(
      id: 1,
      name: "Project 1",
      completed: false,
      createDate: now,
      updateDate: now
    )

    let projectData = ProjectData(
      data: projectMetadata,
      projectSections: sections
    )

    let projectImages = ProjectImages(
      projectId: projectMetadata.id,
      images: []
    )

    let model = ProjectViewModel(
      data: projectData,
      projectsNavigation: [projectMetadata],
      projectImages: projectImages,
    )

    return model
  }

  @Test("Test initialize delete section")
  @MainActor func testInitiateDeleteSection() {
    let model = initializeProjectViewModel()

    let now = Date()
    let section = SectionRecord(
      id: 1,
      projectId: 1,
      name: "Section 1",
      isDeleted: false,
      createDate: now,
      updateDate: now
    )
    model.showDeleteSectionConfirmationDialog(section: section)

    #expect(model.projectData.selectedSectionForDeletion == section)
    #expect(model.projectData.showDeleteSectionDialog == true)
  }

  static let testDeleteSectionCases = [
    (
      SectionRecord(
        id: 1,
        projectId: 1,
        name: "Section 1",
        isDeleted: false,
        createDate: Date(timeIntervalSinceReferenceDate: 0),
        updateDate: Date(timeIntervalSinceReferenceDate: 0)
      ),
      Effect.deleteSection(
        section: SectionRecord(
          id: 1,
          projectId: 1,
          name: "Section 1",
          isDeleted: false,
          createDate: Date(timeIntervalSinceReferenceDate: 0),
          updateDate: Date(timeIntervalSinceReferenceDate: 0)
        )
      )
    ),
    (nil, Effect.doNothing),
  ]

  // @Test(
  //   "Test delete section",
  //   arguments: testDeleteSectionCases
  // )
  // @MainActor func testDeleteSection(section: SectionRecord?, expectedEffect: Effect) {
  //   let model = initializeProjectViewModel()

  //   let resultEffect = model.deleteSection(selectedSection: section)

  //   #expect(resultEffect == expectedEffect)
  // }

  @Test("Test store section item")
  @MainActor func testStoreSectionItem() {
    let model = initializeProjectViewModel()

    let effect = model.handleEvent(.StoreSectionItem(text: "task 1", note: nil, sectionId: 1))

    let expectedEffect = Effect.SaveSectionItem(
      text: "task 1",
      note: nil,
      order: 0,
      sectionId: 1
    )

    #expect(effect == expectedEffect)
  }

  @Test("Test add section item")
  @MainActor func testAddSectionItem() {
    let model = initializeProjectViewModel()

    let sectionTextRecord = SectionItemRecord(
      from: SectionItemInputRecord(id: 1, text: "hello", order: 0, sectionId: 1)
    )
    let effect = model.handleEvent(
      .AddSectionItem(item: SectionItem(record: sectionTextRecord), sectionId: 1)
    )

    #expect(effect == nil)

    let section = model.projectData.sections.first(where: { $0.section.id == 1 })!
    #expect(section.items.count == 1)
    #expect(section.items[0].record.id == 1)

  }
}
