//
//  WatchTheme.swift  (RentoryWatch target)
//  Rentory
//
//  Watch-sized mirror of the RR* tokens. Smaller type sizes than the
//  iPhone widget mirror; same urgency tinting so the dashboard,
//  widgets, and complications all feel like one system.
//

import SwiftUI

enum WatchTheme {
    enum Palette {
        static let primary = Color.primary
        static let mutedText = Color.secondary
        static let secondary = Color(red: 0.65, green: 0.55, blue: 0.95)
        static let success = Color(red: 0.36, green: 0.82, blue: 0.54)
        static let warning = Color(red: 0.96, green: 0.66, blue: 0.23)
        static let danger = Color(red: 0.93, green: 0.38, blue: 0.38)
    }

    enum Typography {
        static let title = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 14, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 13, weight: .regular, design: .rounded)
        static let footnote = Font.system(size: 11, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 10, weight: .medium, design: .rounded)
    }

    static func urgencyTint(for daysUntilDue: Int) -> Color {
        switch daysUntilDue {
        case ..<0: return Palette.danger
        case 0...3: return Palette.warning
        case 4...14: return Palette.secondary
        default: return Palette.success
        }
    }

    static func daysUntilDue(for date: Date, calendar: Calendar = .current) -> Int {
        let now = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: now, to: target).day ?? 0
    }

    static func relativeDescription(for date: Date) -> String {
        let days = daysUntilDue(for: date)
        switch days {
        case ..<0:
            let pastDays = -days
            return pastDays == 1 ? "Overdue 1 day" : "Overdue \(pastDays) days"
        case 0: return "Due today"
        case 1: return "Tomorrow"
        default: return "In \(days)d"
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
        default: return "checklist"
        }
    }
}
