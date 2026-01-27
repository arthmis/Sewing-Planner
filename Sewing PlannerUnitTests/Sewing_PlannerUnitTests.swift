//
//  Sewing_PlannerUnitTests.swift
//  Sewing PlannerUnitTests
//
//  Created by Art on 10/29/25.
//

import Foundation
import Testing
import UIKit

@testable import Sewing_Planner

struct Sewing_PlannerUnitTests {
  @MainActor private func initializeStore(
    projectsState: ProjectsState? = nil
  ) -> StateStore {
    let projectsState = projectsState ?? ProjectsState()
    return StateStore(projectsState: projectsState)

  }
  @MainActor private func initializeProjectViewModel(
    sections: [ProjectSection]? = nil,
    images: ProjectImages? = nil,
    projectId: Int64? = nil
  ) -> ProjectViewModel {
    let projectId = projectId ?? 1
    let now = Date()
    let sections =
      sections ?? [
        ProjectSection(
          name: SectionRecord(
            id: 1,
            projectId: projectId,
            name: "Section 1",
            isDeleted: false,
            createDate: now,
            updateDate: now
          )
        )
      ]
    let projectMetadata = ProjectMetadata(
      id: projectId,
      name: "Project 1",
      completed: false,
      createDate: now,
      updateDate: now
    )

    let projectData = ProjectData(
      data: projectMetadata,
      projectSections: sections
    )

    let projectImages =
      images
      ?? ProjectImages(
        projectId: projectId,
        images: []
      )

    let projectsNavigation: ProjectsNavigation = .project(projectId)
    let model = ProjectViewModel(
      data: projectData,
      projectsNavigation: [projectsNavigation],
      projectImages: projectImages,
    )

    return model
  }

  @Test("Test rename section")
  @MainActor func testRenameSection() {
    let now = Date()
    let section = SectionRecord(
      id: 1,
      projectId: 1,
      name: "Section 1",
      isDeleted: false,
      createDate: now,
      updateDate: now
    )
    let sections = [
      ProjectSection(
        section: section,
        items: [],

      )
    ]
    let model = initializeProjectViewModel(sections: sections)
    let stateStore = initializeStore(projectsState: ProjectsState(selectedProject: model))

    let newSectionName = SectionRecord(
      id: 1,
      projectId: 1,
      name: "Materials",
      isDeleted: false,
      createDate: now,
      updateDate: now
    )
    let event: AppEvent = .projects(
      .projectEvent(
        projectId: 1,
        .StoreUpdatedSectionName(section: newSectionName, oldName: section.name)
      )
    )
    let effect = stateStore.handleEvent(event)

    let expectedEffect: Effect = .updateSectionName(section: newSectionName, oldName: section.name)
    #expect(effect == expectedEffect)

    let updatedSection = model.projectData.sections.first(where: { $0.section.id == section.id })!
    #expect(updatedSection.section.name == newSectionName.name)
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
    )
  ]

  @Test(
    "Test initiate delete section",
    arguments: testDeleteSectionCases
  )
  @MainActor func testInitiateDeleteSection(section: SectionRecord, expectedEffect: Effect) {
    let model = initializeProjectViewModel(projectId: 1)
    let stateStore = initializeStore(projectsState: ProjectsState(selectedProject: model))

    let event: AppEvent = .projects(.projectEvent(projectId: 1, .markSectionForDeletion(section)))
    let resultEffect = stateStore.handleEvent(event)
    #expect(resultEffect == expectedEffect)

    let section = model.projectData.sections.first(where: { $0.section.id == section.id })
    #expect(section!.isBeingDeleted == true)
  }

  @Test("Test remove section")
  @MainActor func testRemoveSection() {
    let now = Date.now
    let sections = [
      ProjectSection(
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
    sections[0].isBeingDeleted = true
    let model = initializeProjectViewModel(sections: sections)
    let stateStore = initializeStore(projectsState: ProjectsState(selectedProject: model))

    let event: AppEvent = .projects(.projectEvent(projectId: 1, .RemoveSection(1)))
    let resultEffect = stateStore.handleEvent(event)
    #expect(resultEffect == nil)

    let section = model.projectData.sections.first(where: { $0.section.id == 1 })
    #expect(section == nil)
  }

  @Test("Test store section item")
  @MainActor func testStoreSectionItem() {
    let model = initializeProjectViewModel()
    let stateStore = initializeStore(projectsState: ProjectsState(selectedProject: model))

    let event: AppEvent = .projects(
      .projectEvent(projectId: 1, .StoreSectionItem(text: "task 1", note: nil, sectionId: 1))
    )
    let effect = stateStore.handleEvent(event)

    let expectedEffect = Effect.SaveSectionItem(
      text: "task 1",
      note: nil,
      order: 0,
      sectionId: 1,
      projectId: 1,
    )

    #expect(effect == expectedEffect)
  }

  @Test("Test add section item")
  @MainActor func testAddSectionItem() {
    let model = initializeProjectViewModel()
    let stateStore = initializeStore(projectsState: ProjectsState(selectedProject: model))

    let sectionTextRecord = SectionItemRecord(
      from: SectionItemInputRecord(id: 1, text: "hello", order: 0, sectionId: 1)
    )
    let event: AppEvent = .projects(
      .projectEvent(
        projectId: 1,
        .StoreNewSectionItem(item: SectionItem(record: sectionTextRecord), sectionId: 1)
      )
    )
    let effect = stateStore.handleEvent(event)

    #expect(effect == nil)

    let section = model.projectData.sections.first(where: { $0.section.id == 1 })!
    #expect(section.items.count == 1)
    #expect(section.items[0].record.id == 1)

  }

  @Test("Test initiate update section item text")
  @MainActor func testInitiateStoreUpdatedSectionItemText() {
    let model = initializeProjectViewModel()
    let stateStore = initializeStore(projectsState: ProjectsState(selectedProject: model))

    let updatedSectionTextRecord = SectionItemRecord(
      from: SectionItemInputRecord(id: 1, text: "new test", order: 0, sectionId: 1)
    )
    let updatedSectionItem = SectionItem(record: updatedSectionTextRecord)
    let event: AppEvent = .projects(
      .projectEvent(
        projectId: 1,
        .StoreUpdatedSectionItemText(item: updatedSectionItem, sectionId: 1)
      )
    )
    let effect = stateStore.handleEvent(event)

    let expectedEffect: Effect = .SaveSectionItemTextUpdate(
      item: updatedSectionItem,
      sectionId: 1,
      projectId: 1,
    )
    #expect(effect == expectedEffect)
  }

  @Test("Test update section item text in state")
  @MainActor func testUpdateSectionItemText() {
    let now = Date.now
    let sectionTextRecord = SectionItemRecord(
      from: SectionItemInputRecord(id: 1, text: "hello", order: 0, sectionId: 1)
    )
    let sectionItem = SectionItem(record: sectionTextRecord)
    let sections = [
      ProjectSection(
        section: SectionRecord(
          id: 1,
          projectId: 1,
          name: "Section 1",
          isDeleted: false,
          createDate: now,
          updateDate: now
        ),
        items: [
          sectionItem
        ],
      )
    ]
    let model = initializeProjectViewModel(sections: sections)
    let stateStore = initializeStore(projectsState: ProjectsState(selectedProject: model))

    let updatedSectionTextRecord = SectionItemRecord(
      from: SectionItemInputRecord(id: 1, text: "new test", order: 0, sectionId: 1)
    )
    let updatedSectionItem = SectionItem(record: updatedSectionTextRecord)
    let event: AppEvent = .projects(
      .projectEvent(projectId: 1, .UpdateSectionItemText(item: updatedSectionItem, sectionId: 1))
    )
    let effect = stateStore.handleEvent(event)

    let expectedEffect: Effect? = nil
    #expect(effect == expectedEffect)

    let section = model.projectData.sections.first(where: { $0.section.id == 1 })!
    let updatedSectionItemState = section.items[0]
    #expect(updatedSectionItemState == updatedSectionItem)
  }

  @Test("Test update and store section item record completion status")
  @MainActor func testUpdateSectionItemRecordCompletionStatus() {
    let now = Date.now
    let sectionTextRecord = SectionItemRecord(
      from: SectionItemInputRecord(id: 1, text: "hello", order: 0, sectionId: 1)
    )
    let sectionItem = SectionItem(record: sectionTextRecord)
    let sections = [
      ProjectSection(
        section: SectionRecord(
          id: 1,
          projectId: 1,
          name: "Section 1",
          isDeleted: false,
          createDate: now,
          updateDate: now
        ),
        items: [
          sectionItem
        ],
      )
    ]
    let model = initializeProjectViewModel(sections: sections)
    let stateStore = initializeStore(projectsState: ProjectsState(selectedProject: model))

    var updatedSectionTextRecord = SectionItemRecord(
      from: SectionItemInputRecord(id: 1, text: "hello", order: 0, sectionId: 1)
    )
    let event: AppEvent = .projects(
      .projectEvent(
        projectId: 1,
        .toggleSectionItemCompletionStatus(updatedSectionTextRecord, sectionId: 1)
      )
    )
    let effect = stateStore.handleEvent(event)

    updatedSectionTextRecord.isComplete.toggle()
    let expectedEffect: Effect? = Effect.SaveSectionItemUpdate(
      updatedSectionTextRecord,
      sectionId: 1,
      projectId: 1,
    )
    #expect(effect == expectedEffect)

  }

  @Test("Update section item record state")
  @MainActor func testUpdateSectionItemRecord() {
    let now = Date.now
    let sectionTextRecord = SectionItemRecord(
      from: SectionItemInputRecord(id: 1, text: "hello", order: 0, sectionId: 1)
    )
    let sectionItem = SectionItem(record: sectionTextRecord)
    let sections = [
      ProjectSection(
        section: SectionRecord(
          id: 1,
          projectId: 1,
          name: "Section 1",
          isDeleted: false,
          createDate: now,
          updateDate: now
        ),
        items: [
          sectionItem
        ],
      )
    ]
    let model = initializeProjectViewModel(sections: sections)
    let stateStore = initializeStore(projectsState: ProjectsState(selectedProject: model))

    var updatedSectionTextRecord = SectionItemRecord(
      from: SectionItemInputRecord(id: 1, text: "hello", order: 0, sectionId: 1)
    )
    updatedSectionTextRecord.isComplete.toggle()

    let event: AppEvent = .projects(
      .projectEvent(projectId: 1, .UpdateSectionItem(item: updatedSectionTextRecord, sectionId: 1))
    )
    let effect = stateStore.handleEvent(event)
    #expect(effect == nil)

    let section = model.projectData.sections.first(where: { $0.section.id == 1 })!
    let updatedSectionItemState = section.items[0]
    #expect(updatedSectionItemState.record == updatedSectionTextRecord)
  }

  @Test("toggle item selection for deletion")
  @MainActor func testToggleItemSelectionForDeletion() {
    let now = Date.now
    let sections = [
      ProjectSection(
        section: SectionRecord(
          id: 1,
          projectId: 1,
          name: "Section 1",
          isDeleted: false,
          createDate: now,
          updateDate: now
        ),
        items: [
          SectionItem(
            record: SectionItemRecord(
              from: SectionItemInputRecord(id: 1, text: "second task", order: 0, sectionId: 1)
            )
          ),
          SectionItem(
            record: SectionItemRecord(
              from: SectionItemInputRecord(id: 2, text: "second task", order: 1, sectionId: 1)
            )
          ),
        ],
      )
    ]
    let model = initializeProjectViewModel(sections: sections)
    let stateStore = initializeStore(projectsState: ProjectsState(selectedProject: model))

    let event: AppEvent = .projects(
      .projectEvent(projectId: 1, .toggleSelectedSectionItem(withId: 1, fromSectionWithId: 1))
    )
    let effect = stateStore.handleEvent(event)
    #expect(effect == nil)

    var section = model.projectData.sections.first(where: { $0.section.id == 1 })!
    var item = section.items[0]
    #expect(section.selectedItems.contains(item.record.id))
    #expect(section.selectedItems.count == 1)

    _ = stateStore.handleEvent(event)
    section = model.projectData.sections.first(where: { $0.section.id == 1 })!
    item = section.items[0]
    #expect(!section.selectedItems.contains(item.record.id))
    #expect(section.selectedItems.count == 0)
  }

  @Test("remove deleted section items")
  @MainActor func testRemoveDeletedSectionItems() {
    let now = Date.now
    let sections = [
      ProjectSection(
        section: SectionRecord(
          id: 1,
          projectId: 1,
          name: "Section 1",
          isDeleted: false,
          createDate: now,
          updateDate: now
        ),
        items: [
          SectionItem(
            record: SectionItemRecord(
              from: SectionItemInputRecord(id: 1, text: "second task", order: 0, sectionId: 1)
            )
          ),
          SectionItem(
            record: SectionItemRecord(
              from: SectionItemInputRecord(id: 2, text: "second task", order: 1, sectionId: 1)
            )
          ),
          SectionItem(
            record: SectionItemRecord(
              from: SectionItemInputRecord(id: 3, text: "third task", order: 2, sectionId: 1)
            )
          ),
        ],
      ),
      ProjectSection(
        section: SectionRecord(
          id: 2,
          projectId: 1,
          name: "Section 2",
          isDeleted: false,
          createDate: now,
          updateDate: now
        ),
        items: [
          SectionItem(
            record: SectionItemRecord(
              from: SectionItemInputRecord(
                id: 1,
                text: "second section second task",
                order: 0,
                sectionId: 2
              )
            )
          )
        ],
      ),
    ]
    let model = initializeProjectViewModel(sections: sections)
    let stateStore = initializeStore(projectsState: ProjectsState(selectedProject: model))

    let event: AppEvent = .projects(
      .projectEvent(
        projectId: 1,
        .removeDeletedSectionItems(deletedIds: Set([1, 2]), sectionId: 1)
      )
    )
    let effect = stateStore.handleEvent(event)
    #expect(effect == nil)

    let section = model.projectData.sections.first(where: { $0.section.id == 1 })!
    #expect(section.selectedItems.isEmpty)
    #expect(section.items.count == 1)
    #expect(section.items[0].record.id == 3)
    #expect(section.isEditingSection == false)
    #expect(model.projectData.sections[1].items.count == 1)
  }

  @Test("show delete images view")
  @MainActor func testShowDeleteImagesView() {
    let now = Date.now
    let imagePath = "/some/file/path"
    let images = ProjectImages(
      projectId: 1,
      images: [
        ProjectImage(
          record: ProjectImageRecord(
            from: ProjectImageRecordInput(
              id: 1,
              projectId: 1,
              filePath: imagePath,
              thumbnail: "/cache/some/file/path",
              isDeleted: false,
              createDate: now,
              updateDate: now,
            )
          ),
          path: imagePath
        )
      ]
    )
    let model = initializeProjectViewModel(images: images)
    let stateStore = initializeStore(projectsState: ProjectsState(selectedProject: model))

    let event: AppEvent = .projects(
      .projectEvent(projectId: 1, .ShowDeleteImagesView(initialSelectedImageId: 1))
    )
    let effect = stateStore.handleEvent(event)
    #expect(effect == nil)

    #expect(model.projectImages.inDeleteMode == true)
    #expect(model.projectImages.selectedImages.count == 1)
  }

  @Test("add image")
  @MainActor func testAddImage() {
    let now = Date.now
    let imagePath = "/some/file/path"
    let projectImage =
      ProjectImage(
        record: ProjectImageRecord(
          from: ProjectImageRecordInput(
            id: 1,
            projectId: 1,
            filePath: imagePath,
            thumbnail: "/cache/some/file/path",
            isDeleted: false,
            createDate: now,
            updateDate: now,
          )
        ),
        path: imagePath,
        image: UIImage(ciImage: .empty())
      )
    let model = initializeProjectViewModel()
    let stateStore = initializeStore(projectsState: ProjectsState(selectedProject: model))

    let event: AppEvent = .projects(
      .projectEvent(projectId: 1, .AddImage(projectImage: projectImage))
    )
    let effect = stateStore.handleEvent(event)
    #expect(effect == nil)

    #expect(model.projectImages.images.count == 1)
  }

  @Test("test toggle select for image deletion")
  @MainActor func testToggleSelectImageForDeletion() {
    let now = Date.now
    let imagePath = "/some/file/path"
    let otherImagePath = "/someOther/file/path"
    let images = ProjectImages(
      projectId: 1,
      images: [
        ProjectImage(
          record: ProjectImageRecord(
            from: ProjectImageRecordInput(
              id: 1,
              projectId: 1,
              filePath: imagePath,
              thumbnail: "/cache/some/file/path",
              isDeleted: false,
              createDate: now,
              updateDate: now,
            )
          ),
          path: imagePath,
          image: UIImage(ciImage: .empty())
        ),
        ProjectImage(
          record: ProjectImageRecord(
            from: ProjectImageRecordInput(
              id: 2,
              projectId: 1,
              filePath: otherImagePath,
              thumbnail: "/cache/some/file/path",
              isDeleted: false,
              createDate: now,
              updateDate: now,
            )
          ),
          path: imagePath,
          image: UIImage(ciImage: .empty())
        ),
      ]
    )
    let model = initializeProjectViewModel(images: images)
    let stateStore = initializeStore(projectsState: ProjectsState(selectedProject: model))

    let event1: AppEvent = .projects(.projectEvent(projectId: 1, .ToggleImageSelection(imageId: 1)))
    let effect = stateStore.handleEvent(event1)
    #expect(effect == nil)

    #expect(model.projectImages.selectedImages.count == 1)
    #expect(model.projectImages.selectedImages.contains(1))
    #expect(!model.projectImages.selectedImages.contains(2))

    let event2: AppEvent = .projects(.projectEvent(projectId: 1, .ToggleImageSelection(imageId: 2)))
    _ = stateStore.handleEvent(event2)
    #expect(model.projectImages.selectedImages.count == 2)
    #expect(model.projectImages.selectedImages.contains(2))
    #expect(model.projectImages.selectedImages.contains(1))

    _ = stateStore.handleEvent(event1)
    #expect(model.projectImages.selectedImages.count == 1)
    #expect(model.projectImages.selectedImages.contains(2))
    #expect(!model.projectImages.selectedImages.contains(1))
  }

  @Test("test delete selected images")
  @MainActor func testDeleteSelectedImages() {
    let now = Date.now
    let imagePath = "/some/file/path"
    let otherImagePath = "/someOther/file/path"
    let images = [
      ProjectImage(
        record: ProjectImageRecord(
          from: ProjectImageRecordInput(
            id: 1,
            projectId: 1,
            filePath: imagePath,
            thumbnail: "/cache/some/file/path",
            isDeleted: false,
            createDate: now,
            updateDate: now,
          )
        ),
        path: imagePath,
        image: UIImage(ciImage: .empty())
      ),
      ProjectImage(
        record: ProjectImageRecord(
          from: ProjectImageRecordInput(
            id: 2,
            projectId: 1,
            filePath: otherImagePath,
            thumbnail: "/cache/some/file/path",
            isDeleted: false,
            createDate: now,
            updateDate: now,
          )
        ),
        path: imagePath,
        image: UIImage(ciImage: .empty())
      ),
    ]
    let selectedImages: Set<Int64> = Set([1])
    let projectImages = ProjectImages(
      projectId: 1,
      images: images,
      selectedImages: selectedImages
    )
    let model = initializeProjectViewModel(images: projectImages)
    let stateStore = initializeStore(projectsState: ProjectsState(selectedProject: model))

    let event: AppEvent = .projects(.projectEvent(projectId: 1, .DeleteImagesFromStorage))
    let effect = stateStore.handleEvent(event)
    let selectedImage = [
      ProjectImage(
        record: ProjectImageRecord(
          from: ProjectImageRecordInput(
            id: 1,
            projectId: 1,
            filePath: imagePath,
            thumbnail: "/cache/some/file/path",
            isDeleted: false,
            createDate: now,
            updateDate: now,
          )
        ),
        path: imagePath,
        image: UIImage(ciImage: .empty())
      )
    ]
    let expectedEffect = Effect.DeleteImages(selectedImage, projectId: 1)

    #expect(effect == expectedEffect)

  }
}
