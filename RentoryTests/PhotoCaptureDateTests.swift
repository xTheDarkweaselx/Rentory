//
//  PhotoCaptureDateTests.swift
//  RentoryTests
//
//  Verifies EXIF capture-date parsing — the timezone-sensitive,
//  format-fussy part of dating photo evidence to when it was actually
//  taken rather than when it was imported.
//

import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

@testable import Rentory

struct PhotoCaptureDateTests {
    private func components(_ date: Date, in timeZoneID: String) -> DateComponents {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZoneID)!
        return calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
    }

    @Test func parsesExifDateAtUTC() {
        let date = PhotoCaptureDate.parseExifDate("2026:01:15 09:30:45", offset: "+00:00")
        #expect(date != nil)

        let comps = components(date!, in: "UTC")
        #expect(comps.year == 2026)
        #expect(comps.month == 1)
        #expect(comps.day == 15)
        #expect(comps.hour == 9)
        #expect(comps.minute == 30)
        #expect(comps.second == 45)
    }

    @Test func honoursPositiveOffset() {
        // "+01:00" means the wall-clock time is one hour ahead of UTC,
        // so 09:30 local resolves to 08:30 UTC.
        let utc = PhotoCaptureDate.parseExifDate("2026:01:15 09:30:00", offset: "+00:00")!
        let plusOne = PhotoCaptureDate.parseExifDate("2026:01:15 09:30:00", offset: "+01:00")!
        #expect(plusOne == utc.addingTimeInterval(-3600))
    }

    @Test func honoursNegativeOffset() {
        let utc = PhotoCaptureDate.parseExifDate("2026:01:15 09:30:00", offset: "+00:00")!
        let minusFive = PhotoCaptureDate.parseExifDate("2026:01:15 09:30:00", offset: "-05:00")!
        #expect(minusFive == utc.addingTimeInterval(5 * 3600))
    }

    @Test func returnsNilForMalformedInput() {
        #expect(PhotoCaptureDate.parseExifDate("not a date") == nil)
        #expect(PhotoCaptureDate.parseExifDate("") == nil)
        #expect(PhotoCaptureDate.parseExifDate("   ") == nil)
        // The all-zero EXIF sentinel means "no date", not year zero.
        #expect(PhotoCaptureDate.parseExifDate("0000:00:00 00:00:00") == nil)
    }

    @Test func fallsBackToCurrentZoneWithoutOffset() {
        let date = PhotoCaptureDate.parseExifDate("2026:06:01 14:00:00")
        #expect(date != nil)

        // With no offset the value is interpreted in the device's zone,
        // so reading it back in that same zone returns the wall-clock time.
        let comps = components(date!, in: TimeZone.current.identifier)
        #expect(comps.year == 2026)
        #expect(comps.month == 6)
        #expect(comps.day == 1)
        #expect(comps.hour == 14)
        #expect(comps.minute == 0)
    }

    @Test func ignoresMalformedOffsetAndFallsBackToDeviceZone() {
        // A malformed offset (missing sign) must not be coerced into a
        // positive zone; it should be ignored, matching the no-offset path.
        let fallback = PhotoCaptureDate.parseExifDate("2026:01:15 09:30:00", offset: nil)
        let malformed = PhotoCaptureDate.parseExifDate("2026:01:15 09:30:00", offset: "01:00")
        #expect(malformed == fallback)
    }

    // MARK: - End-to-end metadata reading

    @Test func readsCaptureDateFromImageMetadata() {
        let data = makeImageData(exifOriginal: "2026:03:10 12:00:00")
        let date = PhotoCaptureDate.captureDate(fromImageData: data)
        #expect(date != nil)
        #expect(date == PhotoCaptureDate.parseExifDate("2026:03:10 12:00:00"))
    }

    @Test func prefersDateTimeOriginalOverDigitized() {
        let data = makeImageData(
            exifOriginal: "2026:03:10 12:00:00",
            exifDigitized: "2020:01:01 00:00:00"
        )
        let date = PhotoCaptureDate.captureDate(fromImageData: data)
        #expect(date == PhotoCaptureDate.parseExifDate("2026:03:10 12:00:00"))
    }

    @Test func returnsNilWhenImageHasNoCaptureDate() {
        let data = makeImageData()
        #expect(PhotoCaptureDate.captureDate(fromImageData: data) == nil)
    }

    /// Builds a minimal in-memory JPEG, optionally tagging it with EXIF
    /// capture dates, so the metadata-reading path can be exercised without
    /// shipping a binary fixture.
    private func makeImageData(exifOriginal: String? = nil, exifDigitized: String? = nil) -> Data {
        let context = CGContext(
            data: nil,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        let cgImage = context.makeImage()!

        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            data, UTType.jpeg.identifier as CFString, 1, nil
        )!

        var exif: [CFString: Any] = [:]
        if let exifOriginal { exif[kCGImagePropertyExifDateTimeOriginal] = exifOriginal }
        if let exifDigitized { exif[kCGImagePropertyExifDateTimeDigitized] = exifDigitized }

        var properties: [CFString: Any] = [:]
        if !exif.isEmpty { properties[kCGImagePropertyExifDictionary] = exif }

        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
        CGImageDestinationFinalize(destination)
        return data as Data
    }
}
