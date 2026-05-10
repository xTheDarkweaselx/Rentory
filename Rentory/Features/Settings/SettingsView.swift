//
//  SettingsView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage(AppAppearance.storageKey) private var appAppearanceRawValue = AppAppearance.deviceDefault.rawValue
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var appSecurityState: AppSecurityState
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var iCloudSyncService: ICloudSyncService

    @State private var selectedCategory: SettingsCategory = .privacySecurity
    @State private var selectedDestination: SettingsDestination?
    @State private var appLockToggleIsOn = false
    @State private var upgradePromptContent: UpgradePromptContent?

    var body: some View {
        NavigationStack {
            Group {
                if PlatformLayout.isPhone && horizontalSizeClass != .regular {
                    compactSettingsView
                } else {
                    RRAdaptiveModalContainer(
                        preferredWidth: PlatformLayout.preferredSettingsDialogWidth,
                        preferredHeight: 760,
                        minWidth: 980,
                        minHeight: 640
                    ) {
                        RRSheetHeader(
                            title: "Settings",
                            subtitle: "Manage privacy, sync, backups and Rentory unlock.",
                            systemImage: "gearshape",
                            showsCloseButton: true,
                            closeLabel: "Close settings",
                            closeAction: { dismiss() }
                        )
                    } content: {
                        settingsBody
                    }
                }
            }
            .navigationDestination(for: SettingsDestination.self) { destination in
                destinationView(for: destination)
            }
            .onAppear {
                appLockToggleIsOn = appSecurityState.isAppLockEnabled
            }
            .onChange(of: appSecurityState.isAppLockEnabled) { _, newValue in
                appLockToggleIsOn = newValue
            }
            .alert(item: $appSecurityState.alertContent) { content in
                Alert(
                    title: Text(content.title),
                    message: Text(content.message),
                    dismissButton: .cancel(Text(content.buttonTitle))
                )
            }
            .sheet(item: $upgradePromptContent) { content in
                LimitReachedView(title: content.title, message: content.message)
            }
        }
    }

    private var categorySidebar: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.smallSpacing) {
                ForEach(SettingsCategory.allCases) { category in
                    Button {
                        selectedCategory = category
                        selectedDestination = nil
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: category.systemImage)
                                .frame(width: 18)
                                .foregroundStyle(selectedCategory == category ? Color.white : RRColours.primary)

                            Text(category.title)
                                .font(RRTypography.body.weight(.semibold))
                                .foregroundStyle(selectedCategory == category ? Color.white : RRColours.primary)
                                .lineLimit(1)
                                .truncationMode(.tail)

                            Spacer(minLength: 8)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(selectedCategory == category ? Color.accentColor.opacity(0.92) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(category.title)
                }
            }
        }
    }

    private var settingsBody: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 24) {
                categorySidebar
                    .frame(width: 280)

                selectedDetailView
                    .frame(minWidth: 650, maxWidth: .infinity, alignment: .topLeading)
                    .layoutPriority(1)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                categorySidebar
                selectedDetailView
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var selectedDetailView: some View {
        VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
            if let selectedDestination {
                destinationDetailView(for: selectedDestination)
            } else {
                RRGlassPanel {
                    VStack(alignment: .leading, spacing: RRTheme.smallSpacing) {
                        Text(selectedCategory.title)
                            .font(RRTypography.title)
                            .foregroundStyle(RRColours.primary)
                            .layoutPriority(1)

                        Text(selectedCategory.subtitle)
                            .font(RRTypography.body)
                            .foregroundStyle(RRColours.mutedText)
                            .fixedSize(horizontal: false, vertical: true)
                            .layoutPriority(1)
                    }
                }

                switch selectedCategory {
                case .privacySecurity:
                    settingsDetailGrid(items: privacySecurityItems)
                case .appLock:
                    settingsDetailGrid(items: appLockItems)
                case .appearance:
                    settingsDetailGrid(items: appearanceItems)
                case .iCloudSync:
                    settingsDetailGrid(items: iCloudItems)
                case .backups:
                    settingsDetailGrid(items: backupsItems)
                case .rentoryUnlock:
                    settingsDetailGrid(items: unlockItems)
                case .dataOnDevice:
                    settingsDetailGrid(items: dataItems)
                case .about:
                    settingsDetailGrid(items: aboutItems)
                }
            }
        }
    }

    private func settingsDetailGrid(items: [RRResponsiveFormGridItem]) -> some View {
        RRResponsiveFormGrid(items: items, spacing: RRTheme.cardSpacing)
    }

    private var privacySecurityItems: [RRResponsiveFormGridItem] {
        [
            RRResponsiveFormGridItem {
                settingsCard(
                    title: "Private by default",
                    body: "Your records stay on your device unless you choose to export a backup or share a report."
                )
            },
            RRResponsiveFormGridItem {
                settingsCard(
                    title: "App Lock",
                    body: "Use Face ID, Touch ID or your passcode to help keep your rental records private."
                ) {
                    Button("Open App Lock settings") {
                        selectedCategory = .appLock
                    }
                    .buttonStyle(.plain)
                    .font(RRTypography.body.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                }
            },
            RRResponsiveFormGridItem {
                settingsCard(
                    title: "Privacy & Data",
                    body: "Review temporary reports, storage details and deletion options on this device."
                ) {
                    settingsDestinationAction("Open Privacy & Data", destination: .privacyAndData)
                }
            },
        ]
    }

    private var appLockItems: [RRResponsiveFormGridItem] {
        [
            RRResponsiveFormGridItem {
                settingsCard(
                    title: "App Lock",
                    body: "Use Face ID, Touch ID or your passcode to help keep your rental records private."
                ) {
                    VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                        Toggle("Lock Rentory", isOn: $appLockToggleIsOn)
                            .disabled(appSecurityState.isAuthenticating)
                            .tint(Color.accentColor)
                            .onChange(of: appLockToggleIsOn) { oldValue, newValue in
                                handleAppLockChange(from: oldValue, to: newValue)
                            }

                        Text(appSecurityState.isAppLockEnabled ? "App Lock is on." : "App Lock is off.")
                            .font(RRTypography.footnote)
                            .foregroundStyle(RRColours.mutedText)
                    }
                }
            },
            RRResponsiveFormGridItem {
                settingsCard(
                    title: "How it works",
                    body: "When App Lock is on, Rentory asks you to unlock before showing your rental records."
                )
            },
        ]
    }

    private var appearanceItems: [RRResponsiveFormGridItem] {
        [
            RRResponsiveFormGridItem {
                settingsCard(
                    title: "App appearance",
                    body: "Choose how Rentory looks on this device."
                ) {
                    Picker("App appearance", selection: $appAppearanceRawValue) {
                        ForEach(AppAppearance.allCases) { appearance in
                            Text(appearance.title).tag(appearance.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(selectedAppearance.description)
                        .font(RRTypography.footnote)
                        .foregroundStyle(RRColours.mutedText)
                }
            },
        ]
    }

    private var iCloudItems: [RRResponsiveFormGridItem] {
        [
            RRResponsiveFormGridItem {
                settingsCard(
                    title: "iCloud sync",
                    body: "Keep records available across your devices using your private iCloud account."
                ) {
                    statusRow(label: "Current status", value: iCloudSettingsValue)
                    settingsDestinationAction("Open iCloud sync settings", destination: .iCloudSync)
                }
            },
            RRResponsiveFormGridItem {
                settingsCard(
                    title: "Backups",
                    body: "Backups still work whether iCloud sync is available or not."
                ) {
                    Button("Open backup options") {
                        selectedCategory = .backups
                    }
                    .buttonStyle(.plain)
                    .font(RRTypography.body.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                }
            },
        ]
    }

    private var backupsItems: [RRResponsiveFormGridItem] {
        [
            RRResponsiveFormGridItem {
                settingsCard(
                    title: "Backups",
                    body: "Export or import a Rentory backup when you want to keep a copy."
                ) {
                    settingsDestinationAction("Open backup settings", destination: .backups)
                }
            },
            RRResponsiveFormGridItem {
                settingsCard(
                    title: "What a backup includes",
                    body: "Backups include your records, photos and documents. You choose where to save them."
                )
            },
        ]
    }

    private var unlockItems: [RRResponsiveFormGridItem] {
        [
            RRResponsiveFormGridItem {
                settingsCard(
                    title: "Rentory Unlock",
                    body: "Manage your lifetime unlock or restore your purchase."
                ) {
                    statusRow(label: "Status", value: entitlementManager.isUnlocked ? "Lifetime unlock active" : "Free version")
                    settingsDestinationAction("Open unlock settings", destination: .purchases)
                }
            },
            RRResponsiveFormGridItem {
                settingsCard(
                    title: "Included with the lifetime unlock",
                    body: "Create more records, add more rooms and photos, export full reports and use App Lock."
                )
            },
        ]
    }

    private var dataItems: [RRResponsiveFormGridItem] {
        [
            RRResponsiveFormGridItem {
                settingsCard(
                    title: "Data on this device",
                    body: "Review storage details and remove records from this device when you need to."
                ) {
                    settingsDestinationAction("Open Privacy & Data", destination: .privacyAndData)
                }
            },
            RRResponsiveFormGridItem {
                settingsCard(
                    title: "Welcome screens",
                    body: "Show the welcome screens again if you want a quick refresher."
                ) {
                    RRSecondaryButton(title: "Reset welcome screens") {
                        hasCompletedOnboarding = false
                        dismiss()
                    }
                    .frame(maxWidth: 240)
                }
            },
        ]
    }

    private var aboutItems: [RRResponsiveFormGridItem] {
        var items: [RRResponsiveFormGridItem] = [
            RRResponsiveFormGridItem {
                settingsCard(
                    title: "About Rentory",
                    body: "Rentory helps you organise your own rental records."
                ) {
                    if let appVersion {
                        Text(appVersion)
                            .font(RRTypography.footnote)
                            .foregroundStyle(RRColours.mutedText)
                    }

                    Text("Rentory does not give legal, financial or tenancy advice.")
                        .font(RRTypography.footnote)
                        .foregroundStyle(RRColours.mutedText)
                }
            },
        ]
#if DEBUG
        items.append(
            RRResponsiveFormGridItem {
                settingsCard(
                    title: "Demo data",
                    body: "Use fake sample content for testing and screenshots."
                ) {
                    settingsDestinationAction("Open demo data tools", destination: .developerDemo)
                }
            }
        )
#endif
        return items
    }

    private var compactSettingsView: some View {
        Form {
            Section {
                RRSheetHeader(
                    title: "Settings",
                    subtitle: "Manage privacy, sync, backups and Rentory unlock.",
                    systemImage: "gearshape",
                    showsCloseButton: true,
                    closeLabel: "Close settings",
                    closeAction: { dismiss() }
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section("Privacy & Security") {
                Text("Your records stay on your device by default.")
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)

                Toggle("Lock Rentory", isOn: $appLockToggleIsOn)
                    .disabled(appSecurityState.isAuthenticating)
                    .tint(Color.accentColor)
                    .onChange(of: appLockToggleIsOn) { oldValue, newValue in
                        handleAppLockChange(from: oldValue, to: newValue)
                    }

                Picker("Appearance", selection: $appAppearanceRawValue) {
                    ForEach(AppAppearance.allCases) { appearance in
                        Text(appearance.title).tag(appearance.rawValue)
                    }
                }

                NavigationLink("iCloud sync", value: SettingsDestination.iCloudSync)
                NavigationLink("Backups", value: SettingsDestination.backups)
                NavigationLink("Rentory unlock", value: SettingsDestination.purchases)
                NavigationLink("Data on this device", value: SettingsDestination.privacyAndData)
            }

            Section("About") {
                Text("Rentory helps you organise your own rental records.")
                Text("Rentory does not give legal, financial or tenancy advice.")
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)
            }
        }
        .scrollContentBackground(.hidden)
        .background(RRBackgroundView())
    }

    private func settingsCard<Content: View>(
        title: String,
        body: String,
        @ViewBuilder content: () -> Content = { EmptyView() }
    ) -> some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                Text(title)
                    .font(RRTypography.headline)
                    .foregroundStyle(RRColours.primary)

                Text(body)
                    .font(RRTypography.body)
                    .foregroundStyle(RRColours.mutedText)
                    .fixedSize(horizontal: false, vertical: true)

                content()
            }
        }
    }

    private func statusRow(label: String, value: String) -> some View {
        LabeledContent(label, value: value)
            .font(RRTypography.body)
    }

    @ViewBuilder
    private func settingsDestinationAction(_ title: String, destination: SettingsDestination) -> some View {
        if PlatformLayout.isPhone && horizontalSizeClass != .regular {
            NavigationLink(title, value: destination)
                .font(RRTypography.body.weight(.semibold))
                .foregroundStyle(Color.accentColor)
        } else {
            Button(title) {
                selectedDestination = destination
            }
            .buttonStyle(.plain)
            .font(RRTypography.body.weight(.semibold))
            .foregroundStyle(Color.accentColor)
        }
    }

    @ViewBuilder
    private func destinationView(for destination: SettingsDestination) -> some View {
        switch destination {
        case .privacyAndData:
            PrivacyAndDataSettingsView()
        case .iCloudSync:
            ICloudSyncSettingsView()
        case .backups:
            BackupsSettingsView()
        case .purchases:
            PurchaseSettingsView()
#if DEBUG
        case .developerDemo:
            DeveloperDemoSettingsView()
#endif
        }
    }

    private func destinationDetailView(for destination: SettingsDestination) -> some View {
        VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
            RRGlassPanel {
                VStack(alignment: .leading, spacing: RRTheme.smallSpacing) {
                    Button {
                        selectedDestination = nil
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                            .font(RRTypography.body.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)

                    Text(destination.title)
                        .font(RRTypography.title)
                        .foregroundStyle(RRColours.primary)

                    Text(destination.subtitle)
                        .font(RRTypography.body)
                        .foregroundStyle(RRColours.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            destinationView(for: destination)
                .rrUsesEmbeddedNavigationLayout()
        }
    }

    private func handleAppLockChange(from oldValue: Bool, to newValue: Bool) {
        guard oldValue != newValue else {
            return
        }

        guard !(newValue && !appSecurityState.isAppLockEnabled && !FeatureAccessService.canUseAppLock(isUnlocked: entitlementManager.isUnlocked)) else {
            upgradePromptContent = FeatureAccessService.appLockLimitPrompt
            appLockToggleIsOn = appSecurityState.isAppLockEnabled
            return
        }

        Task {
            let didChange = await appSecurityState.setAppLockEnabled(newValue)

            if !didChange {
                appLockToggleIsOn = appSecurityState.isAppLockEnabled
            }
        }
    }

    private var iCloudSettingsValue: String {
        switch iCloudSyncService.syncStatus {
        case .available:
            return iCloudSyncService.isSyncEnabled ? "On" : "Off"
        case .unavailable:
            return "Unavailable"
        case .checking:
            return "Checking"
        case .unknown:
            return "Unknown"
        }
    }

    private var selectedAppearance: AppAppearance {
        AppAppearance(rawValue: appAppearanceRawValue) ?? .deviceDefault
    }

    private var appVersion: String? {
        guard let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            return nil
        }

        if let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            return "Version \(version) (\(build))"
        }

        return "Version \(version)"
    }
}

private enum SettingsCategory: String, CaseIterable, Identifiable {
    case privacySecurity
    case appLock
    case appearance
    case iCloudSync
    case backups
    case rentoryUnlock
    case dataOnDevice
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .privacySecurity: "Privacy & Security"
        case .appLock: "App Lock"
        case .appearance: "Appearance"
        case .iCloudSync: "iCloud Sync"
        case .backups: "Backups"
        case .rentoryUnlock: "Rentory Unlock"
        case .dataOnDevice: "Data on this device"
        case .about: "About"
        }
    }

    var subtitle: String {
        switch self {
        case .privacySecurity: "See how Rentory keeps your records private and where to manage data controls."
        case .appLock: "Choose whether Rentory should ask you to unlock before showing your records."
        case .appearance: "Choose light, dark or this device’s default appearance."
        case .iCloudSync: "Check whether iCloud sync is available on this device."
        case .backups: "Keep a copy of your records when you want one."
        case .rentoryUnlock: "View your unlock status and restore earlier purchases."
        case .dataOnDevice: "Review storage details and deletion options."
        case .about: "A quick overview of Rentory and this version of the app."
        }
    }

    var systemImage: String {
        switch self {
        case .privacySecurity: "hand.raised.fill"
        case .appLock: "lock.shield.fill"
        case .appearance: "circle.lefthalf.filled"
        case .iCloudSync: "icloud"
        case .backups: "externaldrive"
        case .rentoryUnlock: "sparkles"
        case .dataOnDevice: "internaldrive"
        case .about: "info.circle.fill"
        }
    }
}

private enum SettingsDestination: Hashable, Identifiable {
    case privacyAndData
    case iCloudSync
    case backups
    case purchases
#if DEBUG
    case developerDemo
#endif

    var id: String {
        switch self {
        case .privacyAndData:
            return "privacyAndData"
        case .iCloudSync:
            return "iCloudSync"
        case .backups:
            return "backups"
        case .purchases:
            return "purchases"
#if DEBUG
        case .developerDemo:
            return "developerDemo"
#endif
        }
    }

    var title: String {
        switch self {
        case .privacyAndData:
            return "Privacy & Data"
        case .iCloudSync:
            return "iCloud Sync"
        case .backups:
            return "Backups"
        case .purchases:
            return "Rentory Unlock"
#if DEBUG
        case .developerDemo:
            return "Demo data"
#endif
        }
    }

    var subtitle: String {
        switch self {
        case .privacyAndData:
            return "Manage storage, backups and what stays on this device."
        case .iCloudSync:
            return "Check whether iCloud is available for Rentory on this device."
        case .backups:
            return "Export or import a Rentory backup when you want to keep a copy."
        case .purchases:
            return "Manage your lifetime unlock and restore earlier purchases."
#if DEBUG
        case .developerDemo:
            return "Use fake sample data for testing and screenshots."
#endif
        }
    }
}
