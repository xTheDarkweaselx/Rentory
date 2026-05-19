//
//  ComplicationTheme.swift  (RentoryWatchComplications target)
//  Rentory
//
//  Tiny token mirror — complications on the watch face have very
//  little room and most surfaces are tinted by the watch face itself,
//  so we keep this as small as possible. Urgency tint thresholds match
//  the iPhone widget + watch app for consistency.
//

import SwiftUI

enum ComplicationTheme {
    static let danger = Color(red: 0.93, green: 0.38, blue: 0.38)
    static let warning = Color(red: 0.96, green: 0.66, blue: 0.23)
    static let success = Color(red: 0.36, green: 0.82, blue: 0.54)
    static let secondary = Color(red: 0.65, green: 0.55, blue: 0.95)

    static func urgencyTint(for daysUntilDue: Int) -> Color {
        switch daysUntilDue {
        case ..<0: return danger
        case 0...3: return warning
        case 4...14: return secondary
        default: return success
        }
    }

    static func daysUntilDue(for date: Date, calendar: Calendar = .current) -> Int {
        let now = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: now, to: target).day ?? 0
    }

    static func relativeShortDescription(for date: Date) -> String {
        let days = daysUntilDue(for: date)
        switch days {
        case ..<0:
            let pastDays = -days
            return pastDays == 1 ? "1d late" : "\(pastDays)d late"
        case 0: return "Today"
        case 1: return "1d"
        default: return "\(days)d"
        }
    }

    static func kindIcon(for rawValue: String) -> String {
        switch rawValue {
        case "Gas safety": return "flame.fill"
        case "Electrical safety (EICR)": return "bolt.fill"
        case "Energy performance (EPC)": return "leaf.fill"
        case "Periodic inspection": return "magnifyingglass.circle.fill"
        case "Tenancy renewal": return "doc.text.fill"
        case "Inspection": return "magnifyingglass"
        case "Repair": return "wrench.and.screwdriver"
        case "Compliance": return "checkmark.shield"
        case "Deposit": return "sterlingsign.circle"
        case "Move-in": return "key"
        case "Move-out": return "rectangle.portrait.and.arrow.right"
        default: return "bell.fill"
        }
    }
}
