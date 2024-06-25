
import XCTest
@testable import VideoCompressor

// sample video https://download.blender.org/demo/movies/BBB/

class BatchCompressionTests: XCTestCase {

 
    let sampleVideoURLs = [
        "https://www.learningcontainer.com/wp-content/uploads/2020/05/sample-mov-file.mov",
        "https://www.learningcontainer.com/wp-content/uploads/2020/05/sample-mp4-file.mp4",
        "http://clips.vorwaerts-gmbh.de/VfE_html5.mp4"
    ]


    
    let downloader = Downloader()

    
    
    
    override func setUpWithError() throws {
        downloader.setupSampleVideoPath(url: sampleVideoURLs)
        let expectation = XCTestExpectation(description: "video cache downloading remote video")
        var error: Error?
        
        var allSampleVideosCount = downloader.videos.count
        
        sampleVideoURLs.forEach { urlStr in
            downloader.downloadSampleVideo(urlStr) { result in
                switch result {
                case .failure(let _error):
                    print("💀failed to download sample video:(\(urlStr)) with error: \(_error)")
                    error = _error
                case .success(let path):
                    print("sample video downloaded at path: \(path)")
                    allSampleVideosCount -= 1
                    if allSampleVideosCount <= 0 {
                        expectation.fulfill()
                    }
                }
            }
        }
        
        if let error = error {
            throw error
        }
        wait(for: [expectation], timeout: 300)
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        downloader.clear()
    }
    
    func testCompressVideo() {
        let expectation = XCTestExpectation(description: "compress video")
                    
        var allSampleVideosCount = downloader.videos.count
        
        downloader.videos.forEach { sampleVideo in
            VideoCompressor().compressVideo(sampleVideo.remoteUrl!, config: .default) { result in
                switch result {
                case .success(let video):
                    sampleVideo.compressedURL = video
                    
                    allSampleVideosCount -= 1
                    if allSampleVideosCount <= 0 {
                        expectation.fulfill()
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
            }
        }
        
        wait(for: [expectation], timeout: 300)
//        XCTAssertNotNil(downloader.compressedVideoPath)
//        XCTAssertTrue(try self.sampleVideoPath.sizePerMB() > compressedVideoPath!.sizePerMB())
    }
    
    
}
