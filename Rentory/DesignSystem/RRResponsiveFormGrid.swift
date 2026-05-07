//
//  RRResponsiveFormGrid.swift
//  Rentory
//
//  Created by OpenAI on 04/05/2026.
//

import SwiftUI

private struct RRResponsiveGridWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

enum RRResponsiveGridSpan {
    case automatic
    case fullWidth

    func resolvedSpan(for columnCount: Int) -> Int {
        switch self {
        case .automatic:
            return 1
        case .fullWidth:
            return max(1, columnCount)
        }
    }
}

struct RRResponsiveFormGridItem: Identifiable {
    let id = UUID()
    let span: RRResponsiveGridSpan
    let content: AnyView

    init<V: View>(span: RRResponsiveGridSpan = .automatic, @ViewBuilder content: () -> V) {
        self.span = span
        self.content = AnyView(content())
    }
}

struct RRResponsiveFormGrid: View {
    let items: [RRResponsiveFormGridItem]
    var spacing: CGFloat = RRTheme.sectionSpacing
    @State private var availableWidth: CGFloat = 0

    var body: some View {
        let resolvedWidth = max(availableWidth, 320)
        let columnCount = PlatformLayout.responsiveColumnCount(for: resolvedWidth)
        let rows = makeRows(for: columnCount)

        Grid(horizontalSpacing: spacing, verticalSpacing: spacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                GridRow {
                    ForEach(row) { item in
                        item.content
                            .gridCellColumns(item.span.resolvedSpan(for: columnCount))
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background {
            GeometryReader { proxy in
                Color.clear
                    .preference(key: RRResponsiveGridWidthKey.self, value: proxy.size.width)
            }
        }
        .onPreferenceChange(RRResponsiveGridWidthKey.self) { width in
            availableWidth = width
        }
    }

    private func makeRows(for columnCount: Int) -> [[RRResponsiveFormGridItem]] {
        var rows: [[RRResponsiveFormGridItem]] = []
        var currentRow: [RRResponsiveFormGridItem] = []
        var usedColumns = 0

        for item in items {
            let span = item.span.resolvedSpan(for: columnCount)

            if span >= columnCount {
                if !currentRow.isEmpty {
                    rows.append(currentRow)
                    currentRow = []
                    usedColumns = 0
                }

                rows.append([item])
                continue
            }

            if usedColumns + span > columnCount {
                rows.append(currentRow)
                currentRow = [item]
                usedColumns = span
            } else {
                currentRow.append(item)
                usedColumns += span
            }
        }

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }
}
