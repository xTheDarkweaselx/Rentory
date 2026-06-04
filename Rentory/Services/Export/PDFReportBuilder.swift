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
    private let currencyFormatter: NumberFormatter

    init(fileStorageService: FileStorageService = FileStorageService()) {
        self.fileStorageService = fileStorageService

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateFormat = "d MMM yyyy"
        self.dateFormatter = formatter

        let currency = NumberFormatter()
        currency.locale = Locale(identifier: "en_GB")
        currency.numberStyle = .currency
        currency.maximumFractionDigits = 2
        currency.minimumFractionDigits = 0
        self.currencyFormatter = currency
    }

    init(photoStorageService: PhotoStorageService) {
        self.init()
    }

    func buildReportData(for propertyPack: PropertyPack, options: ExportOptions) throws -> Data {
        try buildReportData(for: PDFReportSnapshot(propertyPack: propertyPack), options: options)
    }

    func buildReportData(for snapshot: PDFReportSnapshot, options: ExportOptions) throws -> Data {
        let content = makeReportSections(for: snapshot, options: options).flatMap(paginatedSections)
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
        var sections: [PDFReportSection] = []

        sections.append(makeCoverSection(for: snapshot, options: options))
        sections.append(makePropertySummarySection(for: snapshot, options: options))

        if options.includeTenancies, !snapshot.tenancies.isEmpty {
            sections.append(makeTenanciesSection(for: snapshot))
        }

        if options.includeRooms {
            sections.append(makeRoomsSection(for: snapshot, options: options))
        }

        if options.includePhotos {
            sections.append(makePhotosSection(for: snapshot, options: options))
        }

        if options.includeDocumentsList {
            sections.append(makeDocumentsSection(for: snapshot))
        }

        if options.includeTimeline {
            sections.append(makeTimelineSection(for: snapshot))
        }

        if options.includeReminders, !snapshot.reminders.isEmpty {
            sections.append(makeRemindersSection(for: snapshot))
        }

        sections.append(
            PDFReportSection(
                title: "Important",
                lines: [ReportDisclaimerView.reportText]
            )
        )

        return sections
    }

    private func paginatedSections(_ section: PDFReportSection) -> [PDFReportSection] {
        let textPages = section.lines.chunked(into: 26)
        let photoPages = section.photos.chunked(into: 6)
        var pages: [PDFReportSection] = []

        if textPages.isEmpty && photoPages.isEmpty {
            return [section]
        }

        for (index, lines) in textPages.enumerated() {
            pages.append(
                PDFReportSection(
                    title: continuedTitle(section.title, pageIndex: index),
                    lines: lines
                )
            )
        }

        for (index, photos) in photoPages.enumerated() {
            pages.append(
                PDFReportSection(
                    title: continuedTitle(section.title, pageIndex: pages.isEmpty ? index : index + 1),
                    lines: pages.isEmpty && section.lines.isEmpty ? section.lines : [],
                    photos: photos
                )
            )
        }

        return pages
    }

    private func continuedTitle(_ title: String, pageIndex: Int) -> String {
        pageIndex == 0 ? title : "\(title) (continued)"
    }

    private func makeCoverSection(for propertyPack: PDFReportSnapshot, options: ExportOptions) -> PDFReportSection {
        var lines = ["Date created: \(dateFormatter.string(from: .now))"]

        if options.reportType != .fullRecord {
            lines.append("Report type: \(options.reportType.title) — \(options.reportType.summary)")
        }

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

        return PDFReportSection(title: options.reportType.coverTitle, lines: lines)
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

        // A check-out report generated before any move-out condition is
        // recorded would otherwise read as a wall of "Not checked" — say so
        // plainly rather than letting it look like a completed inspection.
        if options.reportType == .checkOut, !rooms.isEmpty,
           !rooms.contains(where: { room in
               room.checklistItems.contains { $0.moveOutCondition.contributesToAggregate }
           }) {
            lines.append("No move-out condition has been recorded yet — this report reflects move-in data only.")
        }

        for room in rooms {
            let items = room.checklistItems.sorted(by: { $0.sortOrder < $1.sortOrder })
            let summary = ReportConditionSummary(
                conditionPairs: items.map { (moveIn: $0.moveInCondition, moveOut: $0.moveOutCondition) }
            )

            lines.append(room.name)
            roomSummaryLine(for: options.reportType, summary: summary).map { lines.append($0) }

            for item in items {
                lines.append(contentsOf: itemLines(for: item, options: options))
            }
        }

        if lines.isEmpty {
            lines.append("No rooms have been added yet.")
        }

        return PDFReportSection(title: roomsSectionTitle(for: options.reportType), lines: lines)
    }

    private func roomsSectionTitle(for reportType: ReportType) -> String {
        switch reportType {
        case .checkIn: return "Rooms and condition (check-in)"
        case .checkOut: return "Rooms and condition (check-out)"
        case .fullRecord: return "Rooms and checklist"
        }
    }

    /// A one-line condition rollup printed under each room name. The full
    /// record keeps its original item-only layout (no rollup).
    private func roomSummaryLine(for reportType: ReportType, summary: ReportConditionSummary) -> String? {
        switch reportType {
        case .checkIn:
            return "  Overall condition: \(summary.moveInAggregate.rawValue)"
        case .checkOut:
            var line = "  Overall condition: \(summary.moveOutAggregate.rawValue)"
            if summary.worsenedItemCount > 0 {
                let noun = summary.worsenedItemCount == 1 ? "item" : "items"
                line += " · \(summary.worsenedItemCount) \(noun) worse than at move-in"
            }
            return line
        case .fullRecord:
            return nil
        }
    }

    private func itemLines(for item: PDFReportChecklistItemSnapshot, options: ExportOptions) -> [String] {
        var lines = ["• \(item.title)"]

        switch options.reportType {
        case .checkIn:
            lines.append("  Condition: \(item.moveInCondition.rawValue)")
            if options.includeChecklistNotes, let notes = trimmed(item.moveInNotes) {
                lines.append("  Notes: \(notes)")
            }

        case .checkOut:
            // Em-dash (not a "→" arrow) — the arrow glyph isn't in the
            // report font and would render in a substituted typeface.
            var conditionLine = "  Move-in: \(item.moveInCondition.rawValue) — Move-out: \(item.moveOutCondition.rawValue)"
            if ReportConditionSummary.isWorsening(from: item.moveInCondition, to: item.moveOutCondition) {
                conditionLine += "  (worse than move-in)"
            } else if item.moveInCondition.contributesToAggregate, !item.moveOutCondition.contributesToAggregate {
                // Had a move-in baseline but wasn't re-assessed at move-out —
                // flag it so an unchecked item doesn't read as "nothing wrong".
                conditionLine += "  (not re-checked at move-out)"
            }
            lines.append(conditionLine)
            if options.includeChecklistNotes, let notes = trimmed(item.moveOutNotes) {
                lines.append("  Move-out notes: \(notes)")
            }

        case .fullRecord:
            lines.append("  Move-in: \(item.moveInCondition.rawValue)")
            lines.append("  Move-out: \(item.moveOutCondition.rawValue)")
            if options.includeChecklistNotes, let moveInNotes = trimmed(item.moveInNotes) {
                lines.append("  Move-in summary: \(moveInNotes)")
            }
            if options.includeChecklistNotes, let moveOutNotes = trimmed(item.moveOutNotes) {
                lines.append("  Move-out summary: \(moveOutNotes)")
            }
        }

        return lines
    }

    private func makePhotosSection(for propertyPack: PDFReportSnapshot, options: ExportOptions) -> PDFReportSection {
        var lines: [String] = []
        var photos: [PDFReportPhotoEntry] = []

        for room in propertyPack.rooms.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            for item in room.checklistItems.sorted(by: { $0.sortOrder < $1.sortOrder }) {
                for photo in item.photos.sorted(by: { $0.sortOrder < $1.sortOrder })
                    where photo.includeInExport && photoBelongs(photo, in: options.reportType) {
                    var details = ["\(room.name) • \(item.title)", photo.evidencePhase.rawValue]
                    if let caption = trimmed(photo.caption) {
                        details.append(caption)
                    }
                    // Only present the date as a capture date when it is one.
                    // Unconfirmed photos (no readable capture date, defaulted
                    // to import time) are labelled "Added" so the report never
                    // implies an invented capture date.
                    let dateLabel = photo.captureDateIsConfirmed ? "Taken" : "Added"
                    details.append("\(dateLabel) \(dateFormatter.string(from: photo.capturedAt))")

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

    /// A check-in report shouldn't carry move-out photos (they don't exist
    /// yet at move-in); check-out and the full record include every phase.
    private func photoBelongs(_ photo: PDFReportEvidencePhotoSnapshot, in reportType: ReportType) -> Bool {
        switch reportType {
        case .checkIn: return photo.evidencePhase != .moveOut
        case .checkOut, .fullRecord: return true
        }
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

    private func makeTenanciesSection(for snapshot: PDFReportSnapshot) -> PDFReportSection {
        let tenancies = snapshot.tenancies.sorted { $0.startDate > $1.startDate }
        var lines: [String] = []

        for tenancy in tenancies {
            let dateRange = tenancyDateRange(startDate: tenancy.startDate, endDate: tenancy.endDate)
            lines.append("\(tenancy.status.rawValue) • \(tenancy.tenancyType.rawValue) • \(dateRange)")

            if let rent = tenancy.rentAmount {
                let frequency = tenancy.rentFrequency?.rawValue ?? ""
                lines.append("  Rent: \(formattedCurrency(rent)) \(frequency)".trimmingCharacters(in: .whitespaces))
            }

            if let deposit = tenancy.depositAmount {
                var line = "  Deposit: \(formattedCurrency(deposit))"
                if let scheme = trimmed(tenancy.depositSchemeName) {
                    line += " • Scheme: \(scheme)"
                }
                if let reference = trimmed(tenancy.depositReference) {
                    line += " • Ref: \(reference)"
                }
                lines.append(line)
            }

            for tenant in tenancy.tenants.sorted(by: { $0.sortOrder < $1.sortOrder }) {
                var line = "  Tenant: \(tenant.name)"
                if let email = trimmed(tenant.email) {
                    line += " • \(email)"
                }
                if let phone = trimmed(tenant.phone) {
                    line += " • \(phone)"
                }
                lines.append(line)
            }

            if let notes = trimmed(tenancy.notes) {
                lines.append("  Notes: \(notes)")
            }
        }

        if lines.isEmpty {
            lines.append("No tenancies have been added yet.")
        }

        return PDFReportSection(title: "Tenancies", lines: lines)
    }

    private func makeRemindersSection(for snapshot: PDFReportSnapshot) -> PDFReportSection {
        let outstanding = snapshot.reminders
            .filter { !$0.isCompleted }
            .sorted { lhs, rhs in
                switch (lhs.dueDate, rhs.dueDate) {
                case let (l?, r?): return l < r
                case (.some, .none): return true
                case (.none, .some): return false
                case (.none, .none): return false
                }
            }
        let completed = snapshot.reminders
            .filter(\.isCompleted)
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }

        var lines: [String] = []

        if !outstanding.isEmpty {
            lines.append("Outstanding")
            for reminder in outstanding {
                let dueText = reminder.dueDate.map(dateFormatter.string(from:)) ?? "No due date"
                var line = "• \(dueText) • \(reminder.title) • \(reminder.kind.rawValue) • \(reminder.priority.rawValue) priority"
                if let notes = trimmed(reminder.notes) {
                    line += " • \(notes)"
                }
                lines.append(line)
            }
        }

        if !completed.isEmpty {
            if !outstanding.isEmpty { lines.append("") }
            lines.append("Completed")
            for reminder in completed {
                let completedText = reminder.completedAt.map(dateFormatter.string(from:)) ?? ""
                lines.append("• \(completedText) • \(reminder.title) • \(reminder.kind.rawValue)")
            }
        }

        if lines.isEmpty {
            lines.append("No reminders were included.")
        }

        return PDFReportSection(title: "Reminders", lines: lines)
    }

    private func tenancyDateRange(startDate: Date, endDate: Date?) -> String {
        let startText = dateFormatter.string(from: startDate)
        if let endDate {
            return "\(startText) to \(dateFormatter.string(from: endDate))"
        }
        return "From \(startText)"
    }

    private func formattedCurrency(_ value: Double) -> String {
        currencyFormatter.string(from: NSNumber(value: value)) ?? String(format: "£%.2f", value)
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

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map { startIndex in
            Array(self[startIndex..<Swift.min(startIndex + size, count)])
        }
    }
}
