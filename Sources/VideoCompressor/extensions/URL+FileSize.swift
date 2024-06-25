import Foundation

extension URL {
    /// File url video memory footprint.
    /// Remote url will throw error.
    /// - Returns: memory size
    func fileSize() throws -> Int64 {
        guard isFileURL else { throw NSError(domain: "URL is not a file URL", code: 1, userInfo: nil) }
        let attribute = try FileManager.default.attributesOfItem(atPath: path)
        if let size = attribute[FileAttributeKey.size] as? NSNumber {
            return size.int64Value
        } else {
            throw NSError(domain: "Failed to get file size", code: 2, userInfo: nil)
        }
    }
    
    /// File url video memory footprint.
    /// Remote url will throw error.
    /// - Returns: memory size as a string
    func fileSizeAsString(allowedUnits: ByteCountFormatter.Units = [.useMB]) -> String {
        do {
            let size = try fileSize()
            let byteCountFormatter = ByteCountFormatter()
            byteCountFormatter.allowedUnits = allowedUnits
            byteCountFormatter.countStyle = .file
            return byteCountFormatter.string(fromByteCount: size)
        } catch {
            return "unknown size"
        }
    }
}
