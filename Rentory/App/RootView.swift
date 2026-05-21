//
//  RootView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasAnsweredExampleRecordsPrompt_Renter") private var hasAnsweredRenterPrompt = false
    @AppStorage("hasAnsweredExampleRecordsPrompt_Landlord") private var hasAnsweredLandlordPrompt = false
    @AppStorage(RentoryUserProfile.storageKey) private var profileRawValue = RentoryUserProfile.defaultProfile.rawValue
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appSecurityState: AppSecurityState
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var iCloudSyncService: ICloudSyncService
    @EnvironmentObject private var reminderNotificationService: ReminderNotificationService
    @EnvironmentObject private var watchSyncService: WatchSyncService

    @State private var didWireWatchBridge = false

    @State private var isShowingExampleRecordsPrompt = false
    @State private var pendingPromptProfile: RentoryUserProfile?
    @State private var isLoadingExampleRecords = false
    @State private var exampleRecordsProgress = DemoDataFactory.LoadProgress(
        completedRecords: 0,
        totalRecords: 1,
        stageDescription: "Getting ready."
    )
    @State private var exampleRecordsTask: Task<Void, Never>?
    @State private var rootAlertContent: RRAlertContent?
    @State private var pendingRootAlertContent: RRAlertContent?

    private let demoDataFactory = DemoDataFactory()
    private let snapshotPublisher = RentorySnapshotPublisher()

    private var currentProfile: RentoryUserProfile {
        RentoryUserProfile(rawValue: profileRawValue) ?? .defaultProfile
    }

    var body: some View {
        ZStack {
            mainContent

            if isLoadingExampleRecords {
                RRProgressDialog(
                    title: "Adding example records",
                    message: exampleRecordsProgress.stageDescription,
                    progress: exampleRecordsProgress.fractionCompleted,
                    cancelTitle: "Cancel"
                ) {
                    exampleRecordsTask?.cancel()
                }
                .transition(.opacity)
                .zIndex(1)
            }

            if appSecurityState.shouldShowPrivacyCover {
                PrivacyCoverView()
                    .transition(.opacity)
                    .zIndex(2)
            }

            if appSecurityState.isAppLockEnabled && appSecurityState.isLocked {
                LockedView(
                    isAvailable: appSecurityState.isAppLockAvailable,
                    isAuthenticating: appSecurityState.isAuthenticating
                ) {
                    Task {
                        await appSecurityState.unlockApp()
                    }
                }
                .transition(.opacity)
                .zIndex(3)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: appSecurityState.isLocked)
        .animation(.easeInOut(duration: 0.2), value: appSecurityState.shouldShowPrivacyCover)
        .onChange(of: hasCompletedOnboarding) { wasComplete, didComplete in
            if !wasComplete && didComplete {
                scheduleExampleRecordsPromptIfNeeded(for: currentProfile)
            }
        }
        .onChange(of: profileRawValue) { _, _ in
            guard hasCompletedOnboarding else { return }
            scheduleExampleRecordsPromptIfNeeded(for: currentProfile)
            snapshotPublisher.publish(context: modelContext, activeProfile: currentProfile)
        }
        .onChange(of: scenePhase) { _, newPhase in
            appSecurityState.handleScenePhaseChange(newPhase)

            Task {
                switch newPhase {
                case .active:
                    await entitlementManager.refreshEntitlements()
                    await iCloudSyncService.refreshStatus()
                    await iCloudSyncService.syncIfNeededForSceneActive(context: modelContext)
                    await reminderNotificationService.reschedule(context: modelContext)
                    snapshotPublisher.publish(context: modelContext, activeProfile: currentProfile)
                case .background:
                    await iCloudSyncService.syncBeforeBackground(context: modelContext)
                case .inactive:
                    break
                @unknown default:
                    break
                }
            }
        }
        .task {
            migrateLegacyExampleRecordsPromptFlag()
            try? FileStorageService().cleanupOldTemporaryExports()
            wireWatchBridgeIfNeeded()
            await entitlementManager.refreshEntitlements()
            await iCloudSyncService.refreshStatus()
            await iCloudSyncService.syncIfNeededForSceneActive(context: modelContext)
            await reminderNotificationService.reschedule(context: modelContext)
            snapshotPublisher.publish(context: modelContext, activeProfile: currentProfile)
        }
        .onReceive(NotificationCenter.default.publisher(for: RentorySnapshotPublisher.snapshotShouldRepublish)) { _ in
            // Any feature view that mutates snapshot-visible data
            // (reminders, tenancies, rent payments, expenses, completion-
            // affecting fields) posts this. Republishing is idempotent so
            // multiple posts in quick succession are safe.
            snapshotPublisher.publish(context: modelContext, activeProfile: currentProfile)
        }
        .alert(exampleRecordsPromptTitle, isPresented: $isShowingExampleRecordsPrompt) {
            Button("Not now", role: .cancel) {
                pendingPromptProfile = nil
            }

            Button("Add example records") {
                let profile = pendingPromptProfile ?? currentProfile
                pendingPromptProfile = nil
                exampleRecordsTask = Task {
                    await loadExampleRecords(for: profile)
                }
            }
        } message: {
            Text(exampleRecordsPromptMessage)
        }
        .alert(item: $rootAlertContent) { content in
            Alert(
                title: Text(content.title),
                message: Text(content.message),
                dismissButton: .cancel(Text(content.buttonTitle)) {
                    presentPendingRootAlertIfNeeded()
                }
            )
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if hasCompletedOnboarding {
            if PlatformLayout.prefersSplitView(for: horizontalSizeClass) {
                PropertiesSplitView()
            } else {
                PropertiesListView()
            }
        } else {
            OnboardingView()
        }
    }

    private var exampleRecordsPromptTitle: String {
        switch pendingPromptProfile ?? currentProfile {
        case .renter:
            return "Would you like a few example records?"
        case .landlord:
            return "Would you like a few landlord example records?"
        }
    }

    private var exampleRecordsPromptMessage: String {
        switch pendingPromptProfile ?? currentProfile {
        case .renter:
            return "Rentory can add a small set of fictional rental records so you can try rooms, photos, documents, timelines and reports before entering your own details. You can edit or remove them later."
        case .landlord:
            return "Rentory can add a small set of fictional landlord records — including tenancies, compliance reminders, gas safety, EICR and EPC examples — so you can see how the landlord side works. You can edit or remove them later."
        }
    }

    private func hasAnsweredPrompt(for profile: RentoryUserProfile) -> Bool {
        switch profile {
        case .renter: return hasAnsweredRenterPrompt
        case .landlord: return hasAnsweredLandlordPrompt
        }
    }

    private func setPromptAnswered(_ answered: Bool, for profile: RentoryUserProfile) {
        switch profile {
        case .renter: hasAnsweredRenterPrompt = answered
        case .landlord: hasAnsweredLandlordPrompt = answered
        }
    }

    private func wireWatchBridgeIfNeeded() {
        guard !didWireWatchBridge else { return }
        didWireWatchBridge = true
        snapshotPublisher.onPublish = { [weak watchSyncService] snapshot in
            watchSyncService?.send(snapshot)
        }
        let context = modelContext
        watchSyncService.setPendingReminderHandler { payload in
            WatchPendingReminderApplier.apply(payload, in: context)
        }
    }

    private func migrateLegacyExampleRecordsPromptFlag() {
        let legacyKey = "hasAnsweredExampleRecordsPrompt"
        guard UserDefaults.standard.object(forKey: legacyKey) != nil else { return }
        let wasAnswered = UserDefaults.standard.bool(forKey: legacyKey)
        if wasAnswered {
            hasAnsweredRenterPrompt = true
        }
        UserDefaults.standard.removeObject(forKey: legacyKey)
    }

    private func scheduleExampleRecordsPromptIfNeeded(for profile: RentoryUserProfile) {
        guard !hasAnsweredPrompt(for: profile),
              !isShowingExampleRecordsPrompt,
              !isLoadingExampleRecords else {
            return
        }

        setPromptAnswered(true, for: profile)
        pendingPromptProfile = profile

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard hasCompletedOnboarding,
                  !isShowingExampleRecordsPrompt,
                  !isLoadingExampleRecords,
                  !appSecurityState.isLocked,
                  pendingPromptProfile == profile else {
                return
            }

            isShowingExampleRecordsPrompt = true
        }
    }

    private func loadExampleRecords(for profile: RentoryUserProfile) async {
        guard !isLoadingExampleRecords else { return }
        isLoadingExampleRecords = true
        let totalRecords = demoDataFactory.sampleRecordCount(for: .fullSampleSet, profile: profile)
        exampleRecordsProgress = DemoDataFactory.LoadProgress(
            completedRecords: 0,
            totalRecords: totalRecords,
            stageDescription: "Getting the example records ready."
        )
        await Task.yield()

        let alertContent: RRAlertContent
        do {
            let records = try await demoDataFactory.loadSampleData(
                context: modelContext,
                profile: profile,
                style: .fullSampleSet
            ) { progress in
                Task { @MainActor in
                    exampleRecordsProgress = progress
                }
            }
            alertContent = RRAlertContent(
                title: "Example records added",
                message: "Rentory added \(records.count) fictional records for you to explore. You can edit them, keep them as a starting point or remove them later."
            )
        } catch is CancellationError {
            alertContent = RRAlertContent(
                title: "Example records cancelled",
                message: "Rentory removed the example records that had already been created."
            )
        } catch {
            alertContent = RRAlertContent(
                title: "Example records could not be added",
                message: "Rentory could not add the example records just now. Anything partly created has been removed, so you can try again when you are ready."
            )
        }

        isLoadingExampleRecords = false
        exampleRecordsTask = nil
        enqueueRootAlert(alertContent)
    }

    private func enqueueRootAlert(_ content: RRAlertContent?) {
        guard let content else { return }

        if rootAlertContent != nil || isShowingExampleRecordsPrompt || isLoadingExampleRecords {
            pendingRootAlertContent = content
            return
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard rootAlertContent == nil,
                  !isShowingExampleRecordsPrompt,
                  !isLoadingExampleRecords else {
                pendingRootAlertContent = content
                return
            }

            rootAlertContent = content
        }
    }

    private func presentPendingRootAlertIfNeeded() {
        guard let pendingRootAlertContent else { return }
        self.pendingRootAlertContent = nil
        enqueueRootAlert(pendingRootAlertContent)
    }
}

#Preview("Onboarding") {
    RootView()
        .environmentObject(AppSecurityState())
        .environmentObject(EntitlementManager())
        .environmentObject(ICloudSyncService())
        .environmentObject(ReminderNotificationService())
        .environmentObject(WatchSyncService())
}
