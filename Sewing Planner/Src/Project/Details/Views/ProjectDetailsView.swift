//
//  ProjectDetailsView.swift
//  Sewing Planner
//
//  Created by Art on 9/12/24.
//

import SwiftUI

struct ProjectDataView: View {
  @Environment(ProjectViewModel.self) var project
  @Environment(\.db) var db

  var body: some View {
    @Bindable var projectBinding = project
    VStack(alignment: .leading) {
      if project.projectData.sections.isEmpty {
        EmptyProjectCallToActionView()
        Spacer()
      } else {
        ScrollView {
          VStack(alignment: .leading) {
            HStack {
              ProjectTitle(
                projectData: projectBinding.projectData.data,
                bindedName: projectBinding.projectData.bindedName,
              )
              Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 25)
            ForEach($projectBinding.projectData.sections, id: \.section.id) {
              $section in
              SectionView(model: $section, db: db)
                .padding(.bottom, 16)
            }
          }
        }
        .frame(maxHeight: .infinity)
      }
    }
    .padding([.leading, .trailing], 8)
    .confirmationDialog(
      "Delete Section",
      isPresented: $projectBinding.projectData.showDeleteSectionDialog
    ) {
      Button("Delete", role: .destructive) {
        if let sectionToDelete = project.projectData.selectedSectionForDeletion {
          project.send(event: .markSectionForDeletion(sectionToDelete), db: db)
        }
      }
      Button("Cancel", role: .cancel) {
        project.projectData.cancelDeleteSection()
      }
    } message: {
      if let section = project.projectData.selectedSectionForDeletion {
        Text("Delete \(section.name)")
      }
    }
  }
}

#Preview {
  let viewModel = ProjectViewModel(
    data: ProjectData(
      data: ProjectMetadata(
        id: 1,
        name: "Project Name",
        completed: false,
        createDate: Date(),
        updateDate: Date()
      )
    ),
    projectsNavigation: [],
    projectImages: ProjectImages(projectId: 1)
  )
  ProjectDataView()
    .environment(viewModel)

}
