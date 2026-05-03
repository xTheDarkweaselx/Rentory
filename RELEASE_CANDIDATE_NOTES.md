# Release Candidate Notes

Current version: 1.0 candidate

## Core features included
- Rental records
- Room checklists
- Move-in, during-tenancy and move-out photos
- Document storage
- Timeline events
- Local PDF reports
- Optional App Lock
- One-off lifetime unlock

## Features intentionally not included
- Cloud sync
- Account sign-in
- Landlord or letting agent sharing
- Legal, financial or tenancy advice
- AI analysis

## Privacy posture
- Rentory is local-first
- Records stay on the device by default
- No analytics
- No advertising
- No tracking
- No backend storage
- StoreKit is the only expected network-adjacent Apple service for purchases

## Known limitations
- No cloud sync in v1.
- No account system in v1.
- No landlord or letting agent sharing in v1.
- No legal advice in v1.
- No AI analysis in v1.

## Manual test checklist
- Create record
- Add room
- Edit checklist
- Add photo
- Delete photo
- Add document
- Preview document
- Delete document
- Add timeline event
- Export report
- Share report
- Clear temporary reports
- Enable App Lock
- Background app and verify privacy cover
- Delete one record
- Delete all data
- Test free limits
- Test lifetime unlock
- Test restore purchase
- Test iPad layout
- Test VoiceOver spot check
- Test large text spot check

## App Store submission reminders
- Confirm the bundle identifier and version number
- Review privacy nutrition labels
- Check the StoreKit product is live and matches `com.fusionstudios.rentory.lifetimeunlock`
- Add support and marketing URLs in App Store Connect
- Prepare light and dark mode screenshots for iPhone and iPad
