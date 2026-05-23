# Demo Photos

The App-Store demo data benefits from real, marketing-quality photos rather than the synthetic colour-block placeholders that ship by default. This document is the recipe for replacing those placeholders with curated copyright-free imagery.

## Where the wiring lives

- **`Rentory/Utilities/DemoPhotoLibrary.swift`** — declares the slot names (`DemoPhotoSlot`) and resolves each one against the `DemoPhotos` asset catalog. Returns `nil` when the slot has no bundled asset.
- **`Rentory/Utilities/DemoDataFactory.swift`** — calls `DemoPhotoSlot.slot(for: roomType, phase:)` to derive a slot, then `DemoPhotoLibrary.image(for:)` to fetch the photo. Falls back to the synthetic placeholder when nothing is bundled.
- **`Rentory/DemoPhotos.xcassets/`** — the dedicated asset catalog for demo photos. Starts empty; add image sets as you curate.

The factory works correctly with the catalog empty, partially full, or fully populated — there is no all-or-nothing requirement.

## Slot names to populate

| Slot | Used for | Search ideas |
| --- | --- | --- |
| `demo-kitchen-moveIn` | Kitchen room evidence at move-in | "modern kitchen interior", "white kitchen island" |
| `demo-kitchen-during` | Kitchen during tenancy | "clean kitchen counter", "kitchen cooking" |
| `demo-livingRoom-moveIn` | Living room evidence at move-in | "minimal living room sofa", "scandi living room" |
| `demo-livingRoom-during` | Living room during tenancy | "living room reading", "lit lamp interior" |
| `demo-bedroom-moveIn` | Bedroom evidence at move-in | "neat made bed", "scandi bedroom interior" |
| `demo-bedroom-during` | Bedroom during tenancy | "open wardrobe", "morning bedroom" |
| `demo-bathroom-moveIn` | Bathroom evidence at move-in | "modern bathroom tiles", "minimal bathroom" |
| `demo-bathroom-during` | Bathroom during tenancy | "shower head", "clean bathroom mirror" |
| `demo-ensuite-moveIn` | Ensuite bathroom | "ensuite shower", "small bathroom" |
| `demo-hallway-moveIn` | Hallway / entryway | "entryway interior", "hallway with hooks" |
| `demo-utility-moveIn` | Utility room | "utility room washing machine", "laundry room" |
| `demo-garden-moveIn` | Garden | "small back garden", "patio with plants" |
| `demo-garage-moveIn` | Garage interior | "tidy garage interior", "single garage uk" |
| `demo-exterior-moveIn` | Front of property | "uk terraced house front", "front door porch" |
| `demo-defect-wall-scuff` | Move-out defect close-up | "scuffed wall", "chipped paint close" |
| `demo-defect-carpet-wear` | Carpet wear | "worn carpet", "carpet edge wear" |
| `demo-defect-ceiling-damp` | Ceiling damp | "ceiling water stain", "damp patch" |
| `demo-defect-window-condensation` | Condensation | "window condensation", "foggy window" |
| `demo-defect-cabinet-handle` | Loose cabinet fixture | "cabinet handle loose", "broken cupboard handle" |
| `demo-defect-tile-chip` | Tile chip / crack | "chipped bathroom tile", "cracked tile" |

## How to add a photo

1. **Curate.** Browse [Pexels](https://www.pexels.com/) or [Unsplash](https://unsplash.com/) for a photo matching the slot. Both sites license their photos for commercial use; Pexels requires no attribution, Unsplash recommends but does not require it.
2. **Download.** Save the photo to `~/Downloads/`. Pick reasonably high-resolution (≥ 1600 px on the long edge) but not enormous (≤ 5 MB).
3. **Add to the catalog in Xcode.**
   - Open `Rentory/DemoPhotos.xcassets/` in Xcode.
   - Drag the photo into the catalog.
   - Rename the resulting image set to the exact slot name (e.g. `demo-kitchen-moveIn`). Xcode also creates a folder named the same on disk.
   - Confirm the image is listed under "Universal" so it's available on iOS, iPadOS, watchOS and macOS.
4. **Rebuild.** `DemoPhotoLibrary.image(for:)` will start returning the bundled image next launch. Existing demo records won't auto-refresh — clear demo data and reload via Settings → Sample data.

## Photo guidelines

- **No people identifiable in shots.** No faces, no readable name tags. Rentory shouldn't accidentally identify a stranger.
- **No real addresses.** Avoid shots showing house numbers, street signs or distinctive landmarks that could pin a real place.
- **No copyrighted artwork or branded products on display.** Books spines, magazines, brand-name appliances etc. that read as a generic interior are fine.
- **Aspirational but plausible.** Marketing screenshots benefit from bright, well-lit, modern interiors — but they should still look like rentals, not magazine spreads.

## Licensing record

Keep a CSV / note inside this repo (gitignored) listing each downloaded photo, the source URL, photographer credit (if used), and the licence — so a future reviewer can confirm provenance.

## Removing the bundled photos

The factory falls back to the synthetic placeholders if a slot has no asset. To remove a slot's photo, delete the image set from `DemoPhotos.xcassets` in Xcode; nothing else needs changing.
