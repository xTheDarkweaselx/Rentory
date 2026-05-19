# Release Candidate Notes

Current version: 1.0 candidate

## Core features included
- Renter and Landlord profiles (chosen during onboarding, switchable in Settings)
- Profile-scoped rental records (a record belongs to one profile and is only visible in that profile)
- Room checklists with move-in and move-out conditions, notes and comments
- Move-in, during-tenancy and move-out photo evidence
- Document storage (PDF, images, text, doc, docx)
- Timeline events for key dates and incidents
- Reminders / Action Pulse with profile-aware kinds (renter prompts + landlord-only compliance prompts)
- Tenancies and tenants (landlord profile): per-tenancy records with multiple tenants, rent, deposit, mode (standard / comprehensive), status (upcoming / active / ended), and notes
- Compliance reminder kinds for landlords: gas safety, electrical safety (EICR), energy performance (EPC), periodic inspection, tenancy renewal
- Local PDF reports (cover, property summary, tenancies, rooms, photos, documents, timeline, reminders, disclaimer)
- Backup export and import as `.rentorybackup` packages (v3 payload, decodes v1 and v2)
- Optional iCloud snapshot sync to the user's private CloudKit database
- Optional App Lock (biometric / device passcode)
- One-off lifetime unlock IAP
- Sample data sets for both profiles (eight renter samples, six landlord samples)

## Features intentionally not included
- Account sign-in
- Multi-user collaboration or landlord/agent sharing
- Legal, financial or tenancy advice
- AI analysis or background AI processing
- Third-party analytics, advertising or tracking

## Privacy posture
- Rentory is local-first
- Records stay on the device by default
- No analytics
- No advertising
- No tracking
- No backend storage Rentory controls
- iCloud sync uses the user's own private CloudKit database (opt-in)
- StoreKit is the only network-adjacent Apple service used outside iCloud

## Known limitations
- No account system; sharing across people requires the device-level backup or iCloud sync.
- Profile is per-record and cannot be changed after creation (records would need to be re-created in the other profile).
- iCloud sync is snapshot-based: the newer side wins on conflict.
- No legal advice. No AI analysis.
- All UI copy is hard-coded English; no localisation yet.

## Manual test checklist
- Onboarding picks renter profile and lands on an empty list
- Onboarding picks landlord profile (requires lifetime unlock, paywall appears for free users)
- Demo data prompt fires after first onboarding for the chosen profile
- Switching profile in Settings → renter records hide, landlord records appear, and vice versa
- First switch to landlord triggers the landlord example-records prompt
- Create record
- Add room
- Edit checklist
- Add photo
- Delete photo
- Add document
- Preview document
- Delete document
- Add timeline event
- Add reminder (renter kinds only on renter profile)
- Add reminder (landlord kinds available on landlord profile)
- Add tenancy with two tenants on a landlord record
- Edit tenancy switching standard ↔ comprehensive mode
- Mark a reminder complete
- Export report — verify Tenancies and Reminders sections appear for a landlord record
- Export report on renter record — verify Tenancies/Reminders sections are absent when there is no data
- Share report
- Clear temporary reports
- Export backup
- Import backup in Add mode
- Import backup in Replace mode
- Enable App Lock
- Background app and verify privacy cover
- Enable iCloud Sync (with signed-in iCloud) and verify status flips to Available
- Delete one record
- Delete all data
- Test free limits (1 property, 2 rooms, 20 photos)
- Test lifetime unlock
- Test restore purchase
- Test iPad layout (split view in regular size class)
- Test VoiceOver spot check (profile picker, tenancies card, compliance card, reminder rows)
- Test large text spot check

## App Store submission reminders
- Confirm the bundle identifier and version number
- Review privacy nutrition labels (CloudKit private DB on opt-in; StoreKit only)
- Check the StoreKit product is live and matches `com.fusionstudios.rentory.lifetimeunlock`
- Add support and marketing URLs in App Store Connect
- Prepare light and dark mode screenshots for iPhone and iPad — include at least one renter and one landlord screen
- Include a landlord dashboard screenshot showing the Tenancies and Compliance cards
