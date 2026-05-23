//
//  DemoPhotoLibrary.swift
//  Rentory
//
//  Resolves a small set of named photo "slots" used by `DemoDataFactory`
//  into bundled images shipped inside the `DemoPhotos` asset catalog.
//  Each slot is a semantic key (e.g. "kitchenMoveIn") rather than a
//  generic filename — the factory asks for a slot, the library returns
//  an image if a real photo is bundled for that slot, or `nil` to fall
//  back to the existing synthetic colour-block placeholder.
//
//  This split exists so the user can curate marketing-quality photos at
//  their own pace and drop the files into the asset catalog without
//  having to touch Swift. The factory keeps working in either state:
//    • No assets bundled → demo data uses the synthetic placeholders.
//    • Some assets bundled → factory uses real photos where available.
//    • All assets bundled → demo data ships App Store-ready imagery.
//
//  Bundled file expectation:
//    Each slot's `rawValue` is the asset-catalog name. For example
//    `DemoPhotoSlot.kitchenMoveIn.rawValue == "demo-kitchen-moveIn"` —
//    so the asset in `DemoPhotos.xcassets` must be named exactly
//    `demo-kitchen-moveIn`. The matching JPEG / PNG / HEIC lives
//    inside the imageset.
//
//  Local-first contract preserved: assets are bundled in the app, never
//  downloaded at runtime.
//

import Foundation

#if canImport(UIKit)
import UIKit
typealias DemoPlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias DemoPlatformImage = NSImage
#endif

/// Semantic slot keys for marketing-grade photos used by `DemoDataFactory`.
///
/// Naming convention is `{room-or-defect}{Phase}` so a glance at the
/// raw value tells you what the photo depicts and when. The factory
/// composes these from a room's category and the evidence phase being
/// staged.
enum DemoPhotoSlot: String, CaseIterable {
    // Move-in (aspirational) shots — one per room category.
    case kitchenMoveIn = "demo-kitchen-moveIn"
    case livingRoomMoveIn = "demo-livingRoom-moveIn"
    case bedroomMoveIn = "demo-bedroom-moveIn"
    case bathroomMoveIn = "demo-bathroom-moveIn"
    case ensuiteMoveIn = "demo-ensuite-moveIn"
    case hallwayMoveIn = "demo-hallway-moveIn"
    case utilityMoveIn = "demo-utility-moveIn"
    case gardenMoveIn = "demo-garden-moveIn"
    case garageMoveIn = "demo-garage-moveIn"
    case exteriorMoveIn = "demo-exterior-moveIn"

    // During-tenancy shots — typically a clean follow-up or minor wear.
    case kitchenDuringTenancy = "demo-kitchen-during"
    case livingRoomDuringTenancy = "demo-livingRoom-during"
    case bedroomDuringTenancy = "demo-bedroom-during"
    case bathroomDuringTenancy = "demo-bathroom-during"

    // Move-out evidence shots — defects / wear / damage close-ups.
    case wallScuff = "demo-defect-wall-scuff"
    case carpetWear = "demo-defect-carpet-wear"
    case ceilingDamp = "demo-defect-ceiling-damp"
    case windowCondensation = "demo-defect-window-condensation"
    case cabinetHandleLoose = "demo-defect-cabinet-handle"
    case tileChip = "demo-defect-tile-chip"
}

extension DemoPhotoSlot {
    /// Derives a slot for a (room category, phase) pair. Move-out
    /// photos deliberately don't return a slot here — the rich
    /// marketing message for move-out is "defect close-ups," which
    /// the factory pulls separately via the explicit defect slots.
    static func slot(for roomType: RoomType, phase: EvidencePhase) -> DemoPhotoSlot? {
        switch (roomType, phase) {
        case (.kitchen, .moveIn): return .kitchenMoveIn
        case (.kitchen, .duringTenancy): return .kitchenDuringTenancy
        case (.livingRoom, .moveIn): return .livingRoomMoveIn
        case (.livingRoom, .duringTenancy): return .livingRoomDuringTenancy
        case (.bedroom, .moveIn): return .bedroomMoveIn
        case (.bedroom, .duringTenancy): return .bedroomDuringTenancy
        case (.bathroom, .moveIn): return .bathroomMoveIn
        case (.bathroom, .duringTenancy): return .bathroomDuringTenancy
        case (.ensuite, .moveIn): return .ensuiteMoveIn
        case (.hallway, .moveIn): return .hallwayMoveIn
        case (.utility, .moveIn): return .utilityMoveIn
        case (.garden, .moveIn): return .gardenMoveIn
        case (.garage, .moveIn): return .garageMoveIn
        // Move-out is handled by defect slots, not room slots.
        default: return nil
        }
    }
}

/// Looks slot names up in the `DemoPhotos` asset catalog. Returns nil
/// when the slot has no bundled asset so callers can fall back to a
/// synthetic placeholder without crashing.
enum DemoPhotoLibrary {
    /// Resolve a slot to its bundled image, or `nil` if the asset
    /// hasn't been added to the catalog yet. Looks at `.main` first
    /// because the factory runs inside the main app target.
    static func image(for slot: DemoPhotoSlot) -> DemoPlatformImage? {
        #if canImport(UIKit)
        return UIImage(named: slot.rawValue)
        #elseif canImport(AppKit)
        return NSImage(named: NSImage.Name(slot.rawValue))
        #else
        return nil
        #endif
    }

    /// True if at least one slot resolves to a bundled asset. Used by
    /// docs / settings tooling that wants to show "demo photos
    /// installed" status without iterating every slot.
    static var hasAnyBundledAsset: Bool {
        DemoPhotoSlot.allCases.contains { image(for: $0) != nil }
    }

    /// Convenience that returns slots which currently resolve. Useful
    /// for diagnostics and for tests that assert "these specific slots
    /// were bundled."
    static var bundledSlots: [DemoPhotoSlot] {
        DemoPhotoSlot.allCases.filter { image(for: $0) != nil }
    }
}
