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
    ScrollView {
      VStack {
        HStack {
          ProjectTitle(
            projectData: project.projectData.data,
            bindedName: project.projectData.bindedName,
          )
          Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 8)

        ProjectImagesCard
          .padding(.bottom, 8)

        ProjectTasksView(projectData: $project.projectData)
      }
      .padding([.horizontal], 8)
    }
    .frame(maxHeight: .infinity)
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

  var ProjectImagesCard: some View {
    VStack(alignment: .leading, spacing: 0) {
      Group {
        if let previews = project.projectImagePreviews {
          Image(uiImage: previews.mainImage.image!)
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fill)
            .fill()
            .clipped()
            .contentShape(Rectangle())
            .overlay(alignment: .topTrailing) {
              Button {
                projectsNavigation.append(.projectImages(project.projectData.data.id))
              } label: {
                HStack(alignment: .center) {
                  Text("VIEW IMAGES")
                    .font(.system(size: 12, weight: .semibold))
                  Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                }
              }
              .buttonStyle(SecondaryButtonStyle())
              .padding([.top, .trailing], 12)
            }
        } else {
          Image(systemName: "photo.on.rectangle.angled")
            .font(.system(size: 60))
            .foregroundStyle(.black.opacity(0.7))
            .fill()
            .padding(.top, 8)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      .layoutPriority(1)
      .onTapGesture {
        // todo instead of navigating maybe display the preview image, think about it
        projectsNavigation.append(.projectImages(project.projectData.data.id))
      }
      .background(
        RoundedRectangle(cornerRadius: 0)
          .stroke(.gray.opacity(0.1), lineWidth: 1)
          .fill(.gray.opacity(0.1))
      )

      HStack(alignment: .top, spacing: 0) {
        VStack(alignment: .leading, spacing: 0) {
          Text("Inspiration")
            .font(.system(size: 18, weight: .semibold))
          Text(
            "Import photos as references and inspiration."
          )
          .fixedSize(horizontal: false, vertical: true)
          .frame(maxWidth: .infinity, alignment: .leading)
          .font(.system(size: 15))
          .padding(.top, 8)
        }

        Button {
          project.showPhotoPickerView()
        } label: {
          Label("Add", systemImage: "photo.badge.plus")
        }
        .buttonStyle(SecondaryButtonStyle())
        .frame(maxHeight: .infinity, alignment: .center)
        .photosPicker(
          isPresented: $project.showPhotoPicker,
          selection: $project.pickerItem,
          matching: .images
        )
        .onChange(of: project.pickerItem) {
          store.send(
            event: .projects(
              .projectEvent(
                projectId: project.projectData.data.id,
                .HandleImagePicker(photoPicker: project.pickerItem)
              )
            ),
            db: db
          )
          projectsNavigation.append(.projectImages(project.projectData.data.id))
        }
      }
      .padding(.top, 8)

    }
    .padding(8)
    .frame(maxWidth: .infinity, minHeight: 250, maxHeight: 250)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .stroke(.gray, lineWidth: 1)
        .fill(.white)
        .shadow(color: Color.gray.opacity(0.2), radius: 2, y: 5)
    )
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
