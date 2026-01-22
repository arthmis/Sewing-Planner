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

  init(fabric: FabricRecord, image: FabricImage? = nil) {
    self.fabric = fabric
    self.image = image
  }
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

  init(from input: FabricRecordInput) {
    self.id = input.id!
    self.name = input.name
    self.description = input.description
    self.length = input.length
    self.color = input.color
    self.fabricType = input.fabricType
    self.pattern = input.pattern
    self.storePurchasedFrom = input.storePurchasedFrom
    self.link = input.link
    self.purchasePrice = input.purchasePrice
    self.purchaseDate = input.purchaseDate
    self.createDate = input.createDate
    self.updateDate = input.updateDate
  }
}

struct FabricRecordInput: Hashable, Identifiable, Codable, EncodableRecord, FetchableRecord,
  MutablePersistableRecord, TableRecord
{
  var id: Int64?
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

  mutating func didInsert(_ inserted: InsertionSuccess) {
    id = inserted.rowID
  }
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

enum FabricsEvent {
  case loadFabrics
  case storeFabric(FabricInput)
  case addFabricToState(FabricRecord)
  case addFabricsToState([FabricRecord])
}

extension StateStore {
  func handleFabricsEvent(_ event: FabricsEvent, state: FabricsState) -> Effect? {
    switch event {
      case .storeFabric(let fabricInput):
        let now = Date.now
        let fabricRecordInput = FabricRecordInput(
          name: fabricInput.name,
          length: fabricInput.length,
          createDate: now,
          updateDate: now
        )
        return .StoreFabric(fabricRecordInput)

      case .addFabricToState(let fabric):
        state.fabrics.append(FabricModel(fabric: fabric))

        return nil
      case .loadFabrics:
        return .retrieveAllFabrics
      case .addFabricsToState(let fabrics):
        let fabrics = fabrics.map { fabric in
          FabricModel(fabric: fabric)
        }
        state.fabrics.append(contentsOf: fabrics)

        return nil
    }
  }
}
