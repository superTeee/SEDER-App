import SwiftUI

// MARK: - PINUnlockView
// Lås-skjerm som vises når appen åpnes og brukeren har satt opp en PIN-kode.
// Låser kun opp en allerede aktiv Supabase-sesjon — ved for mange feil kan
// brukeren logge ut og logge inn på nytt med e-post, Apple eller Google.

struct PINUnlockView: View {

    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var pinService: PINService

    @State private var pin = ""
    @State private var errorMessage: String?
    @State private var showSignOutConfirm = false

    var onUnlock: () -> Void

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text("Skriv inn koden din")
                    .font(.title3.bold())

                PINDotsView(filled: pin.count)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Spacer()

                PINKeypad(pin: $pin, onComplete: handleEntry)

                Button("Glemt koden? Logg inn på nytt") {
                    showSignOutConfirm = true
                }
                .font(.subheadline)
                .foregroundColor(Color("Accent"))
                .padding(.bottom, 16)
            }
        }
        .alert("Logg ut?", isPresented: $showSignOutConfirm) {
            Button("Avbryt", role: .cancel) {}
            Button("Logg ut", role: .destructive) {
                Task {
                    pinService.clearPIN()
                    try? await authService.signOut()
                    onUnlock()
                }
            }
        } message: {
            Text("Du logges ut og kan logge inn igjen med e-post, Apple eller Google.")
        }
    }

    private func handleEntry() {
        if pinService.verify(pin) {
            onUnlock()
        } else if pinService.isLockedOut {
            errorMessage = "For mange feil forsøk. Logg inn på nytt for å fortsette."
        } else {
            errorMessage = "Feil kode. \(pinService.attemptsRemaining) forsøk igjen."
            pin = ""
        }
    }
}
