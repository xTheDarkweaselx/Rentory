//
//  DocumentTypePickerView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct DocumentTypePickerView: View {
    @Binding var selectedType: DocumentType

    var body: some View {
        Picker("Document type", selection: $selectedType) {
            ForEach(DocumentType.allCases, id: \.self) { type in
                Text(type.rawValue).tag(type)
            }
        }
    }
}
