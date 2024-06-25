import Foundation
import AVFoundation

public enum VideoCompressorError: Error, LocalizedError {
    case noVideoTrack
    case compressedFailed(_ error: Error)
    case outputPathNotValid(_ path: URL)
    
    public var errorDescription: String? {
        switch self {
        case .noVideoTrack:
            return "cannot find video track"
        case .compressedFailed(let error):
            return error.localizedDescription
        case .outputPathNotValid(let path):
            return "Output path is invalid: \(path)"
        }
    }
}

extension VideoCompressor {
    
    /// Youtube suggests 1Mbps for 24 frame rate 360p video, 1Mbps = 1000_000bps.
    /// Custom quality will not be affected by this value.
    static public let minimumVideoBitrate: Float = 1000_000
    
    public enum VideoResolution: Equatable {
        case sd360p
        case sd480p
        case hd720p
        case hd1080p
        case hd1440p
        case uhd2160p
        case uhd4320p
        case custom(CGSize)
        
        var pixelSize: CGSize {
            switch self {
            case .sd360p:
                return CGSize(width: 640, height: 360)
            case .sd480p:
                return CGSize(width: 854, height: 480)
            case .hd720p:
                return CGSize(width: 1280, height: 720)
            case .hd1080p:
                return CGSize(width: 1920, height: 1080)
            case .hd1440p:
                return CGSize(width: 2560, height: 1440)
            case .uhd2160p:
                return CGSize(width: 3840, height: 2160)
            case .uhd4320p:
                return CGSize(width: 7680, height: 4320)
            case .custom(let size):
                return size
            }
        }
    }
    
    // Compression Parameters
    public struct CompressionConfig {
        //Tag: video
        /// 输出的类型
        public var videoCodecKey: AVVideoCodecType
        /// target video bitrate.
        /// If the input video bitrate is less than this value, it will be ignored. unit is in bps
        ///  youtube suggested bitrate
        //        SDR video
        //        2160p (4K) with 60 fps: 53-68 Mbps
        //        2160p (4K) with 30 fps: 35-45 Mbps
        //        1440p (2K) with 60 fps: 24 Mbps
        //        1440p (2K) with 30 fps: 16 Mbps
        //        1080p (HD) with 60 fps: 12 Mbps
        //        1080p (HD) with 30 fps: 8 Mbps
        //        720p with 60 fps: 7.5 Mbps
        //        720p with 30 fps: 5 Mbps
        //        480p with 60 fps: 4 Mbps
        //        480p with 30 fps: 2.5 Mbps
        //        360p with 60 fps: 1.5 Mbps‍
        //        360p with 30 fps: 1 Mbps
        //        HDR video upload
        //        2160p (4K) with 60 fps: 66-85 Mbps
        //        2160p (4K) with 30 fps: 44-56 Mpbs
        //        1440p (2K) with 60 fps: 30 Mbps
        //        1440p (2K) with 30 fps: 20 Mbps
        //        1080p (HD) with 60 fps: 15 Mbps
        //        1080p (HD) with 30 fps: 10 Mbps
        //        720p with 60 fps: 9.5 Mbps
        //        720p with 30 fps: 6.5 Mbps
        public var videoBitrate: Float
        
        /// A key to access the maximum interval between keyframes.
        /// A key frame interval of 1 indicates that every frame must be a keyframe, 2 indicates that at least every other frame must be a keyframe, and so on.
        /// Default is 10.
        public var videoMaxKeyFrameInterval: Int
        
        /// If video's fps less than this value, this value will be ignored. Default is 24.
        /// Common frame rates include: 24, 25, 30, 48, 50, 60 frames per second (other frame rates are also acceptable).
        public var videoFramerate: Float
        
        ///  which sets the compatibility level of our video. H264 standard defines many profile levels to capture many devices’ capabilities, ranging from really low-end, low performance devices to really powerful, 4K TV processors. Profile level of High 4.1 is a common denominator among a vast number of smartphones, so we choose the default value of AVVideoProfileLevelH264High41 in our implementation. You can find the available options in the AVFoundation documentation.
        public var videoProfileLevel: String
        
        /// 如果这个值被设定，会覆盖前面所设定的值
        public var videoSettings: [String: Any]?
        
        //Tag: audio
        
        /// A type definition for audio format identifiers. default is kAudioFormatMPEG4AAC
        public var audioFormatID: AudioFormatID
        /// Sample rate
        /// Default 44_100
        public var audioSampleRate: Int
        
        /// Default is 128_000
        /// Audio CD bitrate is always 1,411 kilobits per second (Kbps). The MP3 format can range from around 96 to 320Kbps, and streaming services like Spotify range from around 96 to 160Kbps.
        public var audioBitrate: Float
        
        /// default is 2
        public var audioNumberOfChannels: Int
        
        /// If AVNumberOfChannelsKey specifies a channel count greater than 2, the dictionary must also specify a value for AVChannelLayoutKey.
        ///  default is  kAudioChannelLayoutTag_Stereo
        /// 另外这里只支持AudioChannelLayoutTag的设置，如果想要完整的AudioChannelLayout支持比如mChannelBitmap等支持，请直接使用audioSettings
        public var audioChannelLayoutTag: AudioChannelLayoutTag
        
        public var audioSettings: [String: Any]?
        
        /// Default is mp4
        public var fileType: AVFileType
        ///  compressed video will be moved to this path. If no value is set, `FYVideoCompressor` will create it for you.
        ///  Default is nil.
        public var outputPath: URL?
        
        /// Scale (resize) the input video
        /// 1. If you need to simply resize your video to a specific size (e.g 320×240), you can use the scale: CGSize(width: 320, height: 240)
        /// 2. If you want to keep the aspect ratio, you need to specify only one component, either width or height, and set the other component to a number below zero
        ///    e.g CGSize(width: 320, height: -1)
        ///    nil, (-, -), .zero will keep original resolution
        public var resolution: VideoResolution?
        
        static let `default` = CompressionConfig(resolution: .hd720p)
        
        public init(videoCodecType: AVVideoCodecType = .h264,
                    videoBitrate: Float = 2000_000,
                    videoMaxKeyFrameInterval: Int = 10,
                    videoFramerate: Float = 24,
                    videoProfileLevel: String = AVVideoProfileLevelH264High41,
                    videoSettings: [String: Any]? = nil,
                    
                    audioFormatID: AudioFormatID = kAudioFormatMPEG4AAC,
                    audioSampleRate: Int = 44100,
                    audioBitrate: Float = 128_000,
                    audioNumberOfChannels: Int = 2,
                    audioChannelLayoutTag: AudioChannelLayoutTag = kAudioChannelLayoutTag_Stereo,
                    audioSettings: [String: Any]? = nil,
                    
                    resolution: VideoResolution? = nil,
                    fileType: AVFileType = .mp4,
 
                    outputPath: URL? = nil) {
            self.videoCodecKey = videoCodecType
            self.videoBitrate = videoBitrate
            self.videoMaxKeyFrameInterval = videoMaxKeyFrameInterval
            self.videoFramerate = videoFramerate
            self.videoProfileLevel = videoProfileLevel
            self.videoSettings = videoSettings
            
            self.audioFormatID = audioFormatID
            self.audioSampleRate = audioSampleRate
            self.audioBitrate = audioBitrate
            self.audioNumberOfChannels = audioNumberOfChannels
            self.audioChannelLayoutTag = audioChannelLayoutTag
            self.audioSettings = audioSettings
            
            self.fileType = fileType
            self.resolution = resolution
            self.outputPath = outputPath
            
        }
    }
}
