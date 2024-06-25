import Foundation
import AVFoundation

extension AVAssetTrack {
    var mediaFormat: String {
        var format = ""
        let descriptions = self.formatDescriptions as? [CMFormatDescription]
        guard let descriptions else { return format }
        for (index, formatDesc) in descriptions.enumerated() {
            // Get a string representation of the media type.
            let type =
                CMFormatDescriptionGetMediaType(formatDesc).toString()
            // Get a string representation of the media subtype.
            let subType =
                CMFormatDescriptionGetMediaSubType(formatDesc).toString()
            // Format the string as type/subType, such as vide/avc1 or soun/aac.
            format += "\(type)/\(subType)"
            // Comma-separate if there's more than one format description.
            if index < descriptions.count - 1 {
                format += ","
            }
        }
        return format
    }
}
 
extension FourCharCode {
    // Create a string representation of a FourCC.
    func toString() -> String {
        let bytes: [CChar] = [
            CChar((self >> 24) & 0xff),
            CChar((self >> 16) & 0xff),
            CChar((self >> 8) & 0xff),
            CChar(self & 0xff),
            0
        ]
        let result = String(cString: bytes)
        let characterSet = CharacterSet.whitespaces
        return result.trimmingCharacters(in: characterSet)
    }
}

