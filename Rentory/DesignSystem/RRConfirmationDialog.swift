//
//  RRConfirmationDialog.swift
//  Rentory
//
//  Created by Adam Ibrahim on 01/05/2026.
//

import SwiftUI

extension View {
    func rrConfirmationDialog(
        _ content: RRDialogContent,
        isPresented: Binding<Bool>,
        onConfirm: @escaping () -> Void
    ) -> some View {
        alert(content.title, isPresented: isPresented) {
            Button(content.cancelTitle, role: .cancel) {}
            Button(content.confirmTitle, role: content.confirmRole, action: onConfirm)
        } message: {
            Text(content.message)
        }
    }
}
