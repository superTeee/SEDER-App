import SwiftUI

// MARK: - ProfileView
// Profil-fane: viser rik UserProfileView for innloggede brukere,
// eller en enkel påloggingsskjerm hvis brukeren ikke er innlogget.

struct ProfileView: View {

    @EnvironmentObject var authService: AuthService

    @State private var showLoginSheet = false

    var body: some View {
        NavigationStack {
            if let userId = authService.userId {
                UserProfileView(userId: userId, isOwnProfile: true)
                    .environmentObject(authService)
            } else {
                notLoggedInView
            }
        }
    }

    // MARK: - Ikke innlogget

    private var notLoggedInView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "person.crop.circle")
                .font(.system(size: 64))
                .foregroundColor(Color("TextSecondary").opacity(0.4))
            Text("Du er ikke innlogget")
                .font(.title3.weight(.semibold))
                .foregroundColor(Color("TextPrimary"))
            Text("Logg inn for å se profilen din, lagre sigarer og koble deg til venner.")
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button(action: { showLoginSheet = true }) {
                Text("Logg inn")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color("Accent"))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .padding(.horizontal, 32)
            Spacer()
        }
        .background(Color("Background"))
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLoginSheet) { AuthView() }
    }
}

// MARK: - EditNameSheet

struct EditNameSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    @State private var nameText = ""
    @State private var isSaving = false

    private let profileService = ProfileService()

    var body: some View {
        NavigationStack {
            Form {
                Section("Visningsnavn") {
                    TextField("Skriv inn navn", text: $nameText)
                        .autocorrectionDisabled()
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color("Background"))
            .navigationTitle("Endre navn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lagre") {
                        saveName()
                    }
                    .disabled(nameText.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
        }
        .presentationDetents([.height(200)])
    }

    private func saveName() {
        guard let uid = authService.userId, !nameText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSaving = true
        Task {
            try? await profileService.updateProfile(userId: uid, displayName: nameText.trimmingCharacters(in: .whitespaces), city: nil)
            isSaving = false
            dismiss()
        }
    }
}

// MARK: - EditLocationSheet

struct EditLocationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    @State private var city = ""
    @State private var country = ""
    @State private var isSaving = false

    private let profileService = ProfileService()

    var body: some View {
        NavigationStack {
            Form {
                Section("Lokasjon") {
                    TextField("By (f.eks. Oslo)", text: $city)
                        .autocorrectionDisabled()
                    TextField("Land (f.eks. Norge)", text: $country)
                        .autocorrectionDisabled()
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color("Background"))
            .navigationTitle("Endre sted")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lagre") { save() }
                        .disabled(isSaving)
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.height(240)])
        .task { await loadCurrent() }
    }

    private func loadCurrent() async {
        guard let uid = authService.userId else { return }
        if let profile = try? await profileService.fetchOwnProfile(userId: uid) {
            city    = profile.city    ?? ""
            country = profile.country ?? ""
        }
    }

    private func save() {
        guard let uid = authService.userId else { return }
        isSaving = true
        Task {
            try? await profileService.updateProfile(
                userId: uid,
                displayName: nil,
                city: city.trimmingCharacters(in: .whitespacesAndNewlines),
                country: country.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            isSaving = false
            dismiss()
        }
    }
}

// MARK: - ProfileSettingsView
// Innstillinger-sheet som åpnes fra tannhjul-knappen i UserProfileView

struct ProfileSettingsView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var pinService: PINService

    @State private var showPINSetup              = false
    @State private var showSignOutConfirm        = false
    @State private var showDeleteAccountConfirm  = false
    @State private var showRemovePINConfirm      = false
    @State private var showFeedbackSheet         = false
    @State private var showEditName              = false
    @State private var showEditLocation          = false
    @State private var isDeletingAccount         = false
    @State private var deleteAccountError: String?

    // Lys/mørk-modus — deles med app-roten via samme AppStorage-nøkkel
    @AppStorage("appearance") private var appearance = "system"

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
                }

                Section("Profil") {
                    Button {
                        showEditName = true
                    } label: {
                        Label("Endre navn", systemImage: "person.text.rectangle")
                    }
                    Button {
                        showEditLocation = true
                    } label: {
                        Label("Endre by og land", systemImage: "mappin.circle")
                    }
                }

                Section("Utseende") {
                    Picker("Tema", selection: $appearance) {
                        Text("System").tag("system")
                        Text("Mørk").tag("dark")
                        Text("Lys").tag("light")
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color("Card"))
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

                Section("Tilbakemelding") {
                    Button {
                        showFeedbackSheet = true
                    } label: {
                        Label("Gi tilbakemelding på appen", systemImage: "bubble.left.and.exclamationmark.bubble.right")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showSignOutConfirm = true
                    } label: {
                        Label("Logg ut", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteAccountConfirm = true
                    } label: {
                        if isDeletingAccount {
                            HStack {
                                ProgressView().tint(.red)
                                Text("Sletter konto…")
                            }
                        } else {
                            Label("Slett konto", systemImage: "person.crop.circle.badge.minus")
                        }
                    }
                    .disabled(isDeletingAccount)
                } footer: {
                    Text("Dette sletter kontoen din og alle tilhørende data permanent. Handlingen kan ikke angres.")
                        .font(.caption)
                        .foregroundColor(Color("TextSecondary"))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color("Background"))
            .navigationTitle("Innstillinger")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Ferdig") { dismiss() }
                }
            }
            .sheet(isPresented: $showPINSetup) { PINSetupView() }
            .sheet(isPresented: $showFeedbackSheet) {
                FeedbackSheet().environmentObject(authService)
            }
            .sheet(isPresented: $showEditName) {
                EditNameSheet()
                    .environmentObject(authService)
            }
            .sheet(isPresented: $showEditLocation) {
                EditLocationSheet()
                    .environmentObject(authService)
            }
            .alert("Logg ut?", isPresented: $showSignOutConfirm) {
                Button("Avbryt", role: .cancel) {}
                Button("Logg ut", role: .destructive) {
                    Task {
                        try? await authService.signOut()
                        dismiss()
                    }
                }
            }
            .alert("Fjern PIN-kode?", isPresented: $showRemovePINConfirm) {
                Button("Avbryt", role: .cancel) {}
                Button("Fjern", role: .destructive) { pinService.clearPIN() }
            } message: {
                Text("Du må logge inn med e-post, Apple eller Google neste gang du åpner appen.")
            }
            .alert("Slett konto?", isPresented: $showDeleteAccountConfirm) {
                Button("Avbryt", role: .cancel) {}
                Button("Slett konto", role: .destructive) {
                    isDeletingAccount = true
                    Task {
                        do {
                            try await authService.deleteAccount()
                            dismiss()
                        } catch {
                            deleteAccountError = error.localizedDescription
                        }
                        isDeletingAccount = false
                    }
                }
            } message: {
                Text("All data din — sigarer, notater og profil — slettes permanent. Dette kan ikke angres.")
            }
            .alert("Kunne ikke slette konto", isPresented: Binding(
                get: { deleteAccountError != nil },
                set: { if !$0 { deleteAccountError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deleteAccountError ?? "")
            }
        }
    }
}
