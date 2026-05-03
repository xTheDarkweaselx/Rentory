# App Configuration

Rentory currently uses generated Info.plist values through the Xcode project configuration.

## Required privacy strings

- `NSCameraUsageDescription`
  - Text: “Rentory needs camera access when you choose to take a photo for your rental record.”
  - Why: Needed only when the user chooses to take a photo.
  - When requested: When the user taps the option to take a photo.

- `NSPhotoLibraryUsageDescription`
  - Text: “Rentory needs photo access when you choose a photo for your rental record.”
  - Why: Needed only when the user chooses a photo from their library.
  - When requested: When the user taps the option to choose a photo.

- `NSFaceIDUsageDescription`
  - Text: “Rentory uses Face ID when you choose to lock the app.”
  - Why: Needed for optional App Lock.
  - When requested: When the user enables App Lock or unlocks the app with Face ID.

## Permissions not used

- No `NSPhotoLibraryAddUsageDescription`, because Rentory does not save images back to the user’s photo library.
- No location permission
- No contacts permission
- No calendar permission
- No microphone permission

## Capability assumptions

- No developer-owned backend
- No analytics SDKs
- No advertising SDKs
- No tracking SDKs
- No third-party AI SDKs
- No background modes
- StoreKit is the only non-iCloud network-adjacent Apple service used in v1

## Display and device support

- App display name: `Rentory`
- iPhone supported
- iPad supported
- Light and dark mode supported

## Permission timing review

- Camera permission is requested only when the user chooses to take a photo
- Photo library permission is requested only when the user chooses a photo
- Face ID permission is requested only when the user enables or uses App Lock
- No permission prompts appear during onboarding

## iCloud and backups

- Rentory works fully without iCloud
- iCloud status can be checked in settings
- Full live iCloud sync is not enabled yet in this version
- Local backup export and import are available
- Backups are created on the device and shared only when the user chooses to do so
