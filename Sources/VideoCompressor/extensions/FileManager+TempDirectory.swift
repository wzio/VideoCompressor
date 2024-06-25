import Foundation

extension FileManager {
    enum CreateTempDirectoryError: Error, LocalizedError {
        case fileExsisted
        
        var errorDescription: String? {
            switch self {
            case .fileExsisted:
                return "File exsisted"
            }
        }
    }
    /// Get temp directory. If it exsists, return it, else create it.
    /// - Parameter pathComponent: path to append to temp directory.
    /// - Throws: error when create temp directory.
    /// - Returns: temp directory location.
    /// - Warning: Every time you call this function will return a different directory.
    static func tempDirectory(with pathComponent: String = ProcessInfo.processInfo.globallyUniqueString) -> URL {
        var tempURL: URL
        
        let cacheURL = FileManager.default.temporaryDirectory
        if let url = try? FileManager.default.url(for: .itemReplacementDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: cacheURL,
                                                  create: true) {
            tempURL = url
        } else {
            tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
        }
        
        tempURL.appendPathComponent(pathComponent)
        
        if !FileManager.default.fileExists(atPath: tempURL.path) {
            do {
                try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(pathComponent, isDirectory: true)
            }
        }
        return tempURL
    }
    
    func isValidDirectory(atPath path: URL) -> Bool {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: path.path, isDirectory:&isDir) {
            return isDir.boolValue
        } else {
            return false
        }
    }
}
