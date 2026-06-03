//
//  PhotoCaptureDate.swift
//  Rentory
//
//  Reads the original capture timestamp from an image's embedded
//  metadata (EXIF / TIFF). When a user picks an existing photo from
//  their library, this lets Rentory date the evidence to when the
//  shutter actually fired — not when it was imported into the app.
//  That distinction is what makes a photo credible as a record of the
//  property's condition at a point in time.
//

import Foundation
import ImageIO

enum PhotoCaptureDate {
    /// The original capture timestamp parsed from the image's metadata,
    /// or `nil` when the image carries no usable date. Preference order:
    /// EXIF `DateTimeOriginal` (when the shutter fired) → EXIF
    /// `DateTimeDigitized` → TIFF `DateTime` (file-level).
    static func captureDate(fromImageData data: Data) -> Date? {
        guard
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        else {
            return nil
        }

        if let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any] {
            if let original = exif[kCGImagePropertyExifDateTimeOriginal] as? String,
               let date = parseExifDate(original, offset: exif[kCGImagePropertyExifOffsetTimeOriginal] as? String) {
                return date
            }
            if let digitized = exif[kCGImagePropertyExifDateTimeDigitized] as? String,
               let date = parseExifDate(digitized, offset: exif[kCGImagePropertyExifOffsetTimeDigitized] as? String) {
                return date
            }
        }

        if let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any],
           let dateTime = tiff[kCGImagePropertyTIFFDateTime] as? String,
           let date = parseExifDate(dateTime, offset: nil) {
            return date
        }

        return nil
    }

    /// Parses an EXIF datetime string (`"yyyy:MM:dd HH:mm:ss"`). EXIF
    /// stores local wall-clock time with no zone; when an offset string
    /// (e.g. `"+01:00"`) is present we honour it, otherwise the value is
    /// interpreted in the device's current time zone. Returns `nil` for
    /// empty or malformed input.
    static func parseExifDate(_ string: String, offset: String? = nil) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != "0000:00:00 00:00:00" else { return nil }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.timeZone = timeZone(fromOffset: offset) ?? .current
        formatter.isLenient = false
        return formatter.date(from: trimmed)
    }

    /// Converts an EXIF offset string (`"+01:00"`, `"-05:00"`) into a
    /// `TimeZone`. Returns `nil` when absent or unparseable so the caller
    /// can fall back to the device's current zone.
    private static func timeZone(fromOffset offset: String?) -> TimeZone? {
        guard let offset else { return nil }
        let trimmed = offset.trimmingCharacters(in: .whitespacesAndNewlines)

        // Require a strict EXIF offset — sign, two-digit hours, colon,
        // two-digit minutes (e.g. "+01:00", "-05:30"). Anything else is
        // treated as "no usable offset" so we fall back to the device's
        // current zone rather than coercing a malformed string into a
        // plausible-but-wrong time zone.
        guard trimmed.count == 6,
              let signChar = trimmed.first,
              signChar == "+" || signChar == "-" else {
            return nil
        }

        let parts = trimmed.dropFirst().split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 2,
              parts[0].count == 2, parts[1].count == 2,
              let hours = Int(parts[0]), let minutes = Int(parts[1]),
              hours <= 14, minutes < 60 else {
            return nil
        }

        let sign = signChar == "-" ? -1 : 1
        return TimeZone(secondsFromGMT: sign * (hours * 3600 + minutes * 60))
    }
}
