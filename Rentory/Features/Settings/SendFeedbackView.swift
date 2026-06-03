//
//  SendFeedbackView.swift
//  Rentory
//
//  Lets the user compose a feedback message and hand it off to their
//  default mail client as a pre-filled `mailto:` draft. Doesn't send
//  anything itself — the network surface is always Mail.app (the
//  user's choice), keeping the local-first contract intact.
//

import SwiftUI

@MainActor
struct SendFeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.rrUsesEmbeddedNavigationLayout) private var usesEmbeddedNavigationLayout

    @State private var category: FeedbackCategory = .bug
    @State private var subject: String = "Rentory feedback"
    @State private var messageBody: String = ""
    @State private var attachScreenshot = false
    @State private var attachActivityLog = false
    @State private var alertContent: RRAlertContent?

    var body: some View {
        Group {
            if PlatformLayout.isPhone && horizontalSizeClass != .regular {
                compactView
            } else if usesEmbeddedNavigationLayout {
                // Embedded inside the wide Settings panel, which already
                // shows the title + description via its own in-panel
                // header. Drop the RRSheetHeader here so the page doesn't
                // stack a second "Send feedback" header on top of it.
                RRFormContainer(maxWidth: 720) {
                    VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                        messagePanel
                        attachmentsPanel
                        actionButtons
                    }
                }
            } else {
                RRMacSheetContainer(maxWidth: 720, minHeight: PlatformLayout.isMac ? 640 : nil) {
                    VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                        RRSheetHeader(
                            title: "Send feedback",
                            subtitle: "Tell me what felt off, what you’d love to see next, or what happened when something didn’t behave as expected.",
                            systemImage: "envelope.open"
                        )

                        messagePanel
                        attachmentsPanel
                        actionButtons
                    }
                }
            }
        }
        .rrSettingsLeafNavigationTitle("Send feedback")
        .alert(item: $alertContent) { content in
            Alert(
                title: Text(content.title),
                message: Text(content.message),
                dismissButton: .cancel(Text(content.buttonTitle))
            )
        }
    }

    // MARK: - Compact (iPhone)

    private var compactView: some View {
        Form {
            Section {
                Picker("Category", selection: $category) {
                    ForEach(FeedbackCategory.allCases) { category in
                        Text(category.title).tag(category)
                    }
                }

                TextField("Subject", text: $subject)

                ZStack(alignment: .topLeading) {
                    if messageBody.isEmpty {
                        Text("What would you like to share?")
                            .foregroundStyle(RRColours.mutedText)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $messageBody)
                        .frame(minHeight: 140)
                }
            } header: {
                Text("Your message")
            } footer: {
                Text("Tell me what felt off, what you’d love to see next, or what happened when something didn’t behave as expected.")
            }

            Section {
                Toggle("Attach a screenshot", isOn: $attachScreenshot)
                Toggle("Attach recent activity log", isOn: $attachActivityLog)
            } header: {
                Text("Attachments")
            } footer: {
                Text("Optional. Add supporting context if it helps explain what you saw.")
            }

            Section {
                RRPrimaryButton(title: "Open in Mail", isDisabled: !canSubmit) {
                    openMail()
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(RRBackgroundView())
    }

    // MARK: - Wide (iPad / Mac)

    private var messagePanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                Text("Your message")
                    .font(RRTypography.headline)
                    .foregroundStyle(RRColours.primary)

                Text("Tell me what felt off, what you’d love to see next, or what happened when something didn’t behave as expected.")
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)
                    .fixedSize(horizontal: false, vertical: true)

                labelledField("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(FeedbackCategory.allCases) { category in
                            Text(category.title).tag(category)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .tint(RRColours.secondary)
                }

                labelledField("Subject") {
                    TextField("Rentory feedback", text: $subject)
                        .textFieldStyle(.roundedBorder)
                }

                labelledField("Feedback") {
                    ZStack(alignment: .topLeading) {
                        if messageBody.isEmpty {
                            Text("What would you like to share?")
                                .font(RRTypography.body)
                                .foregroundStyle(RRColours.mutedText)
                                .padding(.top, 10)
                                .padding(.leading, 6)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $messageBody)
                            .font(RRTypography.body)
                            .frame(minHeight: 160)
                            .scrollContentBackground(.hidden)
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(RRColours.cardHighlight.opacity(0.55))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(RRColours.border.opacity(0.4), lineWidth: 1)
                            )
                    }
                }
            }
        }
    }

    private var attachmentsPanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                Text("Attachments")
                    .font(RRTypography.headline)
                    .foregroundStyle(RRColours.primary)

                Text("Add supporting context if it helps explain what you saw.")
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)
                    .fixedSize(horizontal: false, vertical: true)

                attachmentRow(
                    title: "Attach a screenshot",
                    description: "Reminds you to attach an image showing the screen, message or layout in question when the email draft opens.",
                    isOn: $attachScreenshot
                )

                Divider().background(RRColours.border.opacity(0.4))

                attachmentRow(
                    title: "Attach recent activity log",
                    description: "Appends up to the last 20 Rentory activity entries (backups, reports, sync attempts) to the email body. Helps with diagnosing bugs.",
                    isOn: $attachActivityLog
                )
            }
        }
    }

    @ViewBuilder
    private func attachmentRow(title: String, description: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(RRTypography.body.weight(.semibold))
                    .foregroundStyle(RRColours.primary)
                Text(description)
                    .font(RRTypography.caption)
                    .foregroundStyle(RRColours.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .toggleStyle(.switch)
        .tint(RRColours.secondary)
    }

    @ViewBuilder
    private func labelledField<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(RRTypography.caption.weight(.semibold))
                .foregroundStyle(RRColours.secondary)
            content()
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            RRSecondaryButton(title: "Cancel") {
                dismiss()
            }
            RRPrimaryButton(title: "Open in Mail", isDisabled: !canSubmit) {
                openMail()
            }
        }
    }

    // MARK: - Submit

    /// Both subject and message must be non-empty to enable
    /// "Open in Mail". An empty draft would just confuse the
    /// mail client.
    private var canSubmit: Bool {
        !subject.trimmingCharacters(in: .whitespaces).isEmpty
            && !messageBody.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func openMail() {
        let composedSubject = "[\(category.title)] \(subject.trimmingCharacters(in: .whitespaces))"
        let composedBody = buildEmailBody()

        guard let url = makeMailtoURL(
            to: RentoryLocalConfig.feedbackRecipientEmail,
            subject: composedSubject,
            body: composedBody
        ) else {
            alertContent = RRAlertContent(error: .somethingWentWrong)
            return
        }

        openURL(url) { accepted in
            Task { @MainActor in
                if accepted {
                    RentoryActivityLog.record(
                        kind: .record,
                        title: "Feedback drafted",
                        message: "Opened Mail with a \(category.title.lowercased()) feedback draft."
                    )
                    dismiss()
                } else {
                    alertContent = RRAlertContent(
                        title: "No mail client found",
                        message: "Rentory tried to open a feedback email but no mail client responded. Make sure Mail (or another mail app) is set up, then try again."
                    )
                }
            }
        }
    }

    private func buildEmailBody() -> String {
        var sections: [String] = [messageBody.trimmingCharacters(in: .whitespacesAndNewlines)]

        if attachScreenshot {
            sections.append("— Reminder: please attach the relevant screenshot in Mail before sending.")
        }

        if attachActivityLog {
            let recent = Array(RentoryActivityLog.entries.prefix(20))
            if recent.isEmpty {
                sections.append("— Recent activity log: (no entries yet)")
            } else {
                let formatter = ISO8601DateFormatter()
                let entries = recent.map { entry in
                    "[\(formatter.string(from: entry.createdAt))] [\(entry.kind.rawValue)] \(entry.title) — \(entry.message)"
                }
                sections.append("— Recent activity log (most recent first):\n" + entries.joined(separator: "\n"))
            }
        }

        if let version = AppBundleInfo.shortVersion {
            let build = AppBundleInfo.buildNumber ?? "?"
            sections.append("— Sent from Rentory \(version) (build \(build))")
        }

        return sections.joined(separator: "\n\n")
    }

    private func makeMailtoURL(to recipient: String, subject: String, body: String) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = recipient
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body),
        ]
        return components.url
    }
}

enum FeedbackCategory: String, CaseIterable, Identifiable {
    case bug = "Bug"
    case featureRequest = "Feature request"
    case general = "General feedback"
    case question = "Question"

    var id: String { rawValue }
    var title: String { rawValue }
}
