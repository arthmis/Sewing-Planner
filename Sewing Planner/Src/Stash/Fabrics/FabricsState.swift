import GRDB
import SwiftUI

@Observable
class FabricsState {
  var fabrics: [FabricModel] = []
  var navigation: [FabricModel] = []
  var selectedFabric: FabricModel?

  init() {

  }
}

struct FabricModel {
  let fabric: FabricRecord
  let image: FabricImage?
}

struct FabricImage {
  let fabricImageRecord: FabricImageRecord
  let image: UIImage?
}

struct FabricRecord: Identifiable, Codable, EncodableRecord, FetchableRecord,
  MutablePersistableRecord, TableRecord
{
  var id: Int64
  var name: String
  var description: String?
  var length: Float64
  var color: String?
  var fabricType: String?
  var pattern: String?
  var storePurchasedFrom: String?
  var link: String?
  var purchasePrice: Float64?
  var purchaseDate: Date?
  var createDate: Date
  var updateDate: Date
  static let databaseTableName = "fabrics"
}

struct FabricImageRecord: Identifiable, Codable, EncodableRecord, FetchableRecord,
  MutablePersistableRecord, TableRecord
{
  var id: Int64
  var fabricId: Int64
  var filePath: String
  var thumbnail: String
  var order: Int8
  var createDate: Date
  var updateDate: Date
  static let databaseTableName = "fabricImages"
}
