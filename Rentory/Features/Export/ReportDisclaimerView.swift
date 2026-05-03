//
//  ReportDisclaimerView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct ReportDisclaimerView: View {
    static let reportText = "This report was created from information, notes, photos and documents added by the user. Rentory helps you organise your own rental records. It does not give legal, financial or tenancy advice."

    var body: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Included with every report")
                    .font(RRTypography.headline)
                    .foregroundStyle(RRColours.primary)

                Text("Rentory creates a report from the information you have added. It does not give legal, financial or tenancy advice.")
                    .font(RRTypography.body)
                    .foregroundStyle(RRColours.mutedText)
            }
        }
    }
}
