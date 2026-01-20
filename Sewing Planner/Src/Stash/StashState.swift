import SwiftUI

@Observable
class StashState {
  var fabrics: FabricsState
  let db: AppDatabase

  init(db: AppDatabase) {
    fabrics = FabricsState()
    self.db = db
  }
}
