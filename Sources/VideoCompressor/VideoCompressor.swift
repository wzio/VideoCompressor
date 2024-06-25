import Foundation
import AVFoundation
import CoreMedia
import OSLog

/// A high-performance, flexible and easy to use Video compressor library written by Swift.
/// Using hardware-accelerator APIs in AVFoundation.
public class VideoCompressor {
    
    private let group = DispatchGroup()
    private let videoCompressQueue = DispatchQueue.init(label: "com.video.compress_queue")
    private lazy var audioCompressQueue = DispatchQueue.init(label: "com.audio.compress_queue")
    
    public init() { }
    
    /// Compress Video with config.
    public func compressVideo(_ url: URL,
                              config: CompressionConfig,
                              completion: @escaping (Result<URL, Error>) -> Void) {
        let asset = AVAsset(url: url)
        FYLogger.logURL(url: url)
        compressVideo(asset, config: config, completion: completion)
    }
    
    /// Compress Video with Asset and config.
    public func compressVideo(_ asset: AVAsset, config: CompressionConfig, completion: @escaping (Result<URL, Error>) -> Void) {
        
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            completion(.failure(VideoCompressorError.noVideoTrack))
            return
        }
        let targetVideoBitrate = getVideoTargetBitrate(targetBitrate: config.videoBitrate, originalBitrate: videoTrack.estimatedDataRate)
        let targetSize = calculateSize(resolution: config.resolution, originalSize: videoTrack.naturalSize)
        var videoSettings: [String: Any] = [:]
        videoSettings[AVVideoCodecKey] = config.videoCodecKey
        videoSettings[AVVideoWidthKey] = targetSize.width
        videoSettings[AVVideoHeightKey] = targetSize.height
        
        var videoCompresionSettings: [String: Any] = [:]
        videoCompresionSettings[AVVideoAverageBitRateKey] = targetVideoBitrate
        videoCompresionSettings[AVVideoMaxKeyFrameIntervalKey] = config.videoMaxKeyFrameInterval
        videoCompresionSettings[AVVideoExpectedSourceFrameRateKey] = config.videoFramerate
        videoCompresionSettings[AVVideoProfileLevelKey] = config.videoProfileLevel
        videoSettings[AVVideoCompressionPropertiesKey] = videoCompresionSettings
        
        /// 合并user的设置
        if let videoSettingByUser = config.videoSettings {
            videoSettings.merge(videoSettingByUser, uniquingKeysWith: { _, new in
                new
            })
        }
        
        FYLogger.logVideoInfo(videoTrack,
                              targetBitrate: targetVideoBitrate,
                              targetNominalFrameRate: config.videoFramerate,
                              targetNaturalSize: targetSize,
                              setting: videoSettings)
        
        let audioTrack = asset.tracks(withMediaType: .audio).first
        var audioSettings: [String: Any]?
        if let audioTrack {
            var audioChannelLayout = AudioChannelLayout()
            memset(&audioChannelLayout, 0, MemoryLayout<AudioChannelLayout>.size)
            audioChannelLayout.mChannelLayoutTag = config.audioChannelLayoutTag
            
            audioSettings = [
                AVFormatIDKey: config.audioFormatID,
                AVSampleRateKey: config.audioSampleRate,
                AVEncoderBitRateKey: config.audioBitrate,
                AVNumberOfChannelsKey: config.audioNumberOfChannels,
                AVChannelLayoutKey: Data(bytes: &audioChannelLayout, count: MemoryLayout<AudioChannelLayout>.size)
            ]
            
            if let userSettings = config.audioSettings {
                audioSettings?.merge(userSettings) { _, new in
                    new
                }
            }
            FYLogger.logAudioInfo(audioTrack, config: config, setting: audioSettings)
        }
        
        let outputPath: URL = config.outputPath ?? FileManager.tempDirectory(with: "CompressedVideo")
        
        _compress(asset: asset,
                  fileType: config.fileType,
                  videoTrack,
                  videoSettings,
                  audioTrack,
                  audioSettings,
                  outputPath: outputPath,
                  completion: completion)
    }
    
    
 
    private func _compress(asset: AVAsset,
                           fileType: AVFileType,
                           _ videoTrack: AVAssetTrack,
                           _ videoSettings: [String: Any],
                           _ audioTrack: AVAssetTrack?,
                           _ audioSettings: [String: Any]?,
                           outputPath: URL,
                           completion: @escaping (Result<URL, Error>) -> Void) {
        guard FileManager.default.isValidDirectory(atPath: outputPath) else {
            completion(.failure(VideoCompressorError.outputPathNotValid(outputPath)))
            return
        }
        
        var outputPath = outputPath
        let videoName = UUID().uuidString + ".\(fileType.fileExtension)"
        outputPath.appendPathComponent("\(videoName)")
        
        do {
            
            let reader = try AVAssetReader(asset: asset)
            let writer = try AVAssetWriter(url: outputPath, fileType: fileType)
            
            // video
            let videoReaderSettings: [String:Any] =  [kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32ARGB ]
            
            let videoReaderOutput = AVAssetReaderTrackOutput(track: videoTrack,
                                                             outputSettings: videoReaderSettings)
            let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            // fix output video orientation
            videoWriterInput.transform = videoTrack.preferredTransform
            
            // video output
            if reader.canAdd(videoReaderOutput) {
                reader.add(videoReaderOutput)
                videoReaderOutput.alwaysCopiesSampleData = false
            }
            if writer.canAdd(videoWriterInput) {
                writer.add(videoWriterInput)
            }
            
            // audio output
            var audioWriterInput: AVAssetWriterInput?
            var audioReaderOutput: AVAssetReaderTrackOutput?
            if let audioTrack = audioTrack, let audioSettings = audioSettings {
                // Specify the number of audio channels we want when decompressing the audio from the asset to avoid error when handling audio data.
                // It really matters when the audio has more than 2 channels, e.g: 'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'
                audioReaderOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: [AVFormatIDKey: kAudioFormatLinearPCM,
                                                                                         AVNumberOfChannelsKey: 2])
                let adInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
                audioWriterInput = adInput
                if reader.canAdd(audioReaderOutput!) {
                    reader.add(audioReaderOutput!)
                }
                if writer.canAdd(adInput) {
                    writer.add(adInput)
                }
            }
            
#if DEBUG
            let startTime = Date()
#endif
            reader.startReading()
            writer.startWriting()
            writer.startSession(atSourceTime: CMTime.zero)
            
            // output video
            group.enter()
            
            outputVideoDataByReducingFPS(wirterInput: videoWriterInput,
                                         videoOutput: videoReaderOutput) {
                self.group.leave()
            }
            
            
            // output audio
            if let audioWriterInput, let audioReaderOutput {
                group.enter()
                outputAudioData(audioWriterInput, audioOutput: audioReaderOutput) {
                    self.group.leave()
                }
            }
            
            // completion
            group.notify(queue: .main) {
                writer.finishWriting {
                    reader.cancelReading()
#if DEBUG
                    FYLogger.logComletionInfo(startTime: startTime, destination: outputPath)
#endif
                    DispatchQueue.main.sync {
                        completion(.success(outputPath))
                    }
                }
            }
            
        } catch {
            completion(.failure(error))
        }
        
    }
    
    
    
    private func outputVideoDataByReducingFPS(wirterInput: AVAssetWriterInput,
                                              videoOutput: AVAssetReaderTrackOutput,
                                              completion: @escaping(() -> Void)) {
        wirterInput.requestMediaDataWhenReady(on: videoCompressQueue) {
            while wirterInput.isReadyForMoreMediaData {
                if let buffer = videoOutput.copyNextSampleBuffer() {
                    wirterInput.append(buffer)
                } else {
                    wirterInput.markAsFinished()
                    completion()
                    break
                }
            }
        }
    }
    
    private func outputAudioData(_ audioInput: AVAssetWriterInput,
                                 audioOutput: AVAssetReaderTrackOutput,
                                 completion:  @escaping(() -> Void)) {
        audioInput.requestMediaDataWhenReady(on: audioCompressQueue) {
            while audioInput.isReadyForMoreMediaData {
                if let buffer = audioOutput.copyNextSampleBuffer() {
                    audioInput.append(buffer)
                } else {
                    audioInput.markAsFinished()
                    completion()
                    break
                }
            }
        }
    }
}

extension VideoCompressor {
    
    func calculateSize(resolution: VideoResolution?, originalSize: CGSize) -> CGSize {
        guard let resolution else {
            return originalSize
        }
        let targetSize = resolution.pixelSize
        if targetSize.width >= originalSize.width && targetSize.height >= originalSize.height {
            return originalSize
        }
        if targetSize.width <= 0 && targetSize.height <= 0 {
            return originalSize
        } else if targetSize.width > 0 && targetSize.height > 0 {
            return targetSize
        } else if targetSize.width < 0 {
            let targetWidth = Int(targetSize.height * originalSize.width / originalSize.height)
            return CGSize(width: CGFloat(targetWidth), height: targetSize.height)
        } else if targetSize.height < 0 {
            let targetHeight = Int(targetSize.width * originalSize.height / originalSize.width)
            return CGSize(width: targetSize.width, height: CGFloat(targetHeight))
        } else {
            return originalSize
        }
    }
    
    func getVideoTargetBitrate(targetBitrate: Float, originalBitrate: Float) -> Float {
        if targetBitrate >= originalBitrate {
            return originalBitrate
        } else {
            return max(targetBitrate, Self.minimumVideoBitrate)
        }
    }
}
