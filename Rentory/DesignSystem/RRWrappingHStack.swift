//
//  RRWrappingHStack.swift
//  Rentory
//
//  Lays out its subviews left-to-right, wrapping onto a new row when the
//  next subview would overflow the proposed width. Each row's height
//  matches the tallest subview on that row. Used for pill rows on summary
//  cards so they flow instead of stacking fully vertically when the
//  horizontal version doesn't fit.
//

import SwiftUI

struct WrappingHStack: Layout {
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = makeRows(maxWidth: proposal.width ?? .infinity, subviews: subviews)
        guard !rows.isEmpty else { return .zero }
        let height = rows.reduce(0) { $0 + $1.height } + verticalSpacing * CGFloat(max(rows.count - 1, 0))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = makeRows(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for placement in row.placements {
                subviews[placement.index].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(placement.size)
                )
                x += placement.size.width + horizontalSpacing
            }
            y += row.height + verticalSpacing
        }
    }

    private struct Placement {
        let index: Int
        let size: CGSize
    }

    private struct Row {
        let placements: [Placement]
        let width: CGFloat
        let height: CGFloat
    }

    private func makeRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        guard !subviews.isEmpty else { return [] }

        var rows: [Row] = []
        var currentPlacements: [Placement] = []
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0

        func flush() {
            guard !currentPlacements.isEmpty else { return }
            rows.append(Row(placements: currentPlacements, width: currentWidth, height: currentHeight))
            currentPlacements = []
            currentWidth = 0
            currentHeight = 0
        }

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let prospectiveWidth = currentWidth + (currentPlacements.isEmpty ? 0 : horizontalSpacing) + size.width
            if !currentPlacements.isEmpty && prospectiveWidth > maxWidth {
                flush()
                currentPlacements = [Placement(index: index, size: size)]
                currentWidth = size.width
                currentHeight = size.height
            } else {
                currentPlacements.append(Placement(index: index, size: size))
                currentWidth = prospectiveWidth
                currentHeight = max(currentHeight, size.height)
            }
        }
        flush()
        return rows
    }
}
