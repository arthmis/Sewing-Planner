//
//  ProjectView.swift
//  Sewing Planner
//
//  Created by Art on 7/9/24.
//

import GRDB
import PhotosUI
import SwiftUI

struct ProjectView: View {
  // used for dismissing a view(basically the back button)
  @Environment(\.dismiss) private var dismiss
  @Environment(\.db) private var db
  @Environment(StateStore.self) private var store
  @State var project: ProjectViewModel
  @Binding var projectsNavigation: [ProjectsNavigation]
  let fetchProjects: () -> Void

  var body: some View {
    VStack {
      Button("Images") {
        projectsNavigation.append(.projectImages(project.projectData.data.id))
      }
      ProjectDataView(projectData: $project.projectData)
    }
    .toolbar {
      ToolbarItem(placement: .navigation) {
        BackButton {
          // dismiss()
          projectsNavigation.removeAll()
          store.projectsState.selectedProject = nil
          fetchProjects()
        }
      }
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          store.send(
            event: .projects(
              .projectEvent(.AddSection(projectId: project.projectData.data.id))
            ),
            db: db
          )
        } label: {
          Image(systemName: "plus")
        }
        .buttonStyle(AddNewSectionButtonStyle())
        .accessibilityIdentifier("AddNewSectionButton")
      }
    }
    .navigationBarBackButtonHidden()
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

struct BackButton: View {
  let buttonAction: () -> Void
  var body: some View {
    Button(action: buttonAction) {
      Image(systemName: "chevron.left")
    }
  }
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

enum CurrentView {
  case details
  case images
}
