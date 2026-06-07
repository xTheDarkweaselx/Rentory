//
//  SettingsView.swift
//  Rentory
//
//  Top-level Settings surface. The IA collapses what used to be 11
//  scattered categories (each fronted by a "Open X settings" stub)
//  into 6 category pages, each rendering its real controls inline.
//  Deeper leaf views (Privacy & Data, Backups, Notifications, etc.)
//  are drill-ins from inside the matching category page — never
//  shortcuts in unrelated categories.
//
//  Same 6 categories appear in compact (iPhone) layout via Form rows,
//  so iPhone and Mac/iPad share one mental model.
//

import SwiftData
import SwiftUI

struct SettingsView: View {
    // MARK: - Persisted preferences
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage(AppAppearance.storageKey) private var appAppearanceRawValue = AppAppearance.deviceDefault.rawValue
    @AppStorage(AppColourTheme.storageKey) private var appColourThemeRawValue = AppColourTheme.defaultLook.rawValue
    @AppStorage(RentoryUserProfile.storageKey) private var profileRawValue = RentoryUserProfile.defaultProfile.rawValue

    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var appSecurityState: AppSecurityState
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var iCloudSyncService: ICloudSyncService

    // SwiftData only invalidates this view when an archived pack
    // changes — we never need to scan the full collection just to
    // count archived ones.
    @Query(filter: #Predicate<PropertyPack> { $0.isArchived })
    private var archivedPacks: [PropertyPack]

    // MARK: - Local UI state
    @State private var selectedCategory: SettingsCategory = .general
    @State private var selectedDetail: SettingsDetail?
    @State private var upgradePromptContent: UpgradePromptContent?

    private var isCompact: Bool {
        PlatformLayout.isPhone && horizontalSizeClass != .regular
    }

    var body: some View {
        NavigationStack {
            Group {
                if isCompact {
                    compactRoot
                } else {
                    wideRoot
                }
            }
            .navigationDestination(for: SettingsCategory.self) { category in
                ScrollView {
                    categoryContent(for: category)
                        .padding(RRTheme.screenPadding)
                }
                .background(RRBackgroundView())
                .navigationTitle(category.title)
                .rrInlineNavigationTitle()
            }
            .navigationDestination(for: SettingsDetail.self) { detail in
                detailView(for: detail)
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
            #if os(macOS)
            .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
            .toolbar(removing: .title)
            #endif
        }
    }

    // MARK: - Root layouts

    /// iPhone root: a Form whose only job is to drill into one of the
    /// 6 category pages. Same 6 categories Mac/iPad sees in its
    /// sidebar — one IA, two presentations.
    private var compactRoot: some View {
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

            Section {
                ForEach(SettingsCategory.allCases) { category in
                    NavigationLink(value: category) {
                        categoryRow(for: category)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(RRBackgroundView())
    }

    private func categoryRow(for category: SettingsCategory) -> some View {
        HStack(spacing: 14) {
            Image(systemName: category.systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(RRColours.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.title)
                    .font(RRTypography.body.weight(.semibold))
                    .foregroundStyle(RRColours.primary)
                Text(category.subtitle)
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)
                    .lineLimit(2)
            }
        }
    }

    /// Mac/iPad root: sidebar + detail. Sidebar shows the 6
    /// categories; detail shows either the active category or a
    /// drilled-in leaf with a "Back to …" header.
    private var wideRoot: some View {
        RRAdaptiveModalContainer(
            preferredWidth: PlatformLayout.preferredSettingsDialogWidth,
            preferredHeight: 760,
            minWidth: 980,
            minHeight: 640,
            outerPadding: 0
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
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 24) {
                    categorySidebar
                        .frame(width: 280)

                    wideDetailColumn
                        .frame(minWidth: 650, maxWidth: .infinity, alignment: .topLeading)
                        .layoutPriority(1)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                    categorySidebar
                    wideDetailColumn
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }

    private var categorySidebar: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.smallSpacing) {
                ForEach(SettingsCategory.allCases) { category in
                    sidebarRow(for: category)
                }
            }
        }
    }

    private func sidebarRow(for category: SettingsCategory) -> some View {
        let isActive = selectedCategory == category
        return Button {
            selectedCategory = category
            selectedDetail = nil
        } label: {
            HStack(spacing: 12) {
                Image(systemName: category.systemImage)
                    .frame(width: 18)
                    .foregroundStyle(isActive ? Color.white : RRColours.primary)

                Text(category.title)
                    .font(RRTypography.body.weight(.semibold))
                    .foregroundStyle(isActive ? Color.white : RRColours.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 8)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isActive ? RRColours.secondary.opacity(0.92) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(category.title)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }

    private var wideDetailColumn: some View {
        VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
            if let detail = selectedDetail {
                wideDetailHeader(detail: detail)
                detailView(for: detail)
                    .rrUsesEmbeddedNavigationLayout()
                    .environment(\.rrEmbeddedLeafDismiss, { selectedDetail = nil })
            } else {
                wideCategoryHeader(for: selectedCategory)
                categoryContent(for: selectedCategory)
            }
        }
    }

    private func wideCategoryHeader(for category: SettingsCategory) -> some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.smallSpacing) {
                Text(category.title)
                    .font(RRTypography.title)
                    .foregroundStyle(RRColours.primary)

                Text(category.subtitle)
                    .font(RRTypography.body)
                    .foregroundStyle(RRColours.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func wideDetailHeader(detail: SettingsDetail) -> some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.smallSpacing) {
                Button {
                    selectedDetail = nil
                } label: {
                    Label("Back to \(selectedCategory.title)", systemImage: "chevron.left")
                        .font(RRTypography.body.weight(.semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(RRColours.secondary)

                Text(detail.title)
                    .font(RRTypography.title)
                    .foregroundStyle(RRColours.primary)

                Text(detail.subtitle)
                    .font(RRTypography.body)
                    .foregroundStyle(RRColours.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Category content (lands directly on real controls)

    @ViewBuilder
    private func categoryContent(for category: SettingsCategory) -> some View {
        switch category {
        case .general:
            generalCategory
        case .privacySecurity:
            privacySecurityCategory
        case .syncBackups:
            syncBackupsCategory
        case .notificationsWidgets:
            notificationsWidgetsCategory
        case .data:
            dataCategory
        case .about:
            aboutCategory
        }
    }

    private var generalCategory: some View {
        RRResponsiveFormGrid(
            items: [
                RRResponsiveFormGridItem(span: .fullWidth) {
                    settingsCard(
                        title: "Profile",
                        body: "Pick the profile that fits how you use Rentory. You can switch any time — your records aren’t tied to a profile."
                    ) {
                        profileChooser
                    }
                },
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
                RRResponsiveFormGridItem {
                    settingsCard(
                        title: "Colour theme",
                        body: "Choose the colour style Rentory uses for highlights, panels and buttons."
                    ) {
                        Picker("Colour theme", selection: $appColourThemeRawValue) {
                            ForEach(AppColourTheme.allCases) { theme in
                                Text(theme.title).tag(theme.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)

                        Text(selectedColourTheme.description)
                            .font(RRTypography.footnote)
                            .foregroundStyle(RRColours.mutedText)
                    }
                },
            ],
            spacing: RRTheme.cardSpacing
        )
    }

    private var privacySecurityCategory: some View {
        RRResponsiveFormGrid(
            items: [
                RRResponsiveFormGridItem {
                    settingsCard(
                        title: "App Lock",
                        body: Self.appLockDescription
                    ) {
                        VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                            Toggle("Lock Rentory", isOn: appLockBinding)
                                .disabled(appSecurityState.isAuthenticating)
                                .tint(RRColours.secondary)

                            Text(appSecurityState.isAppLockEnabled ? "App Lock is on." : "App Lock is off.")
                                .font(RRTypography.footnote)
                                .foregroundStyle(RRColours.mutedText)
                        }
                    }
                },
                RRResponsiveFormGridItem {
                    settingsCard(
                        title: "Private by default",
                        body: "Your records stay on your device unless you choose to export a backup or share a report. Storage and deletion details live under Data."
                    )
                },
            ],
            spacing: RRTheme.cardSpacing
        )
    }

    private var syncBackupsCategory: some View {
        RRResponsiveFormGrid(
            items: [
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
                        body: "Export or import a Rentory backup when you want to keep a copy. Backups work whether iCloud sync is on or not."
                    ) {
                        settingsDestinationAction("Open backup options", destination: .backups)
                    }
                },
                RRResponsiveFormGridItem {
                    settingsCard(
                        title: "What a backup includes",
                        body: "Backups include your records, photos and documents. You choose where to save them."
                    )
                },
            ],
            spacing: RRTheme.cardSpacing
        )
    }

    private var notificationsWidgetsCategory: some View {
        RRResponsiveFormGrid(
            items: [
                RRResponsiveFormGridItem {
                    settingsCard(
                        title: "Reminder notifications",
                        body: "Get a notification at 9 am on the day a reminder is due. Notifications are scheduled locally — Rentory never sends them through a server."
                    ) {
                        settingsDestinationAction("Open notification settings", destination: .notifications)
                    }
                },
                RRResponsiveFormGridItem {
                    settingsCard(
                        title: "Widgets & Watch",
                        body: "Glanceable Rentory tiles for the Home Screen and Apple Watch — added from the system, not from inside the app."
                    ) {
                        settingsDestinationAction("Open widget overview", destination: .widgets)
                    }
                },
                RRResponsiveFormGridItem {
                    settingsCard(
                        title: "How they stay current",
                        body: "Both surfaces read a snapshot Rentory writes to its shared container whenever you open the app, change profile or come back from the background. No network calls."
                    )
                },
            ],
            spacing: RRTheme.cardSpacing
        )
    }

    private var dataCategory: some View {
        RRResponsiveFormGrid(
            items: [
                RRResponsiveFormGridItem {
                    settingsCard(
                        title: "Storage and deletion",
                        body: "Review storage details, clear temporary reports or remove records from this device."
                    ) {
                        settingsDestinationAction("Open storage details", destination: .privacyAndData)
                    }
                },
                RRResponsiveFormGridItem {
                    settingsCard(
                        title: "Archived records",
                        body: archivedRecordsBody
                    ) {
                        settingsDestinationAction("Open archived records", destination: .archivedRecords)
                    }
                },
                RRResponsiveFormGridItem {
                    settingsCard(
                        title: "Activity history",
                        body: "Review recent backups, imports, reports, sync attempts and record changes on this device."
                    ) {
                        settingsDestinationAction("Open activity history", destination: .activityHistory)
                    }
                },
                RRResponsiveFormGridItem {
                    settingsCard(
                        title: "Sample data",
                        body: "Load example records to explore Rentory, or remove them when you are done."
                    ) {
                        settingsDestinationAction("Open sample data", destination: .sampleData)
                    }
                },
            ],
            spacing: RRTheme.cardSpacing
        )
    }

    private var aboutCategory: some View {
        RRResponsiveFormGrid(
            items: [
                RRResponsiveFormGridItem {
                    settingsCard(
                        title: "About Rentory",
                        body: "Rentory helps you organise your own rental records."
                    ) {
                        if let appVersion = AppBundleInfo.displayString {
                            Text(appVersion)
                                .font(RRTypography.footnote)
                                .foregroundStyle(RRColours.mutedText)
                        }
                    }
                },
                RRResponsiveFormGridItem {
                    settingsCard(
                        title: "Rentory Unlock",
                        body: "Manage your lifetime unlock or restore your purchase."
                    ) {
                        statusRow(
                            label: "Status",
                            value: entitlementManager.isUnlocked ? "Lifetime unlock active" : "Free version"
                        )
                        settingsDestinationAction("Open unlock settings", destination: .purchases)
                    }
                },
                RRResponsiveFormGridItem {
                    settingsCard(
                        title: "Send feedback",
                        body: "Pass along bug reports, feature requests, or questions. Opens a draft in your default mail client."
                    ) {
                        settingsDestinationAction("Open feedback form", destination: .feedback)
                    }
                },
                RRResponsiveFormGridItem {
                    settingsCard(
                        title: "Welcome guide",
                        body: "Open the welcome guide again if you want a quick reminder of the basics."
                    ) {
                        RRSecondaryButton(title: "Show welcome guide again") {
                            hasCompletedOnboarding = false
                            dismiss()
                        }
                        .frame(maxWidth: 260)
                    }
                },
                RRResponsiveFormGridItem {
                    settingsCard(
                        title: "Privacy note",
                        body: "Rentory keeps your records on this device by default and does not give legal, financial or tenancy advice."
                    )
                },
            ],
            spacing: RRTheme.cardSpacing
        )
    }

    // MARK: - Profile chooser (used inside General → Profile card)

    @ViewBuilder
    private var profileChooser: some View {
        VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
            VStack(spacing: 10) {
                ForEach(RentoryUserProfile.allCases) { profile in
                    profileRow(for: profile)
                }
            }

            Text(currentProfile.detailedSummary)
                .font(RRTypography.footnote)
                .foregroundStyle(RRColours.mutedText)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(currentProfile.featureHighlights, id: \.self) { highlight in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(RRColours.success)
                            .padding(.top, 2)
                        Text(highlight)
                            .font(RRTypography.footnote)
                            .foregroundStyle(RRColours.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.top, 4)

            if !entitlementManager.isUnlocked && FreePlanLimits.landlordProfileRequiresUnlock {
                Text("Landlord mode is part of the lifetime unlock.")
                    .font(RRTypography.caption.weight(.semibold))
                    .foregroundStyle(RRColours.warning)
            }
        }
    }

    @ViewBuilder
    private func profileRow(for profile: RentoryUserProfile) -> some View {
        let isCurrent = profile == currentProfile
        let isLocked = profile == .landlord
            && !FeatureAccessService.canSwitchToLandlordProfile(isUnlocked: entitlementManager.isUnlocked)

        Button {
            handleProfileChange(to: profile)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: profile.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isCurrent ? .white : RRColours.secondary)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isCurrent ? RRColours.secondary : RRColours.cardHighlight)
                    )

                Text(profile.rawValue)
                    .font(RRTypography.headline)
                    .foregroundStyle(RRColours.primary)

                Spacer(minLength: 8)

                if isCurrent {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(RRColours.success)
                } else if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(RRColours.warning)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isCurrent ? RRColours.cardHighlight : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isCurrent ? RRColours.secondary : RRColours.border, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(profile.rawValue) profile\(isCurrent ? ", selected" : isLocked ? ", locked" : "")")
        .accessibilityHint(isCurrent ? "" : isLocked ? "Shows the lifetime unlock prompt." : "Selects \(profile.rawValue) mode.")
    }

    // MARK: - Leaf destinations

    @ViewBuilder
    private func detailView(for destination: SettingsDetail) -> some View {
        switch destination {
        case .privacyAndData:
            PrivacyAndDataSettingsView()
        case .archivedRecords:
            ArchivedRecordsSettingsView()
        case .iCloudSync:
            ICloudSyncSettingsView()
        case .backups:
            BackupsSettingsView()
        case .purchases:
            PurchaseSettingsView()
        case .activityHistory:
            ActivityHistorySettingsView()
        case .sampleData:
            SampleDataSettingsView()
        case .notifications:
            NotificationSettingsView()
        case .widgets:
            WidgetSettingsView()
        case .feedback:
            SendFeedbackView()
        }
    }

    // MARK: - Card / row helpers

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

    /// On compact (iPhone) this is a NavigationLink so it joins the
    /// outer NavigationStack and gets a chevron / push transition.
    /// On wide (Mac/iPad) it's a Button that flips `selectedDetail`
    /// so the detail column swaps without leaving the modal.
    @ViewBuilder
    private func settingsDestinationAction(_ title: String, destination: SettingsDetail) -> some View {
        if isCompact {
            NavigationLink(title, value: destination)
                .font(RRTypography.body.weight(.semibold))
                .foregroundStyle(RRColours.secondary)
        } else {
            Button(title) {
                selectedDetail = destination
            }
            .buttonStyle(.plain)
            .font(RRTypography.body.weight(.semibold))
            .foregroundStyle(RRColours.secondary)
        }
    }

    // MARK: - Profile binding/handler

    private var currentProfile: RentoryUserProfile {
        RentoryUserProfile(rawValue: profileRawValue) ?? .defaultProfile
    }

    private func handleProfileChange(to newProfile: RentoryUserProfile) {
        guard newProfile != currentProfile else { return }

        if newProfile == .landlord,
           !FeatureAccessService.canSwitchToLandlordProfile(isUnlocked: entitlementManager.isUnlocked) {
            upgradePromptContent = FeatureAccessService.landlordProfilePrompt
            return
        }

        profileRawValue = newProfile.rawValue
    }

    // MARK: - App Lock binding/handler

    private var appLockBinding: Binding<Bool> {
        Binding(
            get: { appSecurityState.isAppLockEnabled },
            set: { handleAppLockChange(to: $0) }
        )
    }

    // Constant per platform — compile-time #if resolves before
    // module init, so a static let avoids re-allocating the literal
    // on every body eval.
    private static let appLockDescription: String = {
        #if os(macOS)
        "Use Touch ID to help keep your rental records private on this Mac. Rentory will ask you to confirm it is you before turning App Lock on."
        #else
        "Use Face ID or Touch ID to help keep your rental records private. Rentory will ask you to confirm it is you before turning App Lock on."
        #endif
    }()

    private func handleAppLockChange(to newValue: Bool) {
        guard newValue != appSecurityState.isAppLockEnabled else { return }

        guard !(newValue && !FeatureAccessService.canUseAppLock(isUnlocked: entitlementManager.isUnlocked)) else {
            upgradePromptContent = FeatureAccessService.appLockLimitPrompt
            return
        }

        Task {
            _ = await appSecurityState.setAppLockEnabled(newValue)
        }
    }

    // MARK: - Derived values

    private var iCloudSettingsValue: String {
        switch iCloudSyncService.syncStatus {
        case .available: return iCloudSyncService.isSyncEnabled ? "On" : "Off"
        case .unavailable: return "Unavailable"
        case .checking: return "Checking"
        case .unknown: return "Unknown"
        }
    }

    private var selectedAppearance: AppAppearance {
        AppAppearance(rawValue: appAppearanceRawValue) ?? .deviceDefault
    }

    private var selectedColourTheme: AppColourTheme {
        AppColourTheme(rawValue: appColourThemeRawValue) ?? .defaultLook
    }

    /// SwiftData's filtered query already only contains archived
    /// packs — we just need the count for the active profile scope.
    /// Filtering in Swift here is cheap because the query has
    /// already pruned everything else.
    private var archivedRecordsCountForProfile: Int {
        archivedPacks.filter { $0.profileRawValue == profileRawValue }.count
    }

    private var archivedRecordsBody: String {
        let count = archivedRecordsCountForProfile
        if count == 0 {
            return "Records you archive will appear here, away from your active list."
        }
        return "\(count) archived record\(count == 1 ? "" : "s") can be restored or permanently deleted."
    }
}

// MARK: - IA enums

private enum SettingsCategory: String, CaseIterable, Hashable, Identifiable {
    case general
    case privacySecurity
    case syncBackups
    case notificationsWidgets
    case data
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "General"
        case .privacySecurity: "Privacy & Security"
        case .syncBackups: "Sync & Backups"
        case .notificationsWidgets: "Notifications & Widgets"
        case .data: "Data"
        case .about: "About"
        }
    }

    var subtitle: String {
        switch self {
        case .general: "Profile, appearance and colour theme."
        case .privacySecurity: "App Lock and how Rentory keeps your records private."
        case .syncBackups: "iCloud sync status and backup export / import."
        case .notificationsWidgets: "Reminder notifications and home-screen surfaces."
        case .data: "Storage, archived records, sample data and activity history."
        case .about: "Version info, Rentory Unlock, feedback and the welcome guide."
        }
    }

    var systemImage: String {
        switch self {
        case .general: "person.crop.circle"
        case .privacySecurity: "lock.shield.fill"
        case .syncBackups: "icloud.and.arrow.up"
        case .notificationsWidgets: "bell.badge"
        case .data: "internaldrive"
        case .about: "info.circle.fill"
        }
    }
}

private enum SettingsDetail: String, Hashable, Identifiable {
    case privacyAndData
    case archivedRecords
    case iCloudSync
    case backups
    case purchases
    case activityHistory
    case sampleData
    case notifications
    case widgets
    case feedback

    var id: String { rawValue }

    var title: String {
        switch self {
        case .privacyAndData: "Storage details"
        case .archivedRecords: "Archived records"
        case .iCloudSync: "iCloud sync"
        case .backups: "Backups"
        case .purchases: "Rentory Unlock"
        case .activityHistory: "Activity history"
        case .sampleData: "Sample data"
        case .notifications: "Notifications"
        case .widgets: "Widgets & Watch"
        case .feedback: "Send feedback"
        }
    }

    var subtitle: String {
        switch self {
        case .privacyAndData:
            return "Manage storage, backups and what stays on this device."
        case .archivedRecords:
            return "Restore archived records or delete them permanently."
        case .iCloudSync:
            return "Check whether iCloud is available for Rentory on this device."
        case .backups:
            return "Export or import a Rentory backup when you want to keep a copy."
        case .purchases:
            return "Manage your lifetime unlock and restore earlier purchases."
        case .activityHistory:
            return "Recent backups, imports, reports, sync attempts and record changes on this device."
        case .sampleData:
            return "Load example records to explore Rentory, or remove them when you are done."
        case .notifications:
            return "Get a heads-up the morning a reminder is due."
        case .widgets:
            return "Glanceable Rentory tiles for iPhone, iPad and Apple Watch."
        case .feedback:
            return "Draft a feedback email in your default mail client."
        }
    }
}
