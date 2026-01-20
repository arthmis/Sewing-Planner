import GRDB
import SwiftUI

@Observable
class Store {
  var projectsState: ProjectsState
  var stashState: StashState
  var appError: AppError?
  var appSection: AppSection = .projects
  let db: AppDatabase

  init(db: AppDatabase) {
    projectsState = ProjectsState(db: db)
    stashState = StashState(db: db)
    self.db = db
  }

}

enum AppError: Error {
  case projectCards
  case loadProject
  case addProject
  case unexpectedError
}

enum AppSection {
  case projects
  case stash
  case shoppingList
}
