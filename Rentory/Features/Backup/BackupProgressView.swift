//
//  BackupProgressView.swift
//  Rentory
//
//  Created by OpenAI on 02/05/2026.
//

import SwiftUI

struct BackupProgressView: View {
    let title: String
    let message: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.12)
                .ignoresSafeArea()

            RRLoadingView(title: title, message: message)
                .padding(24)
        }
    }
}
