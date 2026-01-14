import Foundation
import Testing
import UIKit

@testable import Sewing_Planner

struct Sewing_PlannerAppFilesTests {
  // normally might set the scale to the device but because devices have different scales
  // it's better to manually set it to get consistent results
  // this only matters when comparing input image with the image saved on disk
  func createSolidColorImage(size: CGSize, color: UIColor, scale: CGFloat)
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
    let image = createSolidColorImage(size: size, color: color, scale: 1)

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

  @Test("Test get image")
  func testGetImage() throws {
    let size = CGSize(width: 600, height: 600)
    let color = UIColor.white
    let image = createSolidColorImage(size: size, color: color, scale: 1)

    let result = try AppFiles().saveProjectImage(
      projectId: 1,
      image: ProjectImageInput(image: image)
    )

    let storedImage = AppFiles().getImage(for: result!.0, fromProject: 1)
    #expect(storedImage != nil)
    #expect(storedImage!.pngData() == image.pngData())
  }
}
