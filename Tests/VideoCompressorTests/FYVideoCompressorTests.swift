import XCTest
@testable import VideoCompressor
import AVFoundation

final class FYVideoCompressorTests: XCTestCase {
 
    // http://clips.vorwaerts-gmbh.de/VfE_html5.mp4  5.3
//    static let testVideoURL = URL(string: "https://file-examples.com/storage/fe92e8a57762aaf72faee17/2017/04/file_example_MP4_1280_10MG.mp4")! // video size 5.3M
    
//    static let testVideoURL = URL(string: "https://www.learningcontainer.com/wp-content/uploads/2020/05/sample-mov-file.mov")!

        
    
    
    ///https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4
    ///
    
    let downloader = Downloader()
    
    let compressor = VideoCompressor()
 
    func testCompressVideoBitrate() {
        let urlString = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        let config = VideoCompressor.CompressionConfig(videoBitrate: 200_000, resolution: .sd480p)
        compressVideo(urlString: urlString, config: config)
    }
    
    func testCompressVideoSizeNoSet() {
        let urlString = "https://jsoncompare.org/LearningContainer/SampleFiles/Video/MP4/Sample-MP4-Video-File-for-Testing.mp4"
        let config = VideoCompressor.CompressionConfig(resolution: .custom(CGSize(width: -1, height: -1)))
        compressVideo(urlString: urlString, config: config)
    }
    
    func testCompressVideoMaxKeyFrameInterval() {
        let urlString = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        let config = VideoCompressor.CompressionConfig(videoMaxKeyFrameInterval: 1, resolution: .sd480p)
        compressVideo(urlString: urlString, config: config)
    }
    
    func testCompressVideoFramerate() {
        let urlString = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        let config = VideoCompressor.CompressionConfig(videoMaxKeyFrameInterval: 1, videoFramerate: 24, resolution: .sd480p)
        compressVideo(urlString: urlString, config: config)
    }
    
    func compressVideo(urlString: String, config: VideoCompressor.CompressionConfig) {
        
        downloader.setupSampleVideoPath(url: [urlString])
        
        let video = self.downloader.videos.first(where: { $0.urlString == urlString })!
        
        let expectation = XCTestExpectation(description: "compress video")
        
        downloader.downloadSampleVideo(urlString) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let success):
                
                self.compressor.compressVideo(success, config: config) { result in
                    switch result {
                    case .success(let url):
                        video.compressedURL = url
                        expectation.fulfill()
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                }
                

            case .failure(_):
                break
            }
        }
        
        wait(for: [expectation], timeout: 100)
        XCTAssertNotNil(video.compressedURL)
        XCTAssertTrue(try video.localURL!.fileSize() > (try video.compressedURL!.fileSize()))
    }
 
 
 

}
