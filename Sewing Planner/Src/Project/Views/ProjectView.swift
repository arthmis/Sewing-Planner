//
//  ProjectView.swift
//  Sewing Planner
//
//  Created by Art on 7/9/24.
//

import GRDB
import PhotosUI
import SwiftUI

enum CurrentView {
  case details
  case images
}

struct LoadProjectView: View {
  // used for dismissing a view(basically the back button)
  @Environment(\.dismiss) private var dismiss
  @Environment(\.db) private var appDatabase
  @Environment(Store.self) private var store
  @Binding var projectsNavigation: [ProjectMetadata]
  let fetchProjects: () -> Void
  // @State var isLoading = true

  var body: some View {
    VStack {
      if let project = store.selectedProject {
        ProjectView(
          project: project,
          projectsNavigation: $projectsNavigation,
          fetchProjects: fetchProjects
        )
      } else {
        ProgressView()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    // clicking anywhere will remove focus from whatever may have focus
    // mostly using this to remove focus from textfields when you click outside of them
    // using a frame using all the available space to make it more effective
    //        .onTapGesture {
    //            NSApplication.shared.keyWindow?.makeFirstResponder(nil)
    //        }
    .onAppear {
      if let id = projectsNavigation.last?.id {
        do {
          let maybeProjectData = try ProjectData.getProject(
            with: id,
            from: appDatabase
          )
          if let projectData = maybeProjectData {

            let projectImages = try ProjectImages.getImages(with: id, from: appDatabase)

            store.selectedProject = ProjectViewModel(
              data: projectData,
              projectsNavigation: projectsNavigation,
              projectImages: projectImages
            )
          } else {
            dismiss()
            store.appError = .loadProject
            // TODO: show an error
          }
        } catch {
          dismiss()
          store.appError = .loadProject
          // TODO: show an error
        }
      } else {
        dismiss()
        store.appError = .loadProject
        // navigate back to main view and show an error
        // this basically shouldn't happen because there must be a project in projects navigation at this point, which means
        // there is an id
      }
    }
  }
}

struct ProjectView: View {
  // used for dismissing a view(basically the back button)
  @Environment(\.dismiss) private var dismiss
  @Environment(\.db) private var db
  @Environment(Store.self) private var store
  @State var project: ProjectViewModel
  @Binding var projectsNavigation: [ProjectMetadata]
  let fetchProjects: () -> Void

  var body: some View {
    VStack {
      TabView(selection: $project.currentView) {
        Tab(
          "Details",
          systemImage: "list.bullet.rectangle.portrait",
          value: .details
        ) {
          ProjectDataView()
        }
        Tab("Images", systemImage: "photo.artframe", value: .images) {
          ImagesView(model: $project.projectImages)
        }
      }
      .navigationBarBackButtonHidden(true)
      .toolbar {
        ToolbarItem(placement: .navigation) {
          BackButton {
            dismiss()
            store.selectedProject = nil
            fetchProjects()
          }
        }
      }.toolbar {
        ToolbarItem(placement: .primaryAction) {
          if project.currentView == CurrentView.details {
            Button {
              project.addSection(db: db)
            } label: {
              Image(systemName: "plus")
            }
            .buttonStyle(AddNewSectionButtonStyle())
            .accessibilityIdentifier("AddNewSectionButton")
          } else if project.currentView == CurrentView.images {
            Button {
              project.showPhotoPickerView()
            } label: {
              Image(systemName: "photo.badge.plus")
            }
            .buttonStyle(AddImageButtonStyle())
            .photosPicker(
              isPresented: $project.showPhotoPicker,
              selection: $project.pickerItem,
              matching: .images
            )
            .onChange(of: project.pickerItem) {
              Task { @MainActor in
                await project.handleOnChangePickerItem(db: db)
              }
            }
          }
        }
      }
    }
    .overlay(alignment: .top) {
      Toast(showToast: $project.projectError)
        .padding(.horizontal, 16)
        .transition(.move(edge: .top))
        .animation(
          .easeOut(duration: 0.15),
          value: project.projectError
        )
    }
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .environment(project)
    // clicking anywhere will remove focus from whatever may have focus
    // mostly using this to remove focus from textfields when you click outside of them
    // using a frame using all the available space to make it more effective
    //        .onTapGesture {
    //            NSApplication.shared.keyWindow?.makeFirstResponder(nil)
    //        }
  }
}

enum ProjectError: Error, Equatable {
  case addSection
  case addSectionItem
  case updateSectionItemText
  case updateSectionItemCompletion
  case importImage
  case deleteSection(SectionRecord)
  case deleteSectionItems
  case reOrderSectionItems
  case renameProject
  case renameSectionName(sectionId: Int64, originalName: String)
  case deleteImages
  case loadImages
  case genericError
}

struct ErrorToast: Equatable {
  var show: Bool
  let message: String

  init(
    show: Bool = false,
    message: String = "Something went wrong. Please try again"
  ) {
    self.show = show
    self.message = message
  }
}

@Observable @MainActor
final class ProjectViewModel {
  var projectData: ProjectData
  var projectsNavigation: [ProjectMetadata]
  var projectImages: ProjectImages
  var deletedImages: [ProjectImage] = []
  var currentView = CurrentView.details
  var name = ""
  var showAddTextboxPopup = false
  var doesProjectHaveName = false
  var pickerItem: PhotosPickerItem?
  private var photosAppSelectedImage: Data?
  var showPhotoPicker = false
  var projectError: ProjectError?

  init(
    data: ProjectData,
    projectsNavigation: [ProjectMetadata],
    projectImages: ProjectImages
  ) {
    projectData = data
    self.projectsNavigation = projectsNavigation
    self.projectImages = projectImages
  }

  func addSection(db: AppDatabase) {
    do {
      try projectData.addSection(db: db)
    } catch {
      projectError = .addSection
    }
  }

  func showDeleteSectionConfirmationDialog(section: SectionRecord) {
    projectData.selectedSectionForDeletion = section
    projectData.showDeleteSectionDialog = true
  }

  func handleError(error: ProjectError) {
    projectError = error
  }

  func showPhotoPickerView() {
    showPhotoPicker = true
  }

  @MainActor func handleOnChangePickerItem(db: AppDatabase) async {
    do {
      try await handleOnChangePickerItemInner(db: db)
    } catch {
      projectError = .importImage
    }
  }

  @MainActor private func handleOnChangePickerItemInner(db: AppDatabase) async throws {
    let result = try await pickerItem?.loadTransferable(type: Data.self)

    switch result {
      case .some(let files):
        // fix this unwrap by throwing an error, display to user
        guard let img = UIImage(data: files) else {
          throw ProjectError.importImage
        }
        // TODO: Performance problem here, scale the images in a background task
        let resizedImage = img.scaleToAppImageMaxDimension()
        let projectImage = ProjectImageInput(image: resizedImage)
        try projectImages.importImages([projectImage], db: db)
      case .none:
        // TODO: think about how to deal with path that couldn't become an image
        // I'm thinking display an error alert that lists every image that couldn't be uploaded
        projectError = .importImage
    // errorToast = ErrorToast(show: true, message: "Error importing images. Please try again later")
    // log error
    }
  }
}

enum ProjectEvent {
  case UpdatedProjectTitle(String)
  case UpdateSectionName(section: SectionRecord, oldName: String)
  case markSectionForDeletion(SectionRecord)
  case RemoveSection(Int64)
  case StoreSectionItem(text: String, note: String?, sectionId: Int64)
  case StoreUpdatedSectionItemText(item: SectionItem, sectionId: Int64)
  case UpdateSectionItemText(item: SectionItem, sectionId: Int64)
  case toggleSectionItemCompletionStatus(SectionItemRecord, sectionId: Int64)
  case UpdateSectionItem(item: SectionItemRecord, sectionId: Int64)
  case toggleSelectedSectionItem(withId: Int64, fromSectionWithId: Int64)
  case deleteSelectedTasks(selected: Set<Int64>, sectionId: Int64)
  case removeDeletedSectionItems(deletedIds: Set<Int64>, sectionId: Int64)
  case AddSectionItem(item: SectionItem, sectionId: Int64)
  case ProjectError(ProjectError)
}

extension ProjectViewModel {
  public func handleEvent(_ event: ProjectEvent) -> Effect? {
    switch event {
      case .UpdatedProjectTitle(let newTitle):
        projectData.data.name = newTitle
        return Effect.updateProjectTitle(projectData: projectData.data)

      case .UpdateSectionName(let section, let oldName):
        if let index = self.projectData.sections.firstIndex(where: { $0.section.id == section.id })
        {
          self.projectData.sections[index].section.name = section.name
        }
        return .updateSectionName(section: section, oldName: oldName)

      case .markSectionForDeletion(let section):
        if let index = self.projectData.sections.firstIndex(where: { $0.section.id == section.id })
        {
          self.projectData.sections[index].isBeingDeleted = true
        }
        return .deleteSection(section: section)

      case .RemoveSection(let sectionId):
        self.projectData.sections.removeAll(where: {
          $0.section.id == sectionId && $0.isBeingDeleted
        })
        self.projectData.cancelDeleteSection()

      case .ProjectError(let error):
        switch error {
          case .addSection:
            break
          case .addSectionItem:
            break
          case .deleteImages:
            break
          case .deleteSection(let section):
            if let index = self.projectData.sections.firstIndex(where: {
              $0.section.id == section.id
            }) {
              self.projectData.sections[index].isBeingDeleted = false
            }
            self.projectData.cancelDeleteSection()
            self.handleError(error: error)

          case .deleteSectionItems:
            break
          case .genericError:
            break
          case .importImage:
            break
          case .loadImages:
            break
          case .reOrderSectionItems:
            break
          case .renameProject:
            break
          case .renameSectionName(let sectionId, let originalName):
            if let index = self.projectData.sections.firstIndex(where: {
              $0.section.id == sectionId
            }) {
              self.projectData.sections[index].section.name = originalName
            }
            self.handleError(error: error)
          case .updateSectionItemCompletion:
            break
          case .updateSectionItemText:
            break
        }

      case .StoreSectionItem(let text, let note, let sectionId):
        guard
          let index = self.projectData.sections.firstIndex(where: { section in
            section.section.id == sectionId
          })
        else {
          // TODO log an error here because this shouldn't be possible
          return nil
        }
        let order = self.projectData.sections[index].items.count
        return .SaveSectionItem(
          text: text.trimmingCharacters(in: .whitespacesAndNewlines),
          note: note,
          order: Int64(order),
          sectionId: sectionId
        )

      case .AddSectionItem(let item, let sectionId):
        guard
          let index = self.projectData.sections.firstIndex(where: { section in
            section.section.id == sectionId
          })
        else {
          // TODO log an error here because this shouldn't be possible
          return nil
        }
        self.projectData.sections[index].items.append(item)
        return nil

      case .StoreUpdatedSectionItemText(item: let sectionItem, let sectionId):
        return .SaveSectionItemTextUpdate(item: sectionItem, sectionId: sectionId)

      case .UpdateSectionItemText(let updatedItem, let sectionId):
        guard
          let index = self.projectData.sections.firstIndex(where: { section in
            section.section.id == sectionId
          })
        else {
          // TODO log an error here because this shouldn't be possible
          // or even panic
          return nil
        }

        guard
          let itemIndex = self.projectData.sections[index].items.firstIndex(where: {
            $0.record.id == updatedItem.record.id
          })
        else {
          // TODO log error or panic shouldn't be possible at this point
          return nil
        }

        self.projectData.sections[index].items[itemIndex] = updatedItem
        return nil

      case .toggleSectionItemCompletionStatus(var updatedItem, let sectionId):
        updatedItem.isComplete.toggle()
        return .SaveSectionItemUpdate(updatedItem, sectionId: sectionId)
      case .UpdateSectionItem(let updatedItem, let sectionId):
        guard
          let index = self.projectData.sections.firstIndex(where: { section in
            section.section.id == sectionId
          })
        else {
          // TODO log an error here because this shouldn't be possible
          // or even panic
          return nil
        }

        guard
          let itemIndex = self.projectData.sections[index].items.firstIndex(where: {
            $0.record.id == updatedItem.id
          })
        else {
          // TODO log error or panic shouldn't be possible at this point
          return nil
        }

        self.projectData.sections[index].items[itemIndex].record = updatedItem
        return nil

      case .toggleSelectedSectionItem(let itemId, let sectionId):
        guard
          let sectionIndex = self.projectData.sections.firstIndex(where: { section in
            section.section.id == sectionId
          })
        else {
          // TODO log an error here because this shouldn't be possible
          // or even panic
          return nil
        }

        if self.projectData.sections[sectionIndex].selectedItems.contains(itemId) {
          self.projectData.sections[sectionIndex].selectedItems.remove(itemId)
        } else {
          self.projectData.sections[sectionIndex].selectedItems.insert(itemId)
        }

        return nil

      case .deleteSelectedTasks(let selectedIds, let sectionId):
        guard
          let sectionIndex = self.projectData.sections.firstIndex(where: { section in
            section.section.id == sectionId
          })
        else {
          // TODO log an error here because this shouldn't be possible
          // or even panic
          return nil
        }
        var selected: [SectionItem] = []
        for item in self.projectData.sections[sectionIndex].items {
          if selectedIds.contains(item.record.id) {
            selected.append(item)
          }
        }
        return .deleteSectionItems(selected: selected, sectionId: sectionId)

      case .removeDeletedSectionItems(let deletedIds, let sectionId):
        guard
          let sectionIndex = self.projectData.sections.firstIndex(where: { section in
            section.section.id == sectionId
          })
        else {
          // TODO log an error here because this shouldn't be possible
          // or even panic
          return nil
        }
        let updatedItems = self.projectData.sections[sectionIndex].items.filter({
          !deletedIds.contains($0.record.id)
        })
        withAnimation(.easeOut(duration: 0.12)) {
          self.projectData.sections[sectionIndex].items = updatedItems
          self.projectData.sections[sectionIndex].isEditingSection = false
          self.projectData.sections[sectionIndex].selectedItems.removeAll()
        }

        return nil
    }

    return nil
  }

  func send(event: ProjectEvent, db: AppDatabase) {
    let effect = handleEvent(event)
    handleEffect(effect: effect, db: db)
  }

  nonisolated public func handleEffect(effect: Effect?, db: AppDatabase) {
    guard let effect = effect else {
      return
    }

    switch effect {
      case .deleteSection(let section):
        Task {
          do {
            try await db.deleteProjectSection(section: section)
            await MainActor.run {
              _ = self.handleEvent(.RemoveSection(section.id))
            }
          } catch {
            await MainActor.run {
              _ = self.handleEvent(.ProjectError(.deleteSection(section)))
            }
          }
        }
        return

      case .updateProjectTitle(let projectData):
        Task {
          do {
            try await db.updateProjectTitle(projectData: projectData)
            try self.updateProjectNameInSharedExtensionProjectList(project: projectData)
          } catch {
            await MainActor.run {
              self.handleError(error: .renameProject)
            }
          }
        }
        return

      case .updateSectionName(let section, let oldName):
        Task {
          do {
            try await db.updateSectionName(sectionId: section.id, newName: section.name)
          } catch {
            await MainActor.run {
              _ = self.handleEvent(
                .ProjectError(.renameSectionName(sectionId: section.id, originalName: oldName))
              )
            }
          }
        }
        return

      case .doNothing:
        return
      case .SaveSectionItem(let text, let note, let order, let sectionId):
        Task {
          do {
            let sectionItem: SectionItem = try await db.getWriter().write { db in
              var recordInput = SectionItemInputRecord(
                text: text,
                order: order,
                sectionId: sectionId
              )
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
                return sectionItem
              } else {
                let sectionItem = SectionItem(record: record, note: nil)
                return sectionItem
              }
            }

            await MainActor.run {
              _ = self.handleEvent(
                .AddSectionItem(item: sectionItem, sectionId: sectionId)
              )
            }
          } catch {
            await MainActor.run {
              _ = self.handleEvent(.ProjectError(.addSectionItem))
            }
          }
        }
        return

      case .SaveSectionItemTextUpdate(let item, let sectionId):
        Task {
          do {
            try await db.getWriter().write { db in
              try item.record.update(db)
              try item.note?.update(db)
            }

            await MainActor.run {
              _ = self.handleEvent(.UpdateSectionItemText(item: item, sectionId: sectionId))
            }
          } catch {
            await MainActor.run {
              _ = self.handleEvent(.ProjectError(.updateSectionItemText))
            }
          }
        }

      case .SaveSectionItemUpdate(let updatedItem, let sectionId):
        Task {
          do {
            try await db.getWriter().write { db in
              try updatedItem.update(db)
            }

            await MainActor.run {
              _ = self.handleEvent(.UpdateSectionItem(item: updatedItem, sectionId: sectionId))
            }
          } catch {
            await MainActor.run {
              // TODO: give this its own error type, also used in case above this
              _ = self.handleEvent(.ProjectError(.updateSectionItemText))
            }
          }
        }

      case .deleteSectionItems(let selected, let sectionId):
        Task {
          do {
            let deletedIds = try await db.getWriter().write { db in
              var deletedIds: Set<Int64> = Set()
              for item in selected {
                try item.record.delete(db)
                deletedIds.insert(item.record.id)
              }
              return deletedIds
            }

            await MainActor.run {
              _ = self.handleEvent(
                .removeDeletedSectionItems(deletedIds: deletedIds, sectionId: sectionId)
              )
            }
          } catch {
            await MainActor.run {
              _ = self.handleEvent(.ProjectError(.deleteSectionItems))
            }
          }
        }
    }
  }

  private func removeSection(section: SectionRecord) {
    let updatedSections = projectData.sections.filter {
      projectSection in
      section.id != projectSection.section.id
    }
    projectData.sections = updatedSections
    projectData.cancelDeleteSection()
  }

  private func cancelSectionDeletion(withError error: ProjectError) {
    projectError = error
    projectData.cancelDeleteSection()
  }

  nonisolated private func updateProjectNameInSharedExtensionProjectList(project: ProjectMetadata)
    throws
  {
    let fileData = try SharedPersistence().getFile(fileName: "projects")
    guard let data = fileData else {
      // TODO: figure out what I want to do here if no file is found
      // let projectsList = [Project(id: project.id, name: project.name)]
      // let encoder = JSONEncoder()
      // let updatedProjectsList = try encoder.encode(projectsList)
      // try SharedPersistence().writeFile(data: updatedProjectsList, fileName: "projects")

      return
    }

    let decoder = JSONDecoder()
    guard var projectsList = try? decoder.decode([SharedProject].self, from: data) else {
      throw ShareError.emptyFile("Couldn't get shared projects list file")
    }

    guard let index = projectsList.firstIndex(where: { $0.id == project.id })
    else {
      return
    }

    let updatedProject = SharedProject(id: project.id, name: project.name)
    projectsList[index] = updatedProject

    let encoder = JSONEncoder()
    let updatedProjectsList = try encoder.encode(projectsList)
    try SharedPersistence().writeFile(data: updatedProjectsList, fileName: "projects")
  }
}

enum Effect: Equatable {
  case deleteSection(section: SectionRecord)
  case updateProjectTitle(projectData: ProjectMetadata)
  case updateSectionName(section: SectionRecord, oldName: String)
  case SaveSectionItem(text: String, note: String?, order: Int64, sectionId: Int64)
  case SaveSectionItemTextUpdate(item: SectionItem, sectionId: Int64)
  case SaveSectionItemUpdate(SectionItemRecord, sectionId: Int64)
  case deleteSectionItems(selected: [SectionItem], sectionId: Int64)
  case doNothing
}

struct BackButton: View {
  let buttonAction: () -> Void
  var body: some View {
    Button(action: buttonAction) {
      Image(systemName: "chevron.left")
    }
  }
}
