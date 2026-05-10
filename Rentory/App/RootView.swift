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
    @AppStorage("hasAnsweredExampleRecordsPrompt") private var hasAnsweredExampleRecordsPrompt = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appSecurityState: AppSecurityState
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var iCloudSyncService: ICloudSyncService

    @State private var isShowingExampleRecordsPrompt = false
    @State private var hasScheduledExampleRecordsPrompt = false
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
                scheduleExampleRecordsPromptAfterOnboardingCompletion()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            appSecurityState.handleScenePhaseChange(newPhase)

            Task {
                switch newPhase {
                case .active:
                    await entitlementManager.refreshEntitlements()
                    await iCloudSyncService.refreshStatus()
                    await iCloudSyncService.syncIfNeededForSceneActive(context: modelContext)
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
            try? FileStorageService().cleanupOldTemporaryExports()
            await entitlementManager.refreshEntitlements()
            await iCloudSyncService.refreshStatus()
            await iCloudSyncService.syncIfNeededForSceneActive(context: modelContext)
        }
        .alert("Would you like a few example records?", isPresented: $isShowingExampleRecordsPrompt) {
            Button("Not now", role: .cancel) {
                hasAnsweredExampleRecordsPrompt = true
            }

            Button("Add example records") {
                hasAnsweredExampleRecordsPrompt = true
                exampleRecordsTask = Task {
                    await loadExampleRecords()
                }
            }
        } message: {
            Text("Rentory can add a small set of fictional rental records so you can try rooms, photos, documents, timelines and reports before entering your own details. You can edit or remove them later.")
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

    private func scheduleExampleRecordsPromptAfterOnboardingCompletion() {
        guard !hasAnsweredExampleRecordsPrompt,
              !hasScheduledExampleRecordsPrompt,
              !isShowingExampleRecordsPrompt,
              !isLoadingExampleRecords else {
            return
        }

        hasScheduledExampleRecordsPrompt = true
        hasAnsweredExampleRecordsPrompt = true

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard hasCompletedOnboarding,
                  !isShowingExampleRecordsPrompt,
                  !isLoadingExampleRecords,
                  !appSecurityState.isLocked else {
                return
            }

            isShowingExampleRecordsPrompt = true
        }
    }

    private func loadExampleRecords() async {
        guard !isLoadingExampleRecords else { return }
        isLoadingExampleRecords = true
        exampleRecordsProgress = DemoDataFactory.LoadProgress(
            completedRecords: 0,
            totalRecords: 8,
            stageDescription: "Getting the example records ready."
        )
        await Task.yield()

        let alertContent: RRAlertContent
        do {
            let records = try await demoDataFactory.loadSampleData(context: modelContext, style: .fullSampleSet) { progress in
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
}
