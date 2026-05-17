//
//  DocumentTypePickerView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct DocumentTypePickerView: View {
    @Binding var selectedType: DocumentType
    @AppStorage(RentoryUserProfile.storageKey) private var profileRawValue = RentoryUserProfile.defaultProfile.rawValue

    private var profile: RentoryUserProfile {
        RentoryUserProfile(rawValue: profileRawValue) ?? .defaultProfile
    }

    var body: some View {
        Picker("Document type", selection: $selectedType) {
            ForEach(DocumentType.availableCases(for: profile), id: \.self) { type in
                Text(type.rawValue).tag(type)
            }
        }
    }
}
