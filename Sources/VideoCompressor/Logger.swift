//
//  Logger.swift
//
//
//  Created by kun on 2024/6/21.
//

import UIKit
import OSLog
import AVFoundation

@available(iOS 14.0, *)
extension Logger {
    static let compressor = Logger(subsystem: "com.videocompressor.log", category: "compressor")
}

struct FYLogger {
    
    static func logURL(url: URL) {
        #if DEBUG
        if #available(iOS 14.0, *) {
            let videourlkey = "video url:"
            let sizekey = "video size:"
            Logger.compressor.debug("\(videourlkey, align: .left(columns: 15)) \(url)")
            Logger.compressor.debug("\(sizekey, align: .left(columns: 15)) \(url.fileSizeAsString())")
        }
        #endif
    }
    
    static func logVideoInfo(
        _ videoTrack: AVAssetTrack,
        targetBitrate: Float, targetNominalFrameRate: Float, targetNaturalSize: CGSize,
        setting: [String: Any]
    ) {
        
        if #available(iOS 14.0, *) {
#if DEBUG
            let logger = Logger.compressor
            let bitratekey = "bitrate:"
            let fpskey = "fps:"
            let sizekey = "size:"
            let mediaFormatkey = "mediaFormat:"
            let settingskey = "settings:"
            logger.debug("Video ORIGINAL:")
            logger.debug("\(mediaFormatkey, align: .left(columns: 15)) \(videoTrack.mediaFormat)")
            logger.debug("\(bitratekey, align: .left(columns: 15)) \(videoTrack.estimatedDataRate) b/s")
            logger.debug("\(fpskey, align: .left(columns: 15)) \(videoTrack.nominalFrameRate)")
            logger.debug("\(sizekey, align: .left(columns: 15)) \(videoTrack.naturalSize.debugDescription)")
            
            logger.debug("Video TARGET:")
            logger.debug("\(bitratekey, align: .left(columns: 15)) \(targetBitrate) b/s")
            logger.debug("\(fpskey, align: .left(columns: 15)) \(targetNominalFrameRate)")
            logger.debug("\(sizekey, align: .left(columns: 15)) \(targetNaturalSize.debugDescription)")
            logger.debug("\(settingskey, align: .left(columns: 15)) \(setting.debugDescription)")
#endif
        }
    }
    
    static func logAudioInfo(_ audioTrack: AVAssetTrack, config: VideoCompressor.CompressionConfig, setting: [String: Any]?) {
#if DEBUG
        if #available(iOS 14.0, *) {
            let logger: Logger = Logger.compressor
            let formatidkey = "formatID:"
            let bitratekey = "bitrate:"
            let smapleratekey = "sampleRate:"
            let channelskey = "channels:"
            let settingskey = "settings:"
            let columns = 15
            if let audioFormatDescs = audioTrack.formatDescriptions as? [CMFormatDescription], let formatDescription = audioFormatDescs.first {
                
                logger.debug("Audio ORIGINAL:")
                logger.debug("\(bitratekey, align: .left(columns: columns)) \(audioTrack.estimatedDataRate)")
                if let streamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription) {
                    logger.debug("\(smapleratekey, align: .left(columns: columns)) \(streamBasicDescription.pointee.mSampleRate)")
                    logger.debug("\(channelskey, align: .left(columns: columns)) \(streamBasicDescription.pointee.mChannelsPerFrame)")
                    logger.debug("\(formatidkey, align: .left(columns: columns)) \(streamBasicDescription.pointee.mFormatID)")
                }
                
                logger.debug("Audio TARGET:")
                logger.debug("\(smapleratekey, align: .left(columns: columns)) \(config.audioSampleRate)")
                logger.debug("\(bitratekey, align: .left(columns: columns)) \(config.audioBitrate)")
                logger.debug("\(formatidkey, align: .left(columns: columns)) \(config.audioFormatID)")
                
                logger.debug("\(settingskey, align: .left(columns: columns)) \(setting.debugDescription)")
            }
        }
#endif
    }
    
    static func logComletionInfo(startTime: Date, destination: URL) {
#if DEBUG
        if #available(iOS 14.0, *) {
            let endTime = Date()
            let elapse = endTime.timeIntervalSince(startTime)
            Logger.compressor.debug("******** Compression finished ✅**********")
            Logger.compressor.debug("Compressed video:")
            Logger.compressor.debug("time: \(elapse)")
            Logger.compressor.debug("size: \(destination.fileSizeAsString())")
            Logger.compressor.debug("path: \(destination)")
            Logger.compressor.debug("******************************************")
        }
#endif
    }
}
 
