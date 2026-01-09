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
              project.send(event: .AddSection(projectId: project.projectData.data.id), db: db)
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
              project.send(event: .HandleImagePicker(photoPicker: project.pickerItem), db: db)
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

struct BackButton: View {
  let buttonAction: () -> Void
  var body: some View {
    Button(action: buttonAction) {
      Image(systemName: "chevron.left")
    }
  }
}
