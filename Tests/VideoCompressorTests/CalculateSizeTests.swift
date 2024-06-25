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
        XCTAssertEqual(result, originalSize, "Should return the original size when target size is larger")
    }
    
    func testCalculateSizeWhenTargetSizeIsZeroOrNegative() {
        let originalSize = CGSize(width: 1920, height: 1080)
        let resolution = VideoCompressor.VideoResolution.custom(.zero)
        let result = test.calculateSize(resolution: resolution, originalSize: originalSize)
        XCTAssertEqual(result, originalSize, "Should return the original size when target size is zero or negative")
    }
    
    func testCalculateSizeWhenTargetSizeIsValid() {
        let originalSize = CGSize(width: 1920, height: 1080)
        let resolution = VideoCompressor.VideoResolution.hd720p
        let result = test.calculateSize(resolution: resolution, originalSize: originalSize)
        XCTAssertEqual(result, CGSize(width: 1280, height: 720), "Should return the target size when it is valid")
    }
    
    func testCalculateSizeWhenWidthIsNegative() {
        let originalSize = CGSize(width: 1920, height: 1080)
        let resolution = VideoCompressor.VideoResolution.custom(CGSize(width: -1, height: 720))
        let result = test.calculateSize(resolution: resolution, originalSize: originalSize)
        let expectedWidth = Int(720 * originalSize.width / originalSize.height)
        XCTAssertEqual(result, CGSize(width: CGFloat(expectedWidth), height: 720), "Should calculate the width based on height when width is negative")
    }
    
    func testCalculateSizeWhenHeightIsNegative() {
        let originalSize = CGSize(width: 1920, height: 1080)
        let resolution = VideoCompressor.VideoResolution.custom(CGSize(width: 1280, height: -1))
        let result = test.calculateSize(resolution: resolution, originalSize: originalSize)
        let expectedHeight = Int(1280 * originalSize.height / originalSize.width)
        XCTAssertEqual(result, CGSize(width: 1280, height: CGFloat(expectedHeight)), "Should calculate the height based on width when height is negative")
    }
    
}
