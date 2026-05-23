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
- Rent payments and property expenses (landlord profile) with current-month net summary
- Backup export and import as `.rentorybackup` packages (v5 payload — adds recurring-reminder cadence on top of v4; decodes v1–v5)
- Recurring reminders (daily / weekly / fortnightly / monthly / quarterly / yearly) — completing a recurring reminder spawns the next occurrence automatically
- CSV finance export for the current UK tax year (landlord profile) — per-property rent payments and expenses, shareable via the system share sheet
- Siri Shortcuts / AppIntents app actions: Add Rentory reminder, Open next Rentory reminder, Log Rentory rent payment
- Optional Calendar mirror (write-only) — Rentory writes upcoming reminders to a dedicated "Rentory reminders" calendar; disabling removes the calendar
- Top-level search across reminders, rooms, documents, timeline and notes — hits inside a record show inline as a chip on the property card
- Provisional notification fallback — after a user declines the explicit notification prompt once, Rentory silently requests `.provisional` permission on the next reminder save so they still get quiet Notification Centre delivery
- Optional iCloud snapshot sync to the user's private CloudKit database
- Optional App Lock (biometric / device passcode)
- One-off lifetime unlock IAP
- Sample data sets for both profiles (eight renter samples, six landlord samples)
- Local reminder notifications (UNCalendarNotificationTrigger, 9 AM local time, opt-in)
- Haptic feedback on save, delete and favourite toggles (iOS / iPadOS; macOS native + visionOS no-op)
- Home Screen widgets: Next reminder, Monthly finance (landlord), Next step — with Smart Stack relevance hints so iOS surfaces the right tile at the right time
- Apple Watch companion: Reminders / Records / Quick Add tabs, with iPhone confirmation handshake so the pending counter clears when reminders land
- Apple Watch face complications: Next reminder, Record progress — tappable deep links open the right record (accessoryCircular / accessoryRectangular / accessoryInline / accessoryCorner)

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
- App Group `group.com.fusionstudios.rentory` is shared only between processes signed with this Team ID + entitlement (main app, widget extension, watch complication extension) on a single device
- WatchConnectivity carries the snapshot between iPhone and the paired Apple Watch; no internet hop

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
- Add a Home Screen widget (Next reminder / Monthly finance / Next step) and verify it shows live data
- Tap a Home Screen widget and verify it opens Rentory focused on the relevant property
- Enable reminder notifications (toggle in Settings or accept the prompt after creating the first reminder); confirm permission dialog appears
- Install Rentory on a paired Apple Watch via the Watch app
- On the watch, verify the Reminders tab populates after the iPhone foregrounds
- On the watch, verify the Records tab shows completion rings and next-step copy
- On the watch, queue a Quick Add reminder and verify it appears on the iPhone after the next bridge transfer
- Add a watch face complication (Next reminder, Record progress) and verify it shows live data
- Trigger a reminder notification (schedule a reminder due ~1 min from now) and tap it; verify Rentory opens to the relevant property

## App Store submission reminders
- Confirm the bundle identifier and version number
- Review privacy nutrition labels (CloudKit private DB on opt-in; StoreKit only)
- Check the StoreKit product is live and matches `com.fusionstudios.rentory.lifetimeunlock`
- Add support and marketing URLs in App Store Connect
- Prepare light and dark mode screenshots for iPhone and iPad — include at least one renter and one landlord screen
- Include a landlord dashboard screenshot showing the Tenancies and Compliance cards
