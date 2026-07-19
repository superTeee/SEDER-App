import SwiftUI

// MARK: - OnboardingProfileView
// Vises én gang etter første innlogging hvis brukeren ikke har satt visningsnavn.
// Viser innlogget e-post (read-only) så brukeren ser hvilken konto de er på,
// og samler et visningsnavn som lagres til profiles-tabellen.

struct OnboardingProfileView: View {

    @EnvironmentObject var authService: AuthService
    var onComplete: () -> Void

    @State private var nameText = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let profileService = ProfileService()

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: - Header
                VStack(spacing: 12) {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.bottom, 4)

                    Text("Velkommen til SEDER")
                        .font(.title2.bold())
                        .foregroundColor(Color("TextPrimary"))

                    Text("Sett opp profilen din for å komme i gang")
                        .font(.subheadline)
                        .foregroundColor(Color("TextSecondary"))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 72)
                .padding(.horizontal, 32)

                Spacer()

                // MARK: - Skjema
                VStack(spacing: 14) {

                    // E-post — vises read-only så brukeren ser hvilken konto
                    if let email = authService.currentUser?.email {
                        HStack(spacing: 10) {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(Color("TextSecondary"))
                                .frame(width: 20)
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(Color("TextSecondary"))
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color("Card"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Navn
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Visningsnavn")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color("TextSecondary"))
                            .padding(.leading, 4)

                        HStack(spacing: 10) {
                            Image(systemName: "person.fill")
                                .foregroundColor(Color("TextSecondary"))
                                .frame(width: 20)
                            TextField("Hva vil du hete?", text: $nameText)
                                .font(.body)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.words)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color("Card"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 4)
                    }

                    // Kom i gang
                    Button(action: save) {
                        Group {
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Text("Kom i gang")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(nameIsValid ? Color("Accent") : Color("TextSecondary").opacity(0.25))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!nameIsValid || isSaving)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
            }
        }
        .onAppear {
            // Pre-fyll med navn fra Google hvis tilgjengelig
            if let pending = authService.pendingDisplayName, !pending.isEmpty {
                nameText = pending
            }
        }
    }

    private var nameIsValid: Bool {
        !nameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        guard let uid = authService.userId, nameIsValid else { return }
        let name = nameText.trimmingCharacters(in: .whitespacesAndNewlines)
        isSaving = true
        Task {
            do {
                try await profileService.updateProfile(userId: uid, displayName: name, city: nil)
                authService.pendingDisplayName = nil
                onComplete()
            } catch {
                errorMessage = "Kunne ikke lagre: \(error.localizedDescription)"
            }
            isSaving = false
        }
    }
}
