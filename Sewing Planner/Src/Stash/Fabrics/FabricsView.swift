import SwiftUI

struct FabricsView: View {
  @Environment(\.db) private var appDatabase
  @Environment(\.settings) var settings
  @Environment(Store.self) var store

  var body: some View {
    Text("Fabrics")
  }
}
