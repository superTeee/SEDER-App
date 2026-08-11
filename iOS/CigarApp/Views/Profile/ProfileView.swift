import SwiftUI

// MARK: - ProfileView
// Profil-fane: viser rik UserProfileView for innloggede brukere,
// eller en enkel påloggingsskjerm hvis brukeren ikke er innlogget.

struct ProfileView: View {

    @EnvironmentObject var authService: AuthService

    /// Settes når profilen presenteres modalt (fra avatar-knappen) → viser lukk-knapp.
    var onClose: (() -> Void)? = nil

    @State private var showLoginSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if let userId = authService.userId {
                    UserProfileView(userId: userId, isOwnProfile: true)
                        .environmentObject(authService)
                } else {
                    notLoggedInView
                }
            }
            .toolbar {
                if let onClose {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: onClose) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color("TextPrimary"))
                        }
                        .accessibilityLabel("Lukk")
                    }
                }
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
            Text("Logg inn for å se profilen din, lagre sigarer og bygge samlingen din.")
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
            await attempt("Lagre visningsnavn") {
                try await profileService.updateProfile(userId: uid, displayName: nameText.trimmingCharacters(in: .whitespaces), city: nil)
            }
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
            await attempt("Lagre sted") {
                try await profileService.updateProfile(
                    userId: uid,
                    displayName: nil,
                    city: city.trimmingCharacters(in: .whitespacesAndNewlines),
                    country: country.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
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
    @EnvironmentObject var proManager: ProManager

    @State private var showPINSetup              = false
    @State private var showSignOutConfirm        = false
    @State private var showDeleteAccountConfirm  = false
    @State private var showRemovePINConfirm      = false
    @State private var showFeedbackSheet         = false
    @State private var showEditName              = false
    @State private var showEditLocation          = false
    @State private var showAdminSheet            = false
    @State private var showPaywall               = false
    @State private var isFoundingMember          = false

    @StateObject private var adminService = AdminService()
    private let profileService = ProfileService()
    @State private var isDeletingAccount         = false
    @State private var deleteAccountError: String?

    // Lys/mørk-modus — deles med app-roten via samme AppStorage-nøkkel
    @AppStorage("appearance") private var appearance = "system"

    // Samme utledning som app-roten, så arket selv oppdaterer modus live
    private var preferredScheme: ColorScheme? {
        switch appearance {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    // Ensartet innstillingsrad: grått ikon + primærtekst, eller helt rødt for destruktivt.
    @ViewBuilder
    private func settingsRow(_ title: String, icon: String, destructive: Bool = false,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(destructive ? .red : Color("TextSecondary"))
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(destructive ? .red : Color("TextPrimary"))
                Spacer()
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // Pro-status / oppgrader (skilt ut for å lette kompilatoren)
    private var proSection: some View {
                Section {
                    if proManager.isPro {
                        HStack(spacing: 12) {
                            Image(systemName: "seal.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color("Accent"))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("SEDER Pro")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Color("TextPrimary"))
                                Text(proManager.isFoundingMember ? "Tidlig tester · livstid" : "Pro · livstid")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color("TextSecondary"))
                            }
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "seal.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color("Accent"))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Oppgrader til Pro")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Color("TextPrimary"))
                                    Text("Ubegrenset humidor, eksport og innsikt")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color("TextSecondary"))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color("TextSecondary").opacity(0.4))
                            }
                            .padding(.vertical, 2)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listRowBackground(Color("Card"))
    }

    // Admin-kø (skilt ut for å lette kompilatoren)
    @ViewBuilder private var adminSection: some View {
                if adminService.isAdmin {
                    Section("Administrasjon") {
                        Button {
                            showAdminSheet = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "tray.full")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color("TextSecondary"))
                                    .frame(width: 24)
                                Text("Kø")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color("TextPrimary"))
                                Spacer()
                                if adminService.antallIKo > 0 {
                                    Text("\(adminService.antallIKo)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 2)
                                        .background(Color("Accent"))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.vertical, 2)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .listRowBackground(Color("Card"))
                }
    }

    // Konto-handlinger (skilt ut for å lette kompilatoren)
    private var accountActionsSection: some View {
                Section {
                    settingsRow("Logg ut", icon: "rectangle.portrait.and.arrow.right", destructive: true) { showSignOutConfirm = true }
                    if isDeletingAccount {
                        HStack(spacing: 12) {
                            ProgressView().tint(.red)
                            Text("Sletter konto…")
                                .font(.system(size: 16))
                                .foregroundColor(.red)
                        }
                        .padding(.vertical, 2)
                    } else {
                        settingsRow("Slett konto", icon: "trash", destructive: true) { showDeleteAccountConfirm = true }
                    }
                } footer: {
                    Text("«Slett konto» fjerner kontoen din og alle data permanent. Kan ikke angres.")
                        .font(.system(size: 12))
                        .foregroundColor(Color("TextSecondary"))
                }
                .listRowBackground(Color("Card"))
    }

    private var kontoSection: some View {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 34))
                            .foregroundColor(Color("TextSecondary"))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Innlogget som")
                                .font(.system(size: 12))
                                .foregroundColor(Color("TextSecondary"))
                            Text(authService.currentUser?.email ?? "—")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color("TextPrimary"))
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color("Card"))
    }

    private var profilSection: some View {
                Section("Profil") {
                    settingsRow("Endre navn", icon: "person.text.rectangle") { showEditName = true }
                    settingsRow("Endre by og land", icon: "mappin.and.ellipse") { showEditLocation = true }
                }
                .listRowBackground(Color("Card"))
    }

    private var utseendeSection: some View {
                Section("Utseende") {
                    Picker("Tema", selection: $appearance) {
                        Text("System").tag("system")
                        Text("Mørk").tag("dark")
                        Text("Lys").tag("light")
                    }
                    .pickerStyle(.segmented)
                }
                .listRowBackground(Color("Card"))
    }

    private var sikkerhetSection: some View {
                Section("Sikkerhet") {
                    if pinService.isPINSet {
                        settingsRow("Fjern PIN-kode", icon: "lock.open", destructive: true) { showRemovePINConfirm = true }
                    } else {
                        settingsRow("Sett opp 4-sifret kode", icon: "lock") { showPINSetup = true }
                    }
                }
                .listRowBackground(Color("Card"))
    }

    private var tilbakemeldingSection: some View {
                Section("Tilbakemelding") {
                    settingsRow("Gi tilbakemelding på appen", icon: "bubble.left.and.bubble.right") { showFeedbackSheet = true }
                }
                .listRowBackground(Color("Card"))
    }

    // Om SEDER — helse/formål + juridiske lenker (viktig for App Review)
    private var omSederSection: some View {
        Section("Om SEDER") {
            VStack(alignment: .leading, spacing: 6) {
                Text("Helse og formål")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color("TextPrimary"))
                Text("Tobakk innebærer helserisiko. SEDER selger ingen produkter, formidler ingen kjøp og oppfordrer ikke til bruk. Appen er et referanse- og registreringsverktøy for voksne over 18 år som ønsker å holde oversikt over en egen samling.")
                    .font(.system(size: 13))
                    .foregroundColor(Color("TextSecondary"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)
            Link("Vilkår for bruk", destination: URL(string: "https://sederappen.no/terms.html")!)
                .font(.system(size: 15))
                .foregroundColor(Color("Accent"))
            Link("Personvern", destination: URL(string: "https://sederappen.no/privacy.html")!)
                .font(.system(size: 15))
                .foregroundColor(Color("Accent"))
        }
        .listRowBackground(Color("Card"))
    }

    var body: some View {
        NavigationStack {
            List {
                kontoSection

                proSection

                profilSection

                utseendeSection

                sikkerhetSection

                tilbakemeldingSection

                omSederSection

                adminSection


                accountActionsSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color("Background"))
            .navigationTitle("Innstillinger")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(preferredScheme)
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
            .sheet(isPresented: $showAdminSheet) {
                AdminView()
            }
            .sheet(isPresented: $showPaywall) {
                SupportView(mode: .unlock,
                            unlockTitle: "SEDER Pro",
                            unlockSubtitle: "Ubegrenset humidor, statistikk og eksport – én betaling, for alltid.",
                            showQuota: false)
            }
            .task {
                await adminService.refreshAdminStatus()
                await adminService.loadQueue()
                if let uid = authService.userId,
                   let p = try? await profileService.fetchOwnProfile(userId: uid) {
                    isFoundingMember = p.isFoundingMember ?? false
                    proManager.isFoundingMember = isFoundingMember
                }
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
