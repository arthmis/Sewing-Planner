//
//  AppDatabase.swift
//  Sewing Planner
//
//  Created by Art on 7/18/24.
//

import Foundation
import GRDB

/// docs on implementing this struct https://github.com/groue/GRDB.swift/blob/master/Documentation/DemoApps/GRDBDemoiOS/GRDBDemoiOS/AppDatabase.swift
struct AppDatabase {
  private let dbWriter: any DatabaseWriter

  init(_ dbWriter: any DatabaseWriter) throws {
    self.dbWriter = dbWriter
    try migrator.migrate(self.dbWriter)

    #if DEBUG
      try self.dbWriter.read { db in
        let rows = try ProjectMetadata.all().fetchAll(db)
        if rows.isEmpty {
          AppFiles().deleteImagesFolder()
          try SharedPersistence().removeSharedData()
        }
      }

      UserDefaults.standard.set(false, forKey: UserCreatedOneProject)

    #endif
  }
}

extension AppDatabase {
  private var migrator: DatabaseMigrator {
    var migrator = DatabaseMigrator()

    migrator.registerMigration("projects") { db in
      try db.create(table: "project", options: [.ifNotExists]) { table in
        table.autoIncrementedPrimaryKey("id")
        table.column("name", .text).notNull().indexed()
        table.column("completed", .boolean).notNull().indexed()
        table.column("isDeleted", .boolean).notNull()
        table.column("createDate", .datetime).notNull()
        table.column("updateDate", .datetime).notNull()
      }

      try db.create(table: "projectImage", options: [.ifNotExists]) {
        table in
        table.autoIncrementedPrimaryKey("id")
        table.belongsTo("project").notNull()
        table.column("filePath", .text).notNull()
        table.column("thumbnail", .text).notNull()
        table.column("isDeleted", .boolean).notNull()
        table.column("createDate", .datetime).notNull()
        table.column("updateDate", .datetime).notNull()
      }

      try db.create(table: "section", options: [.ifNotExists]) { table in
        table.autoIncrementedPrimaryKey("id")
        table.belongsTo("project").notNull()
        table.column("name", .text).notNull().indexed()
        table.column("isDeleted", .boolean).notNull()
        table.column("createDate", .datetime).notNull()
        table.column("updateDate", .datetime).notNull()
      }

      try db.create(table: "sectionItem", options: [.ifNotExists]) {
        table in
        table.autoIncrementedPrimaryKey("id")
        table.belongsTo("section", onDelete: .cascade).notNull()
        table.column("text", .text).notNull().indexed()
        table.column("isComplete", .boolean).notNull().indexed()
        table.column("isDeleted", .boolean).notNull()
        table.column("order", .integer).notNull()
        table.column("createDate", .datetime).notNull()
        table.column("updateDate", .datetime).notNull()
      }

      try db.create(table: "sectionItemNote", options: [.ifNotExists]) {
        table in
        table.autoIncrementedPrimaryKey("id")
        table.belongsTo("sectionItem", onDelete: .cascade).notNull()
          .unique()
        table.column("text", .text).notNull().indexed()
        table.column("createDate", .datetime).notNull()
        table.column("updateDate", .datetime).notNull()
      }
    }

    #if DEBUG
      migrator.eraseDatabaseOnSchemaChange = true
    #endif

    return migrator
  }
}

extension AppDatabase {
  var reader: DatabaseReader {
    dbWriter
  }
}

extension AppDatabase {
  func addProject(project: inout ProjectMetadataInput) throws
    -> ProjectMetadata
  {
    try dbWriter.write { db in
      let now = Date()
      project.createDate = now
      project.updateDate = now
      try project.save(db)
      return ProjectMetadata(from: project)
    }
  }

  func getWriter() -> any DatabaseWriter {
    return dbWriter
  }
}

extension AppDatabase {
  func fetchProjectsAndProjectImage() throws -> [ProjectCardModel] {
    return try dbWriter.read { db in
      // let request = ProjectMetadata.including(optional: ProjectMetadata.image)
      // let projectsData = try ProjectCardModel.fetchAll(db, request)
      // print(projectsData)
      // print(projectsData.count)
      let projects: [ProjectMetadata] = try ProjectMetadata.all().order(
        ProjectColumns.id
      )
      .fetchAll(db)

      let projectCards = try projects.map { project in
        let projectIdColumn = Column("projectId")
        let record = try ProjectImageRecord.all().filter(
          projectIdColumn == project.id
        ).order(Column("id")).fetchOne(db)

        return ProjectCardModel(project: project, image: record)
      }

      return projectCards
    }
  }

  func getProject(id: Int64) throws -> ProjectMetadata? {
    return try dbWriter.read { db in
      try ProjectMetadata.all().filter(ProjectColumns.id == id)
        .fetchOne(db)
    }
  }

  func getSections(projectId: Int64) throws -> [Section] {
    return try dbWriter.read { db in
      let sectionRecords: [SectionRecord] =
        try SectionRecord
        .all()
        .filter(Column("projectId") == projectId)
        .fetchAll(db)

      return try sectionRecords.map { sectionRecord in
        let sectionItems = try getSectionItems(
          sectionId: sectionRecord.id,
          from: db
        )
        return
          Section(
            section: sectionRecord,
            items: sectionItems,
          )
      }
    }
  }

  func getSectionItems(sectionId: Int64, from db: Database) throws
    -> [SectionItem]
  {
    let sectionItems =
      try SectionItemRecord
      .including(optional: SectionItemRecord.note)
      .filter(Column("sectionId") == sectionId)
      .filter(Column("isDeleted") == false)
      .order(Column("order").asc)
      .asRequest(of: SectionItem.self)
      .fetchAll(db)

    return sectionItems
  }

  func getProjectImageRecords(projectId: Int64) throws -> [ProjectImageRecord] {
    return try dbWriter.read { db in
      let projectIdColumn = Column("projectId")
      let records: [ProjectImageRecord] = try ProjectImageRecord.all()
        .filter(projectIdColumn == projectId).order(Column("id"))
        .fetchAll(db)

      return records
    }

  }

  func getProjectThumbnails(projectId: Int64, records: [ProjectImageRecord]) -> [ProjectImage] {
    var projectImages: [ProjectImage] = []

    for record in records {
      do {
        let thumbnailData = try AppFiles().getThumbnailImage(
          for: record.thumbnail,
          fromProject: projectId
        )
        // TODO: show a placeholder image or view instead of ignoring the image that failed to load
        // inform the user of this error
        guard let thumbnail = thumbnailData else {
          NSLog(
            "couldn't get image thumbnail \(record.thumbnail) for project: \(projectId)"
          )
          continue
        }
        let projectImage = ProjectImage(
          record: record,
          path: record.filePath,
          image: thumbnail
        )
        projectImages.append(projectImage)
      } catch {
        // add error handling but don't exit the function
      }
    }

    return projectImages
  }
}

extension AppDatabase {
  static func empty() -> AppDatabase {
    let dbQueue = try! DatabaseQueue()
    return try! AppDatabase(dbQueue)
  }
}

extension AppDatabase {
  /// Shared database instance. Thread-safe lazy initialization.
  /// GRDB's DatabaseQueue handles all thread synchronization internally.
  static let db: AppDatabase = makeDb(name: "db")

  static func makeDb(name: String) -> AppDatabase {
    do {
      // create the "Application Support/Database" directory if needed
      let fileManager = FileManager.default
      let appSupportUrl = try fileManager.url(
        for: .applicationSupportDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
      )
      let directoryUrl = appSupportUrl.appendingPathComponent(
        "Database",
        isDirectory: true
      )

      // create database folder
      try fileManager.createDirectory(
        at: directoryUrl,
        withIntermediateDirectories: true
      )

      // open or create database
      let databaseUrl = directoryUrl.appendingPathComponent(name)
        .appendingPathExtension("sqlite")
      let dbQueue = try DatabaseQueue(
        path: databaseUrl.path(percentEncoded: false)
      )

      let appDatabase = try AppDatabase(dbQueue)

      return appDatabase
    } catch {
      fatalError("Opening database error: \(error)")
    }
  }
}

// protocol DbStore {
//   func deleteProjectSection(section: SectionRecord) async throws
//   func updateProjectTitle(projectData: ProjectMetadata) async throws
// }

// extension AppDatabase: DbStore {
extension AppDatabase {
  func deleteProjectSection(section: SectionRecord) async throws {
    _ = try await dbWriter.write { db in
      try section.delete(db)
    }
  }

  func updateProjectTitle(projectData: ProjectMetadata) async throws {
    _ = try await dbWriter.write { db in
      try projectData.update(db)
    }
  }

  func updateSectionName(sectionId: Int64, newName: String) async throws {
    _ = try await dbWriter.write { db in
      try db.execute(
        sql: "UPDATE section SET name = ?, updateDate = ? WHERE id = ?",
        arguments: [newName, Date(), sectionId]
      )
    }
  }
}
