import GRDB
import SwiftUI

@Observable @MainActor
class StateStore {
  var projectsState: ProjectsState
  var stashState: StashState
  var appError: AppError?
  var appSection: AppSection = .stash
  let db: AppDatabase

  init(db: AppDatabase) {
    projectsState = ProjectsState(db: db)
    stashState = StashState(db: db)
    self.db = db
  }

}

extension StateStore {
  public func handleEvent(_ event: AppEvent) -> Effect? {
    switch event {
      case .fabrics(let event):
        return handleFabricsEvent(event: event, state: self.stashState.fabrics)
    }
  }

  func send(event: AppEvent, db: AppDatabase) {
    let effect = handleEvent(event)
    handleEffect(effect: effect, db: db)
  }

}

extension StateStore {
  nonisolated public func handleEffect(effect: Effect?, db: AppDatabase) {
    guard let effect = effect else {
      return
    }

    switch effect {
      case .StoreFabric(let fabricInput):
        Task {
          do {
            let fabricRecord = try await db.getWriter().write { [fabricInput] db in
              let savedFabric = try fabricInput.saved(db)
              return FabricRecord(from: savedFabric)
            }

            await MainActor.run {
              _ = self.handleEvent(.fabrics(.addFabricToState(fabricRecord)))
            }
          } catch {
            print(error)
            // todo: handle app error
          }
        }
      case .retrieveAllFabrics:
        Task {
          do {
            let fabrics = try await db.reader.read { db in
              let fabrics = try FabricRecord.all().fetchAll(db)
              return fabrics
            }

            await MainActor.run {
              _ = self.handleEvent(.fabrics(.addFabricsToState(fabrics)))
            }
          }
        }
      default:
        print("hi")
    }
  }
}

enum AppEvent {
  case fabrics(FabricsEvent)
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
