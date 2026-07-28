import SwiftUI
import MessageUI

// MARK: - FeedbackSheet
// In-app tilbakemeldingsskjema. Brukeren skriver meldingen sin,
// trykker "Send" og meldingen går til support@sederappen.no via
// MFMailComposeViewController (eller mailto:-fallback).

struct FeedbackSheet: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService

    @State private var message: String = ""
    @State private var showMailCompose = false
    @State private var showMailUnavailable = false
    @FocusState private var editorFocused: Bool

    private let maxChars = 1000

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // ── Intro ──────────────────────────────────────────────
                    Text("Hva tenker du på? Bugs, ideer, ros – alt er\nvelkommen.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    // ── Tekstfelt ──────────────────────────────────────────
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(editorFocused
                                            ? Color("Accent")
                                            : Color(.separator),
                                            lineWidth: editorFocused ? 1.5 : 1)
                            )

                        if message.isEmpty {
                            Text("Skriv din tilbakemelding her…")
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: $message)
                            .focused($editorFocused)
                            .frame(minHeight: 160)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .scrollContentBackground(.hidden)
                            .onChange(of: message) { _, new in
                                if new.count > maxChars {
                                    message = String(new.prefix(maxChars))
                                }
                            }
                    }

                    // ── Tegnteller ─────────────────────────────────────────
                    HStack {
                        Spacer()
                        Text("\(message.count) / \(maxChars)")
                            .font(.caption2)
                            .foregroundStyle(message.count > maxChars - 50 ? .orange : .secondary)
                            .monospacedDigit()
                    }

                    // ── Send-knapp ─────────────────────────────────────────
                    Button(action: sendFeedback) {
                        Text("Send tilbakemelding")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(trimmedMessage.isEmpty
                                        ? Color("Accent").opacity(0.35)
                                        : Color("Accent"))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .disabled(trimmedMessage.isEmpty)

                    Spacer(minLength: 24)
                }
                .padding()
            }
            .background(Color("Background"))
            .navigationTitle("Gi tilbakemelding")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
            }
            // MFMailComposeViewController vist som sheet inni denne sheeten
            .sheet(isPresented: $showMailCompose) {
                MailComposeView(
                    recipients: [AppFeedback.recipient],
                    subject: AppFeedback.subject,
                    messageBody: buildEmailBody()
                ) {
                    // Lukk FeedbackSheet når Mail-composer er ferdig
                    dismiss()
                }
            }
            .alert("Ingen e-postklient funnet", isPresented: $showMailUnavailable) {
                Button("Kopier e-postadresse") {
                    UIPasteboard.general.string = AppFeedback.recipient
                }
                Button("OK", role: .cancel) {}
            } message: {
                Text("Send tilbakemeldingen din direkte til \(AppFeedback.recipient)")
            }
        }
    }

    // MARK: - Helpers

    private var trimmedMessage: String {
        message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func sendFeedback() {
        guard !trimmedMessage.isEmpty else { return }
        editorFocused = false

        if MFMailComposeViewController.canSendMail() {
            showMailCompose = true
        } else if let url = buildMailtoURL(), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            dismiss()
        } else {
            showMailUnavailable = true
        }
    }

    private func buildEmailBody() -> String {
        let version   = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build     = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        let ios       = UIDevice.current.systemVersion
        let model     = UIDevice.current.model
        let userEmail = authService.currentUser?.email ?? "ikke innlogget"
        return """
        \(trimmedMessage)


        ---
        Fra: \(userEmail)
        App-versjon: \(version) (\(build))
        iOS: \(ios)
        Enhet: \(model)
        """
    }

    private func buildMailtoURL() -> URL? {
        var c = URLComponents()
        c.scheme = "mailto"
        c.path   = AppFeedback.recipient
        c.queryItems = [
            URLQueryItem(name: "subject", value: AppFeedback.subject),
            URLQueryItem(name: "body",    value: buildEmailBody())
        ]
        return c.url
    }
}
