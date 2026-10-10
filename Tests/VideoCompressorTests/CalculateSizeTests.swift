import XCTest

@testable import VideoCompressor

final class CalculateSizeTests: XCTestCase {

  let test = VideoCompressor()
  func testCalculateSizeWithoutResolution() {
    let originalSize = CGSize(width: 1920, height: 1080)
    let result = test.calculateSize(resolution: nil, originalSize: originalSize)
    XCTAssertEqual(result, originalSize, "Should return the original size when resolution is nil")
  }

  func testCalculateSizeWhenTargetSizeIsLarger() {
    let originalSize = CGSize(width: 1920, height: 1080)
    let resolution = VideoCompressor.VideoResolution.uhd4320p
    let result = test.calculateSize(resolution: resolution, originalSize: originalSize)
    XCTAssertEqual(
      result, originalSize, "Should return the original size when target size is larger")
  }

  func testCalculateSizeWhenTargetSizeIsZeroOrNegative() {
    let originalSize = CGSize(width: 1920, height: 1080)
    let resolution = VideoCompressor.VideoResolution.custom(.zero)
    let result = test.calculateSize(resolution: resolution, originalSize: originalSize)
    XCTAssertEqual(
      result, originalSize, "Should return the original size when target size is zero or negative")
  }

  func testCalculateSizeWhenTargetSizeIsValid() {
    let originalSize = CGSize(width: 1920, height: 1080)
    let resolution = VideoCompressor.VideoResolution.hd720p
    let result = test.calculateSize(resolution: resolution, originalSize: originalSize)
    XCTAssertEqual(
      result, CGSize(width: 1280, height: 720), "Should return the target size when it is valid")
  }

  func test720pPreservesAspectRatioAndOrientation() {
    let cases: [(CGSize, CGSize)] = [
      (CGSize(width: 1080, height: 1920), CGSize(width: 720, height: 1280)),
      (CGSize(width: 1440, height: 1080), CGSize(width: 960, height: 720)),
      (CGSize(width: 1080, height: 1080), CGSize(width: 720, height: 720)),
      (CGSize(width: 2400, height: 1080), CGSize(width: 1280, height: 576)),
      (CGSize(width: 1080, height: 2400), CGSize(width: 576, height: 1280)),
    ]

    for (original, expected) in cases {
      XCTAssertEqual(test.calculateSize(resolution: .hd720p, originalSize: original), expected)
    }
  }

  func test720pDoesNotUpscaleSmallVideos() {
    for size in [CGSize(width: 640, height: 480), CGSize(width: 480, height: 640)] {
      XCTAssertEqual(test.calculateSize(resolution: .hd720p, originalSize: size), size)
    }
  }

  func testAllPresetsPreserveFourByThreeAspectRatio() {
    let cases: [(VideoCompressor.VideoResolution, CGSize)] = [
      (.sd360p, CGSize(width: 480, height: 360)),
      (.sd480p, CGSize(width: 640, height: 480)),
      (.hd720p, CGSize(width: 960, height: 720)),
      (.hd1080p, CGSize(width: 1440, height: 1080)),
      (.hd1440p, CGSize(width: 1920, height: 1440)),
      (.uhd2160p, CGSize(width: 2880, height: 2160)),
      (.uhd4320p, CGSize(width: 3840, height: 2880)),
    ]
    for (resolution, expected) in cases {
      XCTAssertEqual(
        test.calculateSize(resolution: resolution, originalSize: CGSize(width: 3840, height: 2880)),
        expected
      )
    }
  }

  func testPresetProducesEvenPixelDimensionsWhenScaling() {
    let result = test.calculateSize(
      resolution: .hd720p, originalSize: CGSize(width: 1920, height: 1000))
    XCTAssertEqual(result, CGSize(width: 1280, height: 666))
  }

  func testCustomSizeStillUsesExplicitDimensions() {
    let target = CGSize(width: 640, height: 480)
    XCTAssertEqual(
      test.calculateSize(resolution: .custom(target), originalSize: CGSize(width: 1920, height: 1080)),
      target
    )
  }

  func testCalculateSizeWhenWidthIsNegative() {
    let originalSize = CGSize(width: 1920, height: 1080)
    let resolution = VideoCompressor.VideoResolution.custom(CGSize(width: -1, height: 720))
    let result = test.calculateSize(resolution: resolution, originalSize: originalSize)
    let expectedWidth = Int(720 * originalSize.width / originalSize.height)
    XCTAssertEqual(
      result, CGSize(width: CGFloat(expectedWidth), height: 720),
      "Should calculate the width based on height when width is negative")
  }

  func testCalculateSizeWhenHeightIsNegative() {
    let originalSize = CGSize(width: 1920, height: 1080)
    let resolution = VideoCompressor.VideoResolution.custom(CGSize(width: 1280, height: -1))
    let result = test.calculateSize(resolution: resolution, originalSize: originalSize)
    let expectedHeight = Int(1280 * originalSize.height / originalSize.width)
    XCTAssertEqual(
      result, CGSize(width: 1280, height: CGFloat(expectedHeight)),
      "Should calculate the height based on width when height is negative")
  }

}
