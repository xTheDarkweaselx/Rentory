//
//  NotificationSettingsView.swift
//  Rentory
//
//  Lets the user opt in to local reminder notifications and shows the
//  iOS-level authorization status. The toggle drives
//  ReminderNotificationService.isEnabledByUser; the service is the single
//  source of truth for scheduling. Reschedule fires whenever the user
//  changes the toggle.
//

import SwiftData
import SwiftUI
import UserNotifications

@MainActor
struct NotificationSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.rrUsesEmbeddedNavigationLayout) private var usesEmbeddedNavigationLayout
    @EnvironmentObject private var notificationService: ReminderNotificationService
    @AppStorage(ReminderNotificationService.isEnabledStorageKey) private var isEnabled = false

    var body: some View {
        Group {
            if PlatformLayout.isPhone && horizontalSizeClass != .regular {
                compactView
            } else if usesEmbeddedNavigationLayout {
                RRFormContainer(maxWidth: 880) {
                    RRResponsiveFormGrid(items: [
                        RRResponsiveFormGridItem { primaryCard },
                        RRResponsiveFormGridItem { permissionStatusCard },
                    ])
                }
            } else {
                RRMacSheetContainer(maxWidth: 880, minHeight: PlatformLayout.isMac ? 520 : nil) {
                    VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                        RRSheetHeader(
                            title: "Notifications",
                            subtitle: "Get a heads-up the morning a reminder is due.",
                            systemImage: "bell.badge"
                        )

                        RRResponsiveFormGrid(items: [
                            RRResponsiveFormGridItem { primaryCard },
                            RRResponsiveFormGridItem { permissionStatusCard },
                        ])
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .rrInlineNavigationTitle()
        .task {
            await notificationService.refreshAuthorizationStatus()
        }
    }

    private var compactView: some View {
        Form {
            Section {
                Toggle("Reminder notifications", isOn: toggleBinding)
                    .toggleStyle(.switch)
                    .disabled(authorizationDenied)
            } header: {
                Text("Reminders")
            } footer: {
                Text(toggleFooterText)
            }

            Section {
                permissionStatusContent
            } header: {
                Text("System permission")
            }
        }
        .scrollContentBackground(.hidden)
        .background(RRBackgroundView())
    }

    private var primaryCard: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                Text("Reminder notifications")
                    .font(RRTypography.headline)
                    .foregroundStyle(RRColours.primary)

                Text("Rentory can send you a notification at 9 am on the day a reminder is due. Notifications are scheduled locally on this device — Rentory never sends them through a server.")
                    .font(RRTypography.body)
                    .foregroundStyle(RRColours.mutedText)
                    .fixedSize(horizontal: false, vertical: true)

                Toggle("Get a notification when a reminder is due", isOn: toggleBinding)
                    .toggleStyle(.switch)
                    .disabled(authorizationDenied)

                if authorizationDenied {
                    Text("Notifications are turned off for Rentory in your device Settings. Allow notifications there to use this feature.")
                        .font(RRTypography.footnote.weight(.semibold))
                        .foregroundStyle(RRColours.warning)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var permissionStatusCard: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                Text("System permission")
                    .font(RRTypography.headline)
                    .foregroundStyle(RRColours.primary)

                permissionStatusContent
            }
        }
    }

    @ViewBuilder
    private var permissionStatusContent: some View {
        HStack(spacing: 10) {
            Image(systemName: authorizationStatusIcon)
                .foregroundStyle(authorizationStatusTint)
            Text(authorizationStatusTitle)
                .font(RRTypography.body)
                .foregroundStyle(RRColours.primary)
        }

        Text(authorizationStatusSubtitle)
            .font(RRTypography.footnote)
            .foregroundStyle(RRColours.mutedText)
            .fixedSize(horizontal: false, vertical: true)

        if authorizationDenied {
            #if os(iOS) || os(visionOS)
            if let url = URL(string: UIApplication.openSettingsURLString) {
                RRSecondaryButton(title: "Open Settings") {
                    UIApplication.shared.open(url)
                }
            }
            #endif
        }
    }

    // MARK: - State

    private var toggleBinding: Binding<Bool> {
        Binding(
            get: { isEnabled && !authorizationDenied },
            set: { newValue in
                Task {
                    if newValue {
                        if notificationService.authorizationStatus == .notDetermined {
                            _ = await notificationService.requestAuthorization()
                        }
                        await notificationService.refreshAuthorizationStatus()
                        if notificationService.authorizationStatus == .authorized || notificationService.authorizationStatus == .provisional {
                            isEnabled = true
                            notificationService.isEnabledByUser = true
                        } else {
                            isEnabled = false
                            notificationService.isEnabledByUser = false
                        }
                    } else {
                        isEnabled = false
                        notificationService.isEnabledByUser = false
                    }

                    await notificationService.reschedule(context: modelContext)
                }
            }
        )
    }

    private var toggleFooterText: String {
        if authorizationDenied {
            return "Notifications are turned off for Rentory. Allow them in your device Settings to enable this."
        }
        if isEnabled {
            return "Rentory will notify you at 9 am on the day a reminder is due."
        }
        return "Reminders are still tracked inside Rentory. Turn this on to be notified the morning they are due."
    }

    private var authorizationDenied: Bool {
        notificationService.authorizationStatus == .denied
    }

    private var authorizationStatusTitle: String {
        switch notificationService.authorizationStatus {
        case .notDetermined: "Not yet asked"
        case .authorized: "Allowed"
        case .provisional: "Allowed quietly"
        case .denied: "Turned off"
        case .ephemeral: "App Clip"
        @unknown default: "Unknown"
        }
    }

    private var authorizationStatusSubtitle: String {
        switch notificationService.authorizationStatus {
        case .notDetermined:
            return "Rentory will ask for permission the first time you turn the toggle on."
        case .authorized:
            return "Rentory can deliver notifications with sound and the standard banner."
        case .provisional:
            return "Notifications are delivered quietly to the Notification Centre."
        case .denied:
            return "Open System Settings → Notifications → Rentory to allow notifications."
        case .ephemeral:
            return "Ephemeral authorization (App Clips only)."
        @unknown default:
            return "Authorization status is not recognised."
        }
    }

    private var authorizationStatusIcon: String {
        switch notificationService.authorizationStatus {
        case .authorized, .provisional: "checkmark.circle.fill"
        case .denied: "xmark.circle.fill"
        case .ephemeral: "circle.dotted"
        case .notDetermined: "questionmark.circle.fill"
        @unknown default: "questionmark.circle.fill"
        }
    }

    private var authorizationStatusTint: Color {
        switch notificationService.authorizationStatus {
        case .authorized, .provisional: RRColours.success
        case .denied: RRColours.danger
        default: RRColours.mutedText
        }
    }
}
