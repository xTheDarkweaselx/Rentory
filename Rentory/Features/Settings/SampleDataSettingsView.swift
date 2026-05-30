//
//  SampleDataSettingsView.swift
//  Rentory
//
//  Created by OpenAI on 02/05/2026.
//

import SwiftData
import SwiftUI

@MainActor
struct SampleDataSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.rrUsesEmbeddedNavigationLayout) private var usesEmbeddedNavigationLayout
    @Query private var propertyPacks: [PropertyPack]
    @AppStorage(RentoryUserProfile.storageKey) private var profileRawValue = RentoryUserProfile.defaultProfile.rawValue

    @State private var isShowingLoadConfirmation = false
    @State private var isShowingClearConfirmation = false
    @State private var alertContent: RRAlertContent?
    @State private var isWorking = false
    @State private var loadProgress = DemoDataFactory.LoadProgress(
        completedRecords: 0,
        totalRecords: 1,
        stageDescription: "Getting ready."
    )
    @State private var loadTask: Task<Void, Never>?
    @State private var loadsFullSampleSet = true

    private let demoDataFactory = DemoDataFactory()

    private var currentProfile: RentoryUserProfile {
        RentoryUserProfile(rawValue: profileRawValue) ?? .defaultProfile
    }

    private var profileScopedPropertyPacks: [PropertyPack] {
        propertyPacks.filter { $0.profileRawValue == profileRawValue }
    }

    /// Demo records on the currently active profile only — used for
    /// the "X sample records ready to use" status line.
    private var profileScopedDemoRecordCount: Int {
        profileScopedPropertyPacks.filter(DemoModeSettings.matchesDemoRecord).count
    }

    /// Demo records across every profile. The Clear button uses this
    /// because users expect "Clear demo data" to remove ALL the
    /// demo records they can see in the app, not just the ones tied
    /// to whichever profile happens to be selected right now —
    /// otherwise tapping it appears to silently do nothing when the
    /// records were created on a different profile.
    private var totalDemoRecordCount: Int {
        propertyPacks.filter(DemoModeSettings.matchesDemoRecord).count
    }

    private var hasDemoRecord: Bool {
        totalDemoRecordCount > 0
    }

    private var profileSampleSetSize: Int {
        demoDataFactory.sampleRecordCount(for: .fullSampleSet, profile: currentProfile)
    }

    var body: some View {
        Group {
            if PlatformLayout.isPhone && horizontalSizeClass != .regular {
                compactView
            } else if usesEmbeddedNavigationLayout {
                RRFormContainer(maxWidth: 880) {
                    RRResponsiveFormGrid(items: [
                        RRResponsiveFormGridItem {
                            statusPanel
                        },
                        RRResponsiveFormGridItem {
                            actionsPanel
                        },
                    ])
                }
            } else {
                RRMacSheetContainer(maxWidth: 880, minHeight: PlatformLayout.isMac ? 560 : nil) {
                    VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                        RRSheetHeader(
                            title: "Sample Data",
                            subtitle: "Use example records to understand how Rentory works.",
                            systemImage: "wand.and.stars"
                        )

                        RRResponsiveFormGrid(items: [
                            RRResponsiveFormGridItem {
                                statusPanel
                            },
                            RRResponsiveFormGridItem {
                                actionsPanel
                            },
                        ])
                    }
                }
            }
        }
        .navigationTitle("Sample data")
        .rrInlineNavigationTitle()
        .overlay {
            if isWorking {
                RRProgressDialog(
                    title: "Preparing demo data",
                    message: loadProgress.stageDescription,
                    progress: loadProgress.fractionCompleted,
                    cancelTitle: "Cancel"
                ) {
                    loadTask?.cancel()
                }
            }
        }
        .rrConfirmationDialog(
            RRDialogContent(
                title: loadsFullSampleSet ? "Load sample set?" : "Load sample record?",
                message: loadsFullSampleSet
                    ? "This adds a fuller set of example records, rooms, photos, documents and timeline events for exploring Rentory."
                    : "This adds one example rental record for exploring Rentory.",
                confirmTitle: loadsFullSampleSet ? "Load sample set" : "Load sample record",
                cancelTitle: "Cancel"
            ),
            isPresented: $isShowingLoadConfirmation
        ) {
            loadTask = Task {
                await loadDemoRecord()
            }
        }
        // NOTE: Two earlier attempts at wiring this confirmation
        // both failed on macOS: first `.alert` via
        // `rrConfirmationDialog` with `Button(role: .destructive,
        // action:)`, then `.confirmationDialog` with the same
        // destructive-role pattern. In both cases the dialog
        // dismissed on tap but the confirm closure never ran.
        // The destructive role is the common factor.
        //
        // This version drops the destructive role and uses
        // `.confirmationDialog` — NOT `.alert`. Adding a third
        // `.alert` modifier would collide with the Load
        // confirmation (`rrConfirmationDialog` wraps `.alert`)
        // and the result presenter (`.alert(item: $alertContent)`);
        // `.confirmationDialog` is a different modifier kind and
        // stacks cleanly. The confirm closure schedules
        // `clearDemoData()` on a Task so the SwiftData mutation +
        // alertContent state change run on the next runloop tick
        // after the dialog has finished tearing down — mirroring
        // the Load flow, which uses the same pattern and works.
        // The "destructive" cue is carried by the message text.
        .confirmationDialog(
            "Clear demo data?",
            isPresented: $isShowingClearConfirmation,
            titleVisibility: .visible
        ) {
            // Defer the actual clear into a Task so the modelContext
            // mutation + alertContent state change happen on the
            // runloop tick *after* the dialog has finished
            // dismissing. The Load flow uses the same shape
            // (`Task { await loadDemoRecord() }` inside its dialog
            // confirm) and fires reliably, so we mirror it.
            Button("Clear demo data") {
                Task { @MainActor in
                    clearDemoData()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the sample records and their sample files.")
        }
        .alert(item: $alertContent) { content in
            Alert(
                title: Text(content.title),
                message: Text(content.message),
                dismissButton: .cancel(Text(content.buttonTitle))
            )
        }
    }

    private var compactView: some View {
        Form {
            Section("Sample data") {
                Text(statusText)
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)

                Toggle("Load the fullest sample set", isOn: $loadsFullSampleSet)
            }

            Section {
                RRPrimaryButton(title: loadsFullSampleSet ? "Load sample set" : "Load sample record", isDisabled: isWorking) {
                    isShowingLoadConfirmation = true
                }

                clearDemoButton
            }
        }
        .scrollContentBackground(.hidden)
        .background(RRBackgroundView())
    }

    /// The Clear demo data button plus a one-line explanation when it
    /// would be disabled. Without the explanation a tap on the (now
    /// visually-greyed) button looks unresponsive — the subtitle tells
    /// the user *why* the action isn't currently available, so they
    /// can switch profile, load sample data, or take whatever next
    /// step makes sense.
    @ViewBuilder
    private var clearDemoButton: some View {
        VStack(alignment: .leading, spacing: 6) {
            RRDestructiveButton(title: "Clear demo data", isDisabled: isWorking || !hasDemoRecord) {
                isShowingClearConfirmation = true
            }

            if !isWorking, !hasDemoRecord {
                Text("No sample records on this device yet. Tap Load above to add some.")
                    .font(RRTypography.caption)
                    .foregroundStyle(RRColours.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var statusPanel: some View {
        // No internal "Sample data" heading and no internal
        // description line here — the screen-level container
        // (either `destinationDetailView`'s RRGlassPanel header
        // when navigated from Settings, or `RRSheetHeader` when
        // shown standalone) already provides both. Showing them
        // again inside this panel read as a duplicate "Sample
        // data" box stacked under the header. Lead straight with
        // the status string + toggle.
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                Text(statusText)
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)

                Toggle("Load the fullest sample set", isOn: $loadsFullSampleSet)
                    .toggleStyle(.switch)
            }
        }
    }

    /// Status line shown under the description. Reports total demo
    /// records across all profiles when there are any, with a hint
    /// about the active profile when records are split between
    /// profiles. Falls back to a friendly empty-state line otherwise.
    private var statusText: String {
        guard totalDemoRecordCount > 0 else {
            return "No sample records have been loaded yet."
        }
        let totalNoun = totalDemoRecordCount == 1 ? "sample record" : "sample records"
        if profileScopedDemoRecordCount == totalDemoRecordCount {
            return "\(totalDemoRecordCount) \(totalNoun) ready to use."
        }
        return "\(totalDemoRecordCount) \(totalNoun) on this device (\(profileScopedDemoRecordCount) on the \(currentProfile.rawValue.lowercased()) profile)."
    }

    private var actionsPanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                Text("Actions")
                    .font(RRTypography.headline)

                RRPrimaryButton(title: loadsFullSampleSet ? "Load sample set" : "Load sample record", isDisabled: isWorking) {
                    isShowingLoadConfirmation = true
                }

                clearDemoButton
            }
        }
    }

    private func loadDemoRecord() async {
        guard !isWorking else { return }
        isWorking = true
        let totalRecords = loadsFullSampleSet ? profileSampleSetSize : 1
        loadProgress = DemoDataFactory.LoadProgress(
            completedRecords: 0,
            totalRecords: totalRecords,
            stageDescription: "Getting the sample data ready."
        )
        let profile = currentProfile
        await Task.yield()
        defer {
            isWorking = false
            loadTask = nil
        }

        do {
            let style: DemoDataFactory.SampleDataStyle = loadsFullSampleSet ? .fullSampleSet : .singleRecord
            let loadedRecords = try await demoDataFactory.loadSampleData(
                context: modelContext,
                profile: profile,
                style: style
            ) { progress in
                Task { @MainActor in
                    loadProgress = progress
                }
            }
            alertContent = RRAlertContent(
                title: loadsFullSampleSet ? "Sample set ready" : "Sample record ready",
                message: loadsFullSampleSet
                    ? "\(loadedRecords.count) sample records are ready to explore."
                    : "Sample data is ready to explore."
            )
            RentoryActivityLog.record(
                kind: .sampleData,
                title: loadsFullSampleSet ? "Sample set loaded" : "Sample record loaded",
                message: "Added \(loadedRecords.count) sample \(profile.rawValue.lowercased()) record\(loadedRecords.count == 1 ? "" : "s") to this device."
            )
        } catch is CancellationError {
            alertContent = RRAlertContent(
                title: "Sample data cancelled",
                message: "Rentory removed the sample data that had already been created."
            )
        } catch {
            alertContent = RRAlertContent(
                title: "Sample data could not be loaded",
                message: "Rentory could not load the sample data just now. Anything partly created has been removed."
            )
        }
    }

    /// Synchronous because `demoDataFactory.clearDemoData` is
    /// itself synchronous (SwiftData fetch + cascade delete) and
    /// runs fast enough that the UI doesn't need a progress
    /// overlay. Caller wraps the invocation in `Task { @MainActor in }`
    /// so the actual mutation runs on the runloop tick *after* the
    /// confirmation dialog has fully torn down.
    private func clearDemoData() {
        do {
            // Clear across every profile rather than only the active
            // one. The user-visible expectation is "clear all the
            // sample records I can see in the app" — restricting to
            // the current profile was previously firing the
            // "Sample data cleared" alert even when zero records
            // matched, which read as the action silently doing
            // nothing.
            let clearedCount = try demoDataFactory.clearDemoData(context: modelContext, profile: nil)
            let noun = clearedCount == 1 ? "sample record" : "sample records"
            alertContent = RRAlertContent(
                title: clearedCount > 0 ? "Sample data cleared" : "No sample records to clear",
                message: clearedCount > 0
                    ? "Removed \(clearedCount) \(noun) and their files."
                    : "Rentory could not find any sample records on this device to remove."
            )
            if clearedCount > 0 {
                RentoryActivityLog.record(
                    kind: .sampleData,
                    title: "Sample data cleared",
                    message: "Removed \(clearedCount) sample \(noun) and the matching sample files from this device."
                )
            }
        } catch {
            alertContent = RRAlertContent(error: .somethingWentWrong)
        }
    }
}
