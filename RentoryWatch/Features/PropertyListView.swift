//
//  PropertyListView.swift  (RentoryWatch target)
//  Rentory
//
//  Records tab — lists property snapshots scoped to the active profile
//  on the paired iPhone. Each row drills into PropertyDetailView. Kept
//  glanceable: nickname + completion ring + one supplementary line.
//

import SwiftUI

struct PropertyListView: View {
    @EnvironmentObject private var snapshotStore: WatchSnapshotStore

    var body: some View {
        Group {
            if snapshotStore.snapshot.properties.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(snapshotStore.snapshot.properties) { property in
                        NavigationLink(value: property) {
                            row(for: property)
                        }
                    }
                }
                .listStyle(.carousel)
            }
        }
        .navigationTitle("Records")
        .navigationDestination(for: RentorySharedSnapshot.PropertyEntry.self) { property in
            PropertyDetailView(property: property)
        }
    }

    private func row(for property: RentorySharedSnapshot.PropertyEntry) -> some View {
        HStack(alignment: .center, spacing: 10) {
            CompletionRing(percent: property.completionPercent)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if property.isFavourite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(WatchTheme.Palette.warning)
                    }
                    Text(property.nickname)
                        .font(WatchTheme.Typography.headline)
                        .foregroundStyle(WatchTheme.Palette.primary)
                        .lineLimit(1)
                }
                Text(supportingLine(for: property))
                    .font(WatchTheme.Typography.footnote)
                    .foregroundStyle(WatchTheme.Palette.mutedText)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }

    private func supportingLine(for property: RentorySharedSnapshot.PropertyEntry) -> String {
        if let action = property.nextActionTitle {
            return action
        }
        if let tenant = property.primaryTenantName {
            return "Tenant: \(tenant)"
        }
        return property.completionStatusTitle
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "house.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(WatchTheme.Palette.secondary)
            Text("No records yet")
                .font(WatchTheme.Typography.title)
            Text("Open Rentory on your iPhone to add a property.")
                .font(WatchTheme.Typography.footnote)
                .foregroundStyle(WatchTheme.Palette.mutedText)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct CompletionRing: View {
    let percent: Int

    private var clamped: Double { Double(max(0, min(100, percent))) / 100 }

    private var tint: Color {
        switch percent {
        case ..<26: return WatchTheme.Palette.danger
        case 26...60: return WatchTheme.Palette.warning
        case 61...89: return WatchTheme.Palette.secondary
        default: return WatchTheme.Palette.success
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.25), lineWidth: 3)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(max(0, min(100, percent)))")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(tint)
        }
    }
}

#Preview {
    NavigationStack {
        PropertyListView()
    }
    .environmentObject(WatchSnapshotStore.shared)
}
