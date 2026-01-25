//
//  ProjectDetailsView.swift
//  Sewing Planner
//
//  Created by Art on 9/12/24.
//

import SwiftUI

struct ProjectDataView: View {
  @Environment(StateStore.self) var store
  @Environment(\.db) var db
  @Binding var projectData: ProjectData

  var body: some View {
    VStack(alignment: .leading) {
      if projectData.sections.isEmpty {
        EmptyProjectCallToActionView()
        Spacer()
      } else {
        ScrollView {
          VStack(alignment: .leading) {
            HStack {
              ProjectTitle(
                projectData: projectData.data,
                bindedName: projectData.bindedName,
              )
              Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 25)
            ForEach($projectData.sections, id: \.section.id) {
              $section in
              SectionView(model: $section, db: db)
                .padding(.bottom, 16)
            }
          }
        }
        .frame(maxHeight: .infinity)
      }
    }
    .confirmationDialog(
      "Delete Section",
      isPresented: $projectData.showDeleteSectionDialog
    ) {
      Button("Delete", role: .destructive) {
        if let sectionToDelete = projectData.selectedSectionForDeletion {
          store.send(
            event: .projects(
              .projectEvent(
                projectId: projectData.data.id,
                .markSectionForDeletion(sectionToDelete)
              )
            ),
            db: db
          )
        }
      }
      Button("Cancel", role: .cancel) {
        projectData.cancelDeleteSection()
      }
    } message: {
      if let section = projectData.selectedSectionForDeletion {
        Text("Delete \(section.name)")
      }
    }
  }
}

// #Preview {
//   @State static var viewModel = ProjectViewModel(
//     data: ProjectData(
//       data: ProjectMetadata(
//         id: 1,
//         name: "Project Name",
//         completed: false,
//         createDate: Date(),
//         updateDate: Date()
//       )
//     ),
//     projectsNavigation: [],
//     projectImages: ProjectImages(projectId: 1)
//   )
//   ProjectDataView(projectData: viewModel.projectData)
//     .environment(viewModel)

// }
