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

struct FiberType: RawRepresentable, Hashable, Codable, Sendable {
  let rawValue: String

  init(rawValue: String) {
    self.rawValue = rawValue
  }

  // Animal
  static let wool = FiberType(rawValue: "wool")
  static let silk = FiberType(rawValue: "silk")
  static let alpaca = FiberType(rawValue: "alpaca")
  static let angora = FiberType(rawValue: "angora")
  static let camel = FiberType(rawValue: "camel")
  static let cashmere = FiberType(rawValue: "cashmere")
  static let chiengora = FiberType(rawValue: "chiengora")
  static let llama = FiberType(rawValue: "llama")
  static let mohair = FiberType(rawValue: "mohair")
  static let qiviut = FiberType(rawValue: "qiviut")
  static let vicuna = FiberType(rawValue: "vicuna")
  static let yak = FiberType(rawValue: "yak")

  // Plant
  static let cotton = FiberType(rawValue: "cotton")
  static let linen = FiberType(rawValue: "linen")
  static let coir = FiberType(rawValue: "coir")
  static let kapok = FiberType(rawValue: "kapok")
  static let banana = FiberType(rawValue: "banana")
  static let hemp = FiberType(rawValue: "hemp")
  static let jute = FiberType(rawValue: "jute")
  static let kenaf = FiberType(rawValue: "kenaf")
  static let ramie = FiberType(rawValue: "ramie")
  static let sugarcane = FiberType(rawValue: "sugarcane")
  static let abaca = FiberType(rawValue: "abaca")
  static let pina = FiberType(rawValue: "pina")
  static let raffia = FiberType(rawValue: "raffia")
  static let sisal = FiberType(rawValue: "sisal")

  // Natural synthesized fibers
  static let bamboo = FiberType(rawValue: "bamboo")
  static let modal = FiberType(rawValue: "modal ")
  static let lyocell = FiberType(rawValue: "lyocell")
  static let rayon = FiberType(rawValue: "rayon")
  static let acetate = FiberType(rawValue: "acetate")

  // Synthetic
  static let polyester = FiberType(rawValue: "polyester")
  static let nylon = FiberType(rawValue: "nylon")
  static let spandex = FiberType(rawValue: "spandex")
  static let acrylic = FiberType(rawValue: "acrylic")

  // MARK: - Display name (for UI)
  var displayName: String {
    rawValue.capitalized
  }

  // Static list of all known types (can be used for pickers)
  static var knownTypes: [FiberType] {
    [
      // Animal
      .wool, .silk, .alpaca, .angora, .camel, .cashmere,
      .chiengora, .llama, .mohair, .qiviut, .vicuna, .yak,
      // Plant
      .cotton, .linen, .coir, .kapok, .banana, .hemp,
      .jute, .kenaf, .ramie, .sugarcane, .abaca, .pina, .raffia, .sisal,
      // Natural synthesized fibers
      .bamboo, .modal, .lyocell, .rayon, .acetate,
      // Synthetic
      .polyester, .nylon, .spandex, .acrylic,
    ]
  }

  static var fiberSet: Set<FiberType> {
    Set(knownTypes)
  }
}

// Usage in your FabricRecord
struct FabricContent: Codable, Hashable {
  var fibers: [FiberType]

  // Convenience initializers
  init(_ fibers: FiberType...) {
    self.fibers = fibers
  }

  init(fibers: [FiberType]) {
    self.fibers = fibers
  }
}

enum FabricCategory: Codable {
  case natural
  case synthetic
  case semiSynthetic
}

struct FabricRecord: Identifiable, Codable, EncodableRecord, FetchableRecord,
  MutablePersistableRecord, TableRecord
{
  var id: Int64
  var name: String
  var description: String?
  var length: Float64
  var width: Float64?
  var color: String?
  var fabricContent: [FabricContent]?
  var fabricCategory: FabricCategory?
  var pattern: String?
  var stretch: String?
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
    self.width = input.width
    self.color = input.color
    self.fabricContent = input.fabricContent
    self.fabricCategory = input.fabricCategory
    self.pattern = input.pattern
    self.stretch = input.stretch
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
  var width: Float64?
  var color: String?
  var fabricContent: [FabricContent]?
  var fabricCategory: FabricCategory?
  var pattern: String?
  var stretch: String?
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
  case addFabric(FabricRecord)
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

      case .addFabric(let fabric):
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
