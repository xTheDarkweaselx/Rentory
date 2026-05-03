//
//  EvidencePhotoThumbnailView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI
import ImageIO

struct EvidencePhotoThumbnailView: View {
    let photo: EvidencePhoto

    private let photoStorageService = PhotoStorageService()

    @State private var loadedImage: UIImage?
    @State private var isUnavailable = false

    var body: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 10) {
                Group {
                    if let loadedImage {
                        Image(rrImage: loadedImage)
                            .resizable()
                            .scaledToFill()
                    } else if isUnavailable {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(RRColours.cardBackground)

                            Text("Photo unavailable")
                                .font(RRTypography.caption)
                                .foregroundStyle(RRColours.mutedText)
                                .multilineTextAlignment(.center)
                                .padding(12)
                        }
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                if let caption = photo.caption, !caption.isEmpty {
                    Text(caption)
                        .font(RRTypography.footnote)
                        .foregroundStyle(RRColours.primary)
                        .lineLimit(2)
                }

                Text(photo.capturedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(RRTypography.caption)
                    .foregroundStyle(RRColours.mutedText)
            }
        }
        .task(id: photo.localFileName) {
            await loadImage()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Opens this photo.")
    }

    @MainActor
    private func loadImage() async {
        let fileName = photo.localFileName

        if let cachedImage = photoStorageService.cachedThumbnail(for: fileName) {
            loadedImage = cachedImage
            isUnavailable = false
            return
        }

        guard let photoURL = try? FileStorageService().urlForEvidencePhoto(fileName: fileName) else {
            loadedImage = nil
            isUnavailable = true
            return
        }

        let result = await Task.detached(priority: .utility) { () -> CGImage? in
            try? PhotoStorageService.makeThumbnailCGImage(for: photoURL, maxPixelSize: 420)
        }.value

        if let result {
            let image = UIImage.rrImage(from: result, size: CGSize(width: result.width, height: result.height))
            photoStorageService.storeThumbnail(image, for: fileName)
            loadedImage = image
            isUnavailable = false
        } else {
            loadedImage = nil
            isUnavailable = true
        }
    }

    private var accessibilityLabel: String {
        var parts = ["Photo added to this record"]
        if let caption = photo.caption, !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append("With a short note")
        }
        parts.append(photo.evidencePhase.rawValue)
        parts.append(photo.capturedAt.formatted(date: .abbreviated, time: .omitted))
        return parts.joined(separator: ", ")
    }
}
