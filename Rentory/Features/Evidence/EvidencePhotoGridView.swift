//
//  EvidencePhotoGridView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct EvidencePhotoGridView: View {
    let title: String
    let photos: [EvidencePhoto]

    private let gridColumns = [
        GridItem(.adaptive(minimum: 180, maximum: 260), spacing: 12),
    ]

    private var sortedPhotos: [EvidencePhoto] {
        photos.sorted {
            if $0.sortOrder == $1.sortOrder {
                return $0.capturedAt < $1.capturedAt
            }

            return $0.sortOrder < $1.sortOrder
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(RRTypography.headline)
                .foregroundStyle(RRColours.primary)
                .accessibilityAddTraits(.isHeader)

            if sortedPhotos.isEmpty {
                RREmptyStateView(
                    symbolName: "photo.on.rectangle",
                    title: "No photos yet",
                    message: "Add photos when you want a clearer record of this item."
                )
            } else {
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(sortedPhotos) { photo in
                        NavigationLink {
                            EvidencePhotoDetailView(photo: photo)
                        } label: {
                            EvidencePhotoThumbnailView(photo: photo)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
