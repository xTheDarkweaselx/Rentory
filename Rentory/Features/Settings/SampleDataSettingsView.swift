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
        // NOTE: We use SwiftUI's native `.confirmationDialog` here
        // instead of the project's `rrConfirmationDialog` because the
        // latter wraps `.alert` with a `Button(role: .destructive,
        // action: onConfirm)`, which — on macOS — silently drops the
        // action closure: the dialog dismisses on tap but onConfirm
        // never fires. `.confirmationDialog` doesn't have that bug.
        .confirmationDialog(
            "Clear demo data?",
            isPresented: $isShowingClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear demo data", role: .destructive) {
                Self.appendDiag("clear confirm onConfirm fired")
                Task {
                    Self.appendDiag("clear confirm Task started")
                    await clearDemoData()
                    Self.appendDiag("clear confirm Task finished")
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
        // No internal "Sample data" heading here — the screen-level
        // RRSheetHeader already provides one, and showing two
        // identical titles back-to-back read as a layout bug. We
        // just lead with the one-line description + status string.
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                Text("Use example records to understand how Rentory works.")
                    .font(RRTypography.body)
                    .foregroundStyle(RRColours.mutedText)

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

    private func clearDemoData() async {
        // Definitive diagnostic — append to a known file in /tmp so we
        // can grep it from a terminal.
        Self.appendDiag("clearDemoData entered, isWorking=\(isWorking) totalPacks=\(propertyPacks.count) demoMatched=\(propertyPacks.filter(DemoModeSettings.matchesDemoRecord).count)")

        guard !isWorking else {
            Self.appendDiag("bailing — isWorking already true")
            return
        }
        isWorking = true
        await Task.yield()
        defer { isWorking = false }

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
            Self.appendDiag("CAUGHT error: \(error)")
            alertContent = RRAlertContent(error: .somethingWentWrong)
        }
        Self.appendDiag("clearDemoData finished, alertContent set=\(alertContent != nil) propertyPacks count after=\(propertyPacks.count)")
    }

    /// Robust diagnostic: append a timestamped line to /tmp/rentory-diag.log
    /// so we can verify from a terminal whether this function is even
    /// being entered (the NSLog approach didn't reach the unified log
    /// for some reason). Will be removed once we've nailed the bug.
    private static func appendDiag(_ msg: String) {
        let path = "/tmp/rentory-diag.log"
        let timestamp = ISO8601DateFormatter().string(from: .now)
        let line = "\(timestamp) \(msg)\n"
        if !FileManager.default.fileExists(atPath: path) {
            try? "".write(toFile: path, atomically: true, encoding: .utf8)
        }
        if let data = line.data(using: .utf8),
           let handle = try? FileHandle(forWritingTo: URL(fileURLWithPath: path)) {
            handle.seekToEndOfFile()
            handle.write(data)
            try? handle.close()
        }
    }
}
