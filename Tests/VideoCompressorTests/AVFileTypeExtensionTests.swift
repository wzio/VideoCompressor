
import XCTest
import AVFoundation
import UniformTypeIdentifiers
@testable import VideoCompressor

class AVFileTypeExtensionTests: XCTestCase {

    func testValidAVFileType() {
        if #available(iOS 14.0, macOS 11.0, *) {
            let fileType = AVFileType.mp4
            XCTAssertEqual(fileType.fileExtension, "mp4")
        }
    }

    func testInvalidAVFileType() {
        if #available(iOS 14.0, macOS 11.0, *) {
            let fileType = AVFileType(rawValue: "com.example.invalid")
            XCTAssertEqual(fileType.fileExtension, "unknown")
        }
    }

    func testDeprecatedAVFileType() {
        if #available(iOS 14.0, macOS 11.0, *) {
            let fileType = AVFileType(rawValue: "public.mpeg-4")
            XCTAssertEqual(fileType.fileExtension, "mp4")
        }
    }

    func testValidAVFileTypePreIOS14() {
        if #available(iOS 14.0, macOS 11.0, *) {
        } else {
            let fileType = AVFileType.mp4
            XCTAssertEqual(fileType.fileExtension, "mp4")
        }
    }

    func testInvalidAVFileTypePreIOS14() {
        if #available(iOS 14.0, macOS 11.0, *) {
        } else {
            let fileType = AVFileType(rawValue: "com.example.invalid")
            XCTAssertEqual(fileType.fileExtension, "unknown")
        }
    }
}

