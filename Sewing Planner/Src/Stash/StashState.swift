import SwiftUI

@Observable
class StashState {
  var fabrics: FabricsState

  init() {
    fabrics = FabricsState()
  }
}
