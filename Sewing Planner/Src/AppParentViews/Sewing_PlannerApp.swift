//
//  Sewing_PlannerApp.swift
//  Sewing Planner
//
//  Created by Art on 5/9/24.
//

import GRDB
import PhotosUI
import SwiftUI
import Synchronization

@main
struct Sewing_PlannerApp: App {
  @Environment(\.db) var db
  @Environment(\.settings) var settings

  // runs before app launch
  // register initial UserDefaults values every launch
  init() {
    // Initialization if needed
  }

  var body: some Scene {
    WindowGroup {
      ContentView(store: StateStore())
    }
  }
}

extension EnvironmentValues {
  @Entry var db = AppDatabase.db
  @Entry var appLogger = AppLogger(label: "app logger")
  @Entry var settings = UserSettings(
    settingsDirectory: "App Settings",
    logger: AppLogger(label: "app_logger")
  )
}
