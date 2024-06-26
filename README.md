# VideoCompressor

VideoCompressor is a high-performance, flexible, and easy-to-use video compression library written in Swift. It leverages hardware-accelerated APIs in AVFoundation to achieve fast and efficient video compression.

## Features

1. **Customizable Compression Configuration**: You can specify the video codec type, bitrate, key frame interval, frame rate, profile level, audio format ID, audio sample rate, audio bitrate, number of audio channels, and other parameters to obtain the desired output video quality and size.

2. **Supports Various Video Resolutions**: The library supports a wide range of video resolutions from 360p to 4320p (8K), as well as custom resolutions.

3. **Asynchronous Processing**: Video compression is performed asynchronously, without blocking the main thread.

4. **Error Handling**: The library handles common errors, such as the absence of a video track or an invalid output path.

5. **Logging**: It includes logging capabilities for debugging purposes.

## Usage

First, import the library:

```swift
import VideoCompressor
```

Here is a simple example of how to use the VideoCompressor library:

```swift
let compressor = VideoCompressor()
let url = URL(fileURLWithPath: "/path/to/your/video/file.mp4")

let config = VideoCompressor.CompressionConfig(
    videoCodecType: .h264,
    videoBitrate: 2000_000,
    videoMaxKeyFrameInterval: 10,
    videoFramerate: 24,
    videoProfileLevel: AVVideoProfileLevelH264High41,
    audioFormatID: kAudioFormatMPEG4AAC,
    audioSampleRate: 44100,
    audioBitrate: 128_000,
    audioNumberOfChannels: 2,
    audioChannelLayoutTag: kAudioChannelLayoutTag_Stereo,
    resolution: .hd720p,
    fileType: .mp4,
    outputPath: URL(fileURLWithPath: "/path/to/output/directory")
)

compressor.compressVideo(url, config: config) { result in
    switch result {
    case .success(let outputUrl):
        print("Compression successful, output URL: \(outputUrl)")
    case .failure(let error):
        print("Compression failed, error: \(error)")
    }
}
```

In this example, we create a `VideoCompressor` instance, specify the video file URL, configure the compression parameters, and then call the `compressVideo(_:config:completion:)` method. The completion handler will be called when the compression is finished, providing either the URL of the compressed video or an error.

## Installation

VideoCompressor is available as a Swift Package. To add it to your project, simply add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/wzio/VideoCompressor.git", .upToNextMajor(from: "1.0.0"))
]
```

Then, import `VideoCompressor` in the files where you want to use it.

## Requirements

- iOS 13.0 or later
- Swift 5.0 or later

## License

VideoCompressor is released under the MIT license. See [LICENSE](https://github.com/yourusername/VideoCompressor/blob/main/LICENSE) for more information.
