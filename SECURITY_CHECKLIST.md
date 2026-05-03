# Security Checklist

## Storage
- [x] SwiftData stores record information only.
- [x] Photos are stored as local files.
- [x] Documents are stored as local files.
- [x] Temporary reports are stored as local files.
- [x] Stored files use generated names.
- [x] No absolute file paths are stored in SwiftData.
- [x] File protection is applied where available.

## Privacy
- [x] No account creation.
- [x] No backend.
- [x] No analytics.
- [x] No advertising SDKs.
- [x] No tracking.
- [x] No third-party AI APIs.
- [x] No networking except StoreKit and Apple iCloud services chosen by the user.

## Logging
- [x] No property names in logs.
- [x] No addresses in logs.
- [x] No postcodes in logs.
- [x] No landlord or letting agent details in logs.
- [x] No deposit references in logs.
- [x] No notes in logs.
- [x] No document names in logs.
- [x] No file paths in logs.
- [x] No photo captions in logs.

## App Lock
- [x] App Lock tested on launch.
- [x] App Lock tested after backgrounding.
- [x] Failed unlock keeps content hidden.
- [x] Privacy cover hides app switcher content.

## Reports and backups
- [x] Reports are created locally.
- [x] Reports do not include hidden local file names.
- [x] Reports do not include file paths.
- [x] Sensitive report fields are off by default.
- [x] Disclaimer is always included.
- [x] Backups do not include temporary reports by default.
- [x] Backups do not include purchase state or App Lock state.
- [x] Backup import validates manifest and package structure before changing records.
- [x] Backup import rejects invalid file names and path traversal.

## Deletion
- [x] Deleting a record removes linked photos.
- [x] Deleting a record removes linked documents.
- [x] Delete all data removes records, photos, documents and temporary reports.
- [x] Temporary reports can be cleared.
- [x] Old temporary reports can be cleaned up safely.
