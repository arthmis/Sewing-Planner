import SwiftUI

struct StashView: View {
  @Environment(\.db) private var appDatabase
  @Environment(\.settings) var settings
  @Environment(StateStore.self) var store

  var body: some View {
    FabricsView()
      .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
      .environment(\.db, appDatabase)
      .environment(store)
  }
}
