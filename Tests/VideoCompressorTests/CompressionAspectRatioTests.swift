import AVFoundation
import XCTest

@testable import VideoCompressor

@available(iOS 15.0, macOS 12.0, *)
final class CompressionAspectRatioTests: XCTestCase {
  func testCompressionPreservesDimensionsOrientationAndPlayableFrames() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let cases: [(CGSize, CGSize, CGAffineTransform)] = [
      (CGSize(width: 1080, height: 1920), CGSize(width: 720, height: 1280), .identity),
      (CGSize(width: 1440, height: 1080), CGSize(width: 960, height: 720), .identity),
      (CGSize(width: 1080, height: 1080), CGSize(width: 720, height: 720), .identity),
      (CGSize(width: 480, height: 640), CGSize(width: 480, height: 640), .identity),
      (CGSize(width: 1920, height: 1000), CGSize(width: 1280, height: 666), .identity),
      (
        CGSize(width: 1920, height: 1080), CGSize(width: 1280, height: 720),
        CGAffineTransform(a: 0, b: 1, c: -1, d: 0, tx: 1080, ty: 0)
      ),
    ]

    for (sourceSize, expectedSize, transform) in cases {
      let sourceURL = directory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
      try await makeVideo(at: sourceURL, size: sourceSize, transform: transform)
      let config = VideoCompressor.CompressionConfig(resolution: .hd720p, outputPath: directory)
      let outputURL: URL = try await withCheckedThrowingContinuation { continuation in
        VideoCompressor().compressVideo(sourceURL, config: config) {
          continuation.resume(with: $0)
        }
      }

      let asset = AVURLAsset(url: outputURL)
      let tracks = try await asset.loadTracks(withMediaType: .video)
      let track = try XCTUnwrap(tracks.first)
      let outputSize = try await track.load(.naturalSize)
      let outputTransform = try await track.load(.preferredTransform)
      XCTAssertEqual(outputSize, expectedSize, "Input: \(sourceSize)")
      XCTAssertEqual(outputTransform, transform)

      let generator = AVAssetImageGenerator(asset: asset)
      generator.appliesPreferredTrackTransform = true
      let frame = try generator.copyCGImage(at: .zero, actualTime: nil)
      let displayedSize = CGRect(origin: .zero, size: expectedSize).applying(transform).size
      XCTAssertEqual(frame.width, Int(abs(displayedSize.width)))
      XCTAssertEqual(frame.height, Int(abs(displayedSize.height)))
    }
  }

  private func makeVideo(at url: URL, size: CGSize, transform: CGAffineTransform) async throws {
    let writer = try AVAssetWriter(url: url, fileType: .mp4)
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
      AVVideoCodecKey: AVVideoCodecType.h264,
      AVVideoWidthKey: Int(size.width),
      AVVideoHeightKey: Int(size.height),
    ])
    input.transform = transform
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input)
    writer.add(input)
    XCTAssertTrue(writer.startWriting())
    writer.startSession(atSourceTime: .zero)

    var buffer: CVPixelBuffer?
    XCTAssertEqual(
      CVPixelBufferCreate(
        nil, Int(size.width), Int(size.height), kCVPixelFormatType_32BGRA, nil, &buffer),
      kCVReturnSuccess
    )
    let pixelBuffer = try XCTUnwrap(buffer)
    CVPixelBufferLockBaseAddress(pixelBuffer, [])
    memset(
      CVPixelBufferGetBaseAddress(pixelBuffer), 128,
      CVPixelBufferGetBytesPerRow(pixelBuffer) * CVPixelBufferGetHeight(pixelBuffer)
    )
    CVPixelBufferUnlockBaseAddress(pixelBuffer, [])

    await withCheckedContinuation { continuation in
      var frameIndex = 0
      input.requestMediaDataWhenReady(on: DispatchQueue(label: "VideoCompressorTests.fixture")) {
        while input.isReadyForMoreMediaData, frameIndex < 3 {
          XCTAssertTrue(adaptor.append(pixelBuffer, withPresentationTime: CMTime(value: Int64(frameIndex), timescale: 24)))
          frameIndex += 1
        }
        if frameIndex == 3 {
          input.markAsFinished()
          continuation.resume()
        }
      }
    }
    await writer.finishWriting()
    XCTAssertEqual(writer.status, .completed, writer.error?.localizedDescription ?? "")
  }
}
