//
//  ReportPDFGenerationTests.swift
//  RentoryTests
//
//  End-to-end smoke test of the PDF pipeline (the real CGContext drawing,
//  image decoding and pagination), which the section-level builder tests
//  don't exercise. Generates a check-out report containing before/after
//  photo pairs and asserts a valid, non-trivial PDF comes out.
//

import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

@testable import Rentory

struct ReportPDFGenerationTests {
    @Test @MainActor func checkOutReportWithPhotosGeneratesValidPDF() async throws {
        let storage = FileStorageService()

        func savePhoto(_ r: Double, _ g: Double, _ b: Double) throws -> String {
            let ctx = CGContext(
                data: nil, width: 240, height: 180, bitsPerComponent: 8, bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )!
            ctx.setFillColor(CGColor(red: r, green: g, blue: b, alpha: 1))
            ctx.fill(CGRect(x: 0, y: 0, width: 240, height: 180))
            let cgImage = ctx.makeImage()!
            let data = NSMutableData()
            let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil)!
            CGImageDestinationAddImage(destination, cgImage, nil)
            CGImageDestinationFinalize(destination)
            return try storage.saveImageData(data as Data, fileExtension: "jpg")
        }

        let oven = ChecklistItemRecord(
            title: "Oven",
            sortOrder: 0,
            moveInConditionRawValue: EvidenceCondition.good.rawValue,
            moveOutConditionRawValue: EvidenceCondition.damaged.rawValue,
            photos: [
                EvidencePhoto(localFileName: try savePhoto(0.40, 0.78, 0.45), phase: .moveIn, captureDateIsConfirmed: true, sortOrder: 0),
                EvidencePhoto(localFileName: try savePhoto(0.85, 0.30, 0.30), phase: .moveOut, captureDateIsConfirmed: true, sortOrder: 0),
            ]
        )
        let room = RoomRecord(name: "Kitchen", type: .kitchen, sortOrder: 0, checklistItems: [oven])
        let pack = PropertyPack(nickname: "Home", rooms: [room])

        let url = try await PDFExportService().createReport(
            for: PDFReportSnapshot(propertyPack: pack),
            options: ExportOptions(reportType: .checkOut)
        )

        let data = try Data(contentsOf: url)
        #expect(data.starts(with: Array("%PDF".utf8))) // valid PDF header
        #expect(data.count > 2000) // a real multi-page report, not an empty stub
    }
}
