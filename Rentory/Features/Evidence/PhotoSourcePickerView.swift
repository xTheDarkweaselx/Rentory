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
        VStack(spacing: 12) {
            if isCameraAvailable {
                RRPrimaryButton(title: "Take a photo", action: onTakePhoto)
            } else {
                RRCard {
                    Text("Camera is not available on this device.")
                        .font(RRTypography.body)
                        .foregroundStyle(RRColours.mutedText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            RRSecondaryButton(title: "Choose from Photos", action: onChooseFromPhotos)

            Text("You can choose more than one from your library.")
                .font(RRTypography.caption)
                .foregroundStyle(RRColours.mutedText)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
