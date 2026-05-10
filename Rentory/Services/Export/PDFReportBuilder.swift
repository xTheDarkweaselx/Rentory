//
//  PDFReportBuilder.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation
import CoreGraphics
import CoreText

struct PDFReportBuilder {
    private let fileStorageService: FileStorageService
    private let dateFormatter: DateFormatter

    init(fileStorageService: FileStorageService = FileStorageService()) {
        self.fileStorageService = fileStorageService

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateFormat = "d MMM yyyy"
        self.dateFormatter = formatter
    }

    init(photoStorageService: PhotoStorageService) {
        self.init()
    }

    func buildReportData(for propertyPack: PropertyPack, options: ExportOptions) throws -> Data {
        try buildReportData(for: PDFReportSnapshot(propertyPack: propertyPack), options: options)
    }

    func buildReportData(for snapshot: PDFReportSnapshot, options: ExportOptions) throws -> Data {
        let content = makeReportSections(for: snapshot, options: options)
        let pageBounds = CGRect(x: 0, y: 0, width: 595, height: 842)
        let data = NSMutableData()
        var mediaBox = pageBounds

        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw PDFExportError.unableToCreateReport
        }

        var pageNumber = 1

        for section in content {
            context.beginPDFPage(nil)
            draw(section: section, in: pageBounds, context: context, pageNumber: pageNumber)
            context.endPDFPage()
            pageNumber += 1
        }

        context.closePDF()
        return data as Data
    }

    func makeReportSections(for propertyPack: PropertyPack, options: ExportOptions) -> [PDFReportSection] {
        makeReportSections(for: PDFReportSnapshot(propertyPack: propertyPack), options: options)
    }

    func makeReportSections(for snapshot: PDFReportSnapshot, options: ExportOptions) -> [PDFReportSection] {
        let enforcedOptions = sanitised(options)
        var sections: [PDFReportSection] = []

        sections.append(makeCoverSection(for: snapshot, options: enforcedOptions))
        sections.append(makePropertySummarySection(for: snapshot, options: enforcedOptions))

        if enforcedOptions.includeRooms {
            sections.append(makeRoomsSection(for: snapshot, options: enforcedOptions))
        }

        if enforcedOptions.includePhotos {
            sections.append(makePhotosSection(for: snapshot))
        }

        if enforcedOptions.includeDocumentsList {
            sections.append(makeDocumentsSection(for: snapshot))
        }

        if enforcedOptions.includeTimeline {
            sections.append(makeTimelineSection(for: snapshot))
        }

        sections.append(
            PDFReportSection(
                title: "Important",
                lines: [ReportDisclaimerView.reportText]
            )
        )

        return sections
    }

    private func sanitised(_ options: ExportOptions) -> ExportOptions {
        var options = options
        options.includeDisclaimer = true
        return options
    }

    private func makeCoverSection(for propertyPack: PDFReportSnapshot, options: ExportOptions) -> PDFReportSection {
        var lines = ["Date created: \(dateFormatter.string(from: .now))"]

        if options.includePropertyName {
            lines.append("Property name: \(propertyPack.nickname)")
        }

        if options.includeTownOrPostcode, let location = townOrPostcode(for: propertyPack) {
            lines.append(location)
        }

        if options.includeFullAddress, let address = fullAddress(for: propertyPack) {
            lines.append(address)
        }

        if options.includeTenancyDates, let tenancy = tenancyDates(for: propertyPack) {
            lines.append("Tenancy dates: \(tenancy)")
        }

        return PDFReportSection(title: "Rentory report", lines: lines)
    }

    private func makePropertySummarySection(for propertyPack: PDFReportSnapshot, options: ExportOptions) -> PDFReportSection {
        var lines: [String] = []

        if options.includePropertyName {
            lines.append("Property name: \(propertyPack.nickname)")
        }

        if options.includeTownOrPostcode, let location = townOrPostcode(for: propertyPack) {
            lines.append(location)
        }

        if options.includeFullAddress, let address = fullAddress(for: propertyPack) {
            lines.append(address)
        }

        if options.includeTenancyDates, let tenancy = tenancyDates(for: propertyPack) {
            lines.append("Tenancy dates: \(tenancy)")
        }

        if options.includeLandlordOrAgentDetails {
            if let name = trimmed(propertyPack.landlordOrAgentName) {
                lines.append("Landlord or letting agent: \(name)")
            }

            if let email = trimmed(propertyPack.landlordOrAgentEmail) {
                lines.append("Email: \(email)")
            }
        }

        if options.includeDepositDetails {
            if let scheme = trimmed(propertyPack.depositSchemeName) {
                lines.append("Deposit scheme: \(scheme)")
            }

            if let reference = trimmed(propertyPack.depositReference) {
                lines.append("Deposit reference: \(reference)")
            }
        }

        if lines.isEmpty {
            lines.append("No property details were selected for this part of the report.")
        }

        return PDFReportSection(title: "Property summary", lines: lines)
    }

    private func makeRoomsSection(for propertyPack: PDFReportSnapshot, options: ExportOptions) -> PDFReportSection {
        let rooms = propertyPack.rooms.sorted { $0.sortOrder < $1.sortOrder }
        var lines: [String] = []

        for room in rooms {
            lines.append(room.name)

            for item in room.checklistItems.sorted(by: { $0.sortOrder < $1.sortOrder }) {
                lines.append("• \(item.title)")
                lines.append("  Move-in: \(item.moveInCondition.rawValue)")
                lines.append("  Move-out: \(item.moveOutCondition.rawValue)")

                if options.includeChecklistNotes, let moveInNotes = trimmed(item.moveInNotes) {
                    lines.append("  Move-in notes: \(moveInNotes)")
                }

                if options.includeChecklistNotes, let moveOutNotes = trimmed(item.moveOutNotes) {
                    lines.append("  Move-out notes: \(moveOutNotes)")
                }
            }
        }

        if lines.isEmpty {
            lines.append("No rooms have been added yet.")
        }

        return PDFReportSection(title: "Rooms and checklist", lines: lines)
    }

    private func makePhotosSection(for propertyPack: PDFReportSnapshot) -> PDFReportSection {
        var lines: [String] = []
        var photos: [PDFReportPhotoEntry] = []

        for room in propertyPack.rooms.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            for item in room.checklistItems.sorted(by: { $0.sortOrder < $1.sortOrder }) {
                for photo in item.photos.sorted(by: { $0.sortOrder < $1.sortOrder }) where photo.includeInExport {
                    var details = ["\(room.name) • \(item.title)", photo.evidencePhase.rawValue]
                    if let caption = trimmed(photo.caption) {
                        details.append(caption)
                    }
                    details.append(dateFormatter.string(from: photo.capturedAt))

                    let image = try? thumbnailImage(for: photo.localFileName)
                    photos.append(PDFReportPhotoEntry(image: image, details: details))
                }
            }
        }

        if photos.isEmpty {
            lines.append("No photos were included.")
        }

        return PDFReportSection(title: "Photos", lines: lines, photos: photos)
    }

    private func makeDocumentsSection(for propertyPack: PDFReportSnapshot) -> PDFReportSection {
        let documents = propertyPack.documents
            .filter(\.includeInExport)
            .sorted { $0.addedAt > $1.addedAt }

        var lines: [String] = []

        for document in documents {
            var line = "\(document.displayName) • \(document.documentType.rawValue)"
            if let documentDate = document.documentDate {
                line += " • \(dateFormatter.string(from: documentDate))"
            }
            lines.append(line)
        }

        if lines.isEmpty {
            lines.append("No documents were included.")
        }

        return PDFReportSection(title: "Documents list", lines: lines)
    }

    private func makeTimelineSection(for propertyPack: PDFReportSnapshot) -> PDFReportSection {
        let events = propertyPack.timelineEvents
            .filter(\.includeInExport)
            .sorted { $0.eventDate < $1.eventDate }

        var lines: [String] = []

        for event in events {
            var line = "\(dateFormatter.string(from: event.eventDate)) • \(event.title) • \(event.eventType.rawValue)"
            if let notes = trimmed(event.notes) {
                line += " • \(notes)"
            }
            lines.append(line)
        }

        if lines.isEmpty {
            lines.append("No timeline events were included.")
        }

        return PDFReportSection(title: "Timeline", lines: lines)
    }

    private func townOrPostcode(for propertyPack: PDFReportSnapshot) -> String? {
        let parts = [trimmed(propertyPack.townCity), trimmed(propertyPack.postcode)].compactMap { $0 }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: " • ")
    }

    private func fullAddress(for propertyPack: PDFReportSnapshot) -> String? {
        let parts = [
            trimmed(propertyPack.addressLine1),
            trimmed(propertyPack.addressLine2),
            trimmed(propertyPack.townCity),
            trimmed(propertyPack.postcode),
        ].compactMap { $0 }

        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: ", ")
    }

    private func tenancyDates(for propertyPack: PDFReportSnapshot) -> String? {
        guard let startDate = propertyPack.tenancyStartDate else {
            return nil
        }

        let startText = dateFormatter.string(from: startDate)
        let endText = propertyPack.tenancyEndDate.map { dateFormatter.string(from: $0) } ?? "Ongoing"
        return "\(startText) to \(endText)"
    }

    private func trimmed(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }

    private func thumbnailImage(for fileName: String) throws -> CGImage {
        let photoURL = try fileStorageService.urlForEvidencePhoto(fileName: fileName)
        return try PhotoStorageService.makeThumbnailCGImage(for: photoURL, maxPixelSize: 900)
    }

    private func draw(section: PDFReportSection, in pageBounds: CGRect, context: CGContext, pageNumber: Int) {
        let margin: CGFloat = 40
        let contentWidth = pageBounds.width - (margin * 2)
        var topOffset: CGFloat = margin

        let titleAttributes = textAttributes(fontSize: 24, isBold: true)
        let bodyAttributes = textAttributes(fontSize: 12, isBold: false)
        let captionAttributes = textAttributes(fontSize: 10, isBold: false)

        topOffset += drawText(
            section.title,
            in: CGRect(x: margin, y: topOffset, width: contentWidth, height: 36),
            pageHeight: pageBounds.height,
            attributes: titleAttributes,
            context: context
        ) + 12

        for line in section.lines {
            topOffset += drawText(
                line,
                in: CGRect(x: margin, y: topOffset, width: contentWidth, height: 1000),
                pageHeight: pageBounds.height,
                attributes: bodyAttributes,
                context: context
            ) + 8
        }

        if !section.photos.isEmpty {
            topOffset += 8
            let imageWidth = (contentWidth - 12) / 2
            let imageHeight: CGFloat = 120

            for (index, photo) in section.photos.enumerated() {
                let column = index % 2
                let row = index / 2
                let xPosition = margin + CGFloat(column) * (imageWidth + 12)
                let blockTop = topOffset + CGFloat(row) * (imageHeight + 60)

                let frame = CGRect(x: xPosition, y: blockTop, width: imageWidth, height: imageHeight)
                let pdfFrame = convertToPDFRect(frame, pageHeight: pageBounds.height)
                context.setFillColor(CGColor(gray: 0.95, alpha: 1))
                context.fill(pdfFrame)

                if let image = photo.image {
                    draw(image: image, in: frame, pageHeight: pageBounds.height, context: context)
                } else {
                    _ = drawText(
                        "Photo unavailable",
                        in: frame.insetBy(dx: 12, dy: 12),
                        pageHeight: pageBounds.height,
                        attributes: captionAttributes,
                        context: context
                    )
                }

                _ = drawText(
                    photo.details.joined(separator: " • "),
                    in: CGRect(x: xPosition, y: frame.maxY + 6, width: imageWidth, height: 48),
                    pageHeight: pageBounds.height,
                    attributes: captionAttributes,
                    context: context
                )
            }
        }

        _ = drawText(
            "Page \(pageNumber)",
            in: CGRect(x: margin, y: pageBounds.height - margin, width: contentWidth, height: 16),
            pageHeight: pageBounds.height,
            attributes: captionAttributes,
            context: context
        )
    }

    private func textAttributes(fontSize: CGFloat, isBold: Bool) -> [NSAttributedString.Key: Any] {
        let fontName = isBold ? "Helvetica-Bold" : "Helvetica"
        let font = CTFontCreateWithName(fontName as CFString, fontSize, nil)
        return [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(gray: 0.12, alpha: 1),
        ]
    }

    @discardableResult
    private func drawText(
        _ text: String,
        in rect: CGRect,
        pageHeight: CGFloat,
        attributes: [NSAttributedString.Key: Any],
        context: CGContext
    ) -> CGFloat {
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        let suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter,
            CFRange(location: 0, length: attributedString.length),
            nil,
            CGSize(width: rect.width, height: rect.height),
            nil
        )
        let textHeight = ceil(suggestedSize.height)
        let textRect = CGRect(
            x: rect.minX,
            y: rect.minY,
            width: rect.width,
            height: min(rect.height, max(textHeight, 16))
        )
        let frameRect = convertToPDFRect(textRect, pageHeight: pageHeight)

        let path = CGPath(rect: frameRect, transform: nil)
        let frame = CTFramesetterCreateFrame(
            framesetter,
            CFRange(location: 0, length: attributedString.length),
            path,
            nil
        )

        CTFrameDraw(frame, context)
        return textRect.height
    }

    private func convertToPDFRect(_ rect: CGRect, pageHeight: CGFloat) -> CGRect {
        CGRect(x: rect.minX, y: pageHeight - rect.minY - rect.height, width: rect.width, height: rect.height)
    }

    private func draw(image: CGImage, in rect: CGRect, pageHeight: CGFloat, context: CGContext) {
        let imageSize = CGSize(width: image.width, height: image.height)
        guard imageSize.width > 0, imageSize.height > 0 else { return }

        let widthRatio = rect.width / imageSize.width
        let heightRatio = rect.height / imageSize.height
        let scale = min(widthRatio, heightRatio)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let x = rect.minX + (rect.width - size.width) / 2
        let y = rect.minY + (rect.height - size.height) / 2

        context.draw(
            image,
            in: convertToPDFRect(CGRect(origin: CGPoint(x: x, y: y), size: size), pageHeight: pageHeight)
        )
    }
}

struct PDFReportSection {
    let title: String
    let lines: [String]
    var photos: [PDFReportPhotoEntry] = []
}

struct PDFReportPhotoEntry {
    let image: CGImage?
    let details: [String]
}
