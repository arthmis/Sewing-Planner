import Foundation
import Testing
import UIKit

@testable import Sewing_Planner

struct Sewing_PlannerAppFilesTests {
  func createSolidColorImage(size: CGSize, color: UIColor, scale: CGFloat = UIScreen.main.scale)
    -> UIImage
  {
    let format = UIGraphicsImageRendererFormat()
    format.scale = scale
    let renderer = UIGraphicsImageRenderer(size: size, format: format)

    let image = renderer.image { context in
      color.setFill()
      context.fill(CGRect(origin: .zero, size: size))
    }

    return image
  }

  @Test("Test save image")
  func testSaveImage() throws {
    let size = CGSize(width: 200, height: 200)
    let color = UIColor.white
    let image = createSolidColorImage(size: size, color: color)

    let result = try AppFiles().saveProjectImage(
      projectId: 1,
      image: ProjectImageInput(image: image)
    )
    #expect(result != nil)

    let fileManager = FileManager.default
    let filePath = AppFiles().getPathForImage(forProject: 1, fileIdentifier: result!.0)
    let exists = fileManager.fileExists(atPath: filePath.path)
    #expect(exists == true)
  }
}
