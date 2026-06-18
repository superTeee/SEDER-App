import SwiftUI
import MessageUI

// MARK: - ProfileView
// Profil-fane: viser innlogget bruker, PIN-innstillinger og utlogging.
// Hvis ikke innlogget: enkel "Logg inn"-knapp som åpner AuthView som sheet.

struct ProfileView: View {

    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var pinService: PINService

    @State private var showLoginSheet = false
    @State private var showPINSetup = false
    @State private var showSignOutConfirm = false
    @State private var showRemovePINConfirm = false
    @State private var showFeedbackMail = false
    @State private var showMailUnavailableAlert = false

    var body: some View {
        NavigationStack {
            List {
                if let email = authService.currentUser?.email {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(Color("TextSecondary"))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Innlogget som")
                                    .font(.caption)
                                    .foregroundColor(Color("TextSecondary"))
                                Text(email)
                                    .font(.subheadline.bold())
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Section("Sikkerhet") {
                        if pinService.isPINSet {
                            Button(role: .destructive) {
                                showRemovePINConfirm = true
                            } label: {
                                Label("Fjern PIN-kode", systemImage: "lock.open.fill")
                            }
                        } else {
                            Button {
                                showPINSetup = true
                            } label: {
                                Label("Sett opp 4-sifret kode", systemImage: "lock.fill")
                            }
                        }
                    }

                    Section {
                        Button(role: .destructive) {
                            showSignOutConfirm = true
                        } label: {
                            Label("Logg ut", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                } else {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 48))
                                .foregroundColor(Color("TextSecondary").opacity(0.5))
                            Text("Du er ikke innlogget")
                                .font(.subheadline)
                                .foregroundColor(Color("TextSecondary"))
                            Text("Logg inn for å lagre sigarer i humidoren din")
                                .font(.caption)
                                .foregroundColor(Color("TextSecondary"))
                                .multilineTextAlignment(.center)

                            Button(action: { showLoginSheet = true }) {
                                Text("Logg inn")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color("Accent"))
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                }

                Section("Tilbakemelding") {
                    Button {
                        if MFMailComposeViewController.canSendMail() {
                            showFeedbackMail = true
                        } else if let url = AppFeedback.mailtoURL, UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        } else {
                            showMailUnavailableAlert = true
                        }
                    } label: {
                        Label("Gi tilbakemelding på appen", systemImage: "bubble.left.and.exclamationmark.bubble.right")
                    }
                }
            }
            .navigationTitle("Profil")
            .sheet(isPresented: $showLoginSheet) {
                AuthView()
            }
            .sheet(isPresented: $showPINSetup) {
                PINSetupView()
            }
            .sheet(isPresented: $showFeedbackMail) {
                MailComposeView(
                    recipients: [AppFeedback.recipient],
                    subject: AppFeedback.subject,
                    messageBody: AppFeedback.bodyTemplate
                )
            }
            .alert("Logg ut?", isPresented: $showSignOutConfirm) {
                Button("Avbryt", role: .cancel) {}
                Button("Logg ut", role: .destructive) {
                    Task { try? await authService.signOut() }
                }
            }
            .alert("Fjern PIN-kode?", isPresented: $showRemovePINConfirm) {
                Button("Avbryt", role: .cancel) {}
                Button("Fjern", role: .destructive) { pinService.clearPIN() }
            } message: {
                Text("Du må logge inn med e-post, Apple eller Google neste gang du åpner appen.")
            }
            .alert("Ingen e-post-konto satt opp", isPresented: $showMailUnavailableAlert) {
                Button("Kopier e-postadresse") {
                    UIPasteboard.general.string = AppFeedback.recipient
                }
                Button("OK", role: .cancel) {}
            } message: {
                Text("Send tilbakemeldingen din direkte til \(AppFeedback.recipient)")
            }
        }
    }
}
