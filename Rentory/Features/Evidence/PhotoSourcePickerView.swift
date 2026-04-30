//
//  PhotoSourcePickerView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct PhotoSourcePickerView: View {
    let isCameraAvailable: Bool
    let onTakePhoto: () -> Void
    let onChooseFromPhotos: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            RRSectionHeader(
                title: "Add a photo",
                subtitle: "Choose where this photo belongs in your record."
            )

            VStack(spacing: 12) {
                if isCameraAvailable {
                    RRPrimaryButton(title: "Take a photo", action: onTakePhoto)
                } else {
                    RRCard {
                        Text("Camera is not available on this device.")
                            .font(RRTypography.body)
                            .foregroundStyle(RRColours.mutedText)
                    }
                }

                RRSecondaryButton(title: "Choose from Photos", action: onChooseFromPhotos)
            }
        }
        .padding(20)
    }
}
