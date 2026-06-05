# Privacy Checklist

## App Store privacy labels
- [x] No user account
- [x] No advertising tracking
- [x] No behavioural analytics
- [x] No third-party AI services
- [x] No backend storage
- [x] StoreKit may be used for purchases
- [x] App stores user-created records locally on device
- [x] Photos and documents are user-provided and stored locally
- [x] Reports are created locally and shared only by the user
- [x] Backups are created locally and saved or shared only when the user chooses to do so
- [x] iCloud status can be checked without using a developer-owned service
- [x] App Group container is used only for an on-device snapshot shared between the main app, widgets and watch complications (same Team ID, same App Group entitlement)
- [x] WatchConnectivity moves data only between the user's iPhone and their paired Apple Watch — no internet hop
- [x] Reminder notifications are local (UNCalendarNotificationTrigger); no APNS or remote push
- [x] Calendar mirror is opt-in and uses full Calendar access (`NSCalendarsFullAccessUsageDescription`), required because Rentory reconciles the events it created; Rentory only creates, updates and removes events in its own dedicated "Rentory reminders" calendar, never modifies the user's other calendars, and never transmits Calendar data off the device
- [x] Siri Shortcuts / AppIntents perform locally — Add reminder + Log rent payment queue payloads into the on-device App Group container; Open next reminder reads from the same shared snapshot. None of these intents leave the device.

Warning: Review App Store privacy answers before submission. Only claim “Data Not Collected” if the app does not collect data from the device and does not transmit user data to the developer or third parties. StoreKit purchase handling and any future iCloud sync behaviour must be assessed according to Apple’s current privacy questionnaire.
