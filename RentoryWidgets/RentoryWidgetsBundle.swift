//
//  RentoryWidgetsBundle.swift
//  RentoryWidgets
//
//  WidgetBundle @main entry. Registers each widget Rentory ships. Adding
//  a new widget = adding it to this bundle list.
//

import SwiftUI
import WidgetKit

@main
struct RentoryWidgetsBundle: WidgetBundle {
    var body: some Widget {
        NextReminderWidget()
        MonthlyFinanceWidget()
        PropertyActionWidget()
    }
}
