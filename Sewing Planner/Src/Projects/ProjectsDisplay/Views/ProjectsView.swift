//
//  ProjectsView.swift
//  Sewing Planner
//
//  Created by Art on 7/9/24.
//

import SwiftUI

// enum Navigation {
//    case allProjects
//    case Project(ProjectViewModel)
// }

let UserCreatedOneProject: String = "CreatedOneProject"

struct ProjectsView: View {
  @Environment(\.db) private var appDatabase
  @Environment(\.settings) var settings
  @Environment(StateStore.self) var store

  func fetchProjects() {
    do {
      let projects = try appDatabase.fetchProjectsAndProjectImage()

      let projectCards = projects.map { projectCard in
        if let imageRecord = projectCard.image {
          var hadError = false
          var projectImage: ProjectDisplayImage
          do {
            let image = try AppFiles().getThumbnailImage(
              for: imageRecord.thumbnail,
              fromProject: projectCard.project.id
            )
            projectImage = ProjectDisplayImage(
              record: imageRecord,
              path: imageRecord.filePath,
              image: image
            )
          } catch {
            hadError = true
            projectImage = ProjectDisplayImage(
              record: imageRecord,
              path: imageRecord.filePath,
              image: nil
            )
          }
          return ProjectCardViewModel(
            project: projectCard.project,
            image: projectImage,
            error: hadError
          )
        } else {
          return ProjectCardViewModel(project: projectCard.project, error: false)

        }
      }
      // store.projects = ProjectsViewModel(projects: projectCards)
      store.projectsState.projects = ProjectsViewModel(projects: projectCards)
    } catch {
      store.appError = AppError.projectCards
    }
  }

  var body: some View {
    @Bindable var storeBinding = store
    if case .some(let error) = store.appError {
      // TODO: do this error handling for how to display the toast message
      // add a transition to the toast to come from the top
      switch error {
        case .projectCards:
          Text(
            "Couldn't load projects. Tap button to try reloading again."
          )
          Button("Load Projects") {
            fetchProjects()
            store.appError = nil
          }
        case .loadProject:
          Text("Couldn't load project. Try again.")
        case .addProject:
          Text("Couldn't add project. Try again.")
        case .unexpectedError:
          Text("Something unexpected happen. Contact developer about this.")
      }
    } else {
      NavigationStack(path: $storeBinding.projectsState.navigation) {
        VStack {
          if !(settings.getUserCreatedProjectFirstTime() ?? false) {
            CreateProjectCTAView()
              .padding(.horizontal, 12)
          } else {
            ScrollView {
              LazyVStack(alignment: .center, spacing: 12) {
                ForEach(
                  $storeBinding.projectsState.projects.projectsDisplay,
                  id: \.self.project.id
                ) { $project in
                  ProjectCardView(
                    projectData: project,
                    projectsNavigation: $storeBinding.projectsState.navigation
                  )
                }
              }
              .padding(.bottom, 12)
            }
          }
        }
        .navigationDestination(for: ProjectMetadata.self) { _ in
          VStack {
            LoadProjectView(
              projectsNavigation: $storeBinding.projectsState.navigation,
              fetchProjects: fetchProjects
            )
          }
        }

        HStack {
          Button("New Project") {
            do {
              store.send(event: .projects(.createProject), db: appDatabase)
              // todo move this into the effects handling
              if !(settings.getUserCreatedProjectFirstTime() ?? false) {
                do {
                  try settings.userCreatedProjectFirstTime(val: true)
                } catch {
                  // TODO: log error
                  print(error)
                }
              }
            } catch AppError.addProject {
              store.appError = .addProject
            } catch {
              store.appError = .unexpectedError
              print(error)
            }
          }
          .buttonStyle(PrimaryButtonStyle())
          .padding(.bottom, 12)
          .accessibilityIdentifier("AddNewProjectButton")
        }
      }
      .navigationTitle("Projects")
      .frame(
        minWidth: 0,
        maxWidth: .infinity,
        minHeight: 0,
        maxHeight: .infinity
      )
      .background(Color.white)
      .task {
        fetchProjects()
      }
    }
  }
}

// #Preview {
//   let db = AppDatabase.db
//   ProjectsView(store: Store(db: db))
// }
