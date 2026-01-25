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

  var ProjectImagesCard: some View {
    VStack(alignment: .leading, spacing: 0) {

      VStack {
        if project.projectImages.images.isEmpty {
          Image(systemName: "photo.on.rectangle.angled")
            .font(.system(size: 60))
            .foregroundStyle(.black.opacity(0.7))
            .padding(.top, 8)
        } else {
          Image(systemName: "photo")
            .font(.system(size: 60))
        }
        Spacer()
      }
      .frame(maxWidth: .infinity, alignment: .center)
      .onTapGesture {
        projectsNavigation.append(.projectImages(project.projectData.data.id))
      }
      .background(
        RoundedRectangle(cornerRadius: 0)
          .stroke(.gray.opacity(0.1), lineWidth: 1)
          .fill(.gray.opacity(0.1))
      )

      Text("Inspiration")
        .font(.system(size: 18, weight: .semibold))
        .padding(.top, 8)

      HStack {
        VStack {
          Text(
            "Import photos as references and inspiration."
          )
          .frame(maxWidth: .infinity, alignment: .leading)
          .font(.system(size: 15))
          .padding(.top, 8)
        }

        Button {
          project.showPhotoPickerView()
          projectsNavigation.append(.projectImages(project.projectData.data.id))
        } label: {
          Label("Add", systemImage: "photo.badge.plus")
        }
        .buttonStyle(SecondaryButtonStyle())
      }

    }
    .padding(8)
    .frame(maxWidth: .infinity, maxHeight: 200)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .stroke(.gray, lineWidth: 1)
        .fill(.white)
        .shadow(color: Color.gray.opacity(0.2), radius: 2, y: 5)
    )
  }

  var body: some View {
    VStack {
      ProjectImagesCard
      ProjectDataView(projectData: $project.projectData)
    }
    .padding([.horizontal], 8)
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
              .projectEvent(
                projectId: project.projectData.data.id,
                .StoreNewSection(projectId: project.projectData.data.id)
              )
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
