//
//  ProjectDisplayViewModel.swift
//  Sewing Planner
//
//  Created by Art on 10/30/24.
//

import SwiftUI

struct ProjectCardViewModel {
  var project: ProjectMetadata
  var image: ProjectDisplayImage?
  var error = false
}

class ProjectDisplayImage {
  var record: ProjectImageRecord
  var path: String
  var image: UIImage?

  init(record: ProjectImageRecord, path: String, image: UIImage?) {
    self.record = record
    self.image = image
    self.path = path
  }
}

class ProjectsViewModel {
  var projectsDisplay: [ProjectCardViewModel] = []

  init(projects: [ProjectCardViewModel]) {
    projectsDisplay = projects
  }

  init() {}
}
