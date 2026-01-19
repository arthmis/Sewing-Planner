//
//  ContentView.swift
//  Sewing Planner
//
//  Created by Art on 5/9/24.
//

import SwiftUI

struct ContentView: View {
  @Environment(\.db) var db
  @State var store: Store

  var body: some View {

    TabView(selection: $store.appSection) {
      Tab(
        "Projects",
        systemImage: "list.bullet.rectangle.portrait",
        value: .projects
      ) {
        ProjectsView()
          .environment(\.font, Font.custom("SourceSans3-Regular", size: 16))
          .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
          .environment(\.db, db)
          .environment(store)
      }
      Tab("Stash", systemImage: "photo.artframe", value: .stash) {
        Text("Fabric")
      }
    }
  }
}

// #Preview {
//   ContentView()
// }
