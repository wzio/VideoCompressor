import Foundation
import AVFoundation
import UniformTypeIdentifiers
#if !os(macOS)
import MobileCoreServices
#endif

extension AVFileType {
    /// get the preferred file extension for the AVFileType.
    var fileExtension: String {
        if #available(iOS 14.0, macOS 11.0, *) {
            if let utType = UTType(self.rawValue) {
                return utType.preferredFilenameExtension ?? "unknown"
            }
            return "unknown"
        } else {
            if let ext = UTTypeCopyPreferredTagWithClass(self as CFString,
                                                         kUTTagClassFilenameExtension)?.takeRetainedValue() {
                return ext as String
            }
            return "unknown"
        }
    }
}
