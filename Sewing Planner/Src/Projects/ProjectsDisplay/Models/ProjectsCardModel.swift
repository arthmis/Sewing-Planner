import GRDB

struct ProjectCardModel: Decodable, FetchableRecord {
  let project: ProjectMetadata
  let image: ProjectImageRecord?
}
