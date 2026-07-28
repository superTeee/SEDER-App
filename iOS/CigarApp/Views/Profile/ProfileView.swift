import SwiftUI
import RevenueCat

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

                Section {
                    if proManager.isPro {
                        HStack(spacing: 12) {
                            Image(systemName: "seal.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color("Accent"))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("SEDER Pro")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(Color("TextPrimary"))
                                Text(proManager.isFoundingMember ? "Tidlig tester · livstid" : "Abonnement aktivt")
                                    .font(.caption)
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
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(Color("TextPrimary"))
                                    Text("Ubegrenset humidor, eksport og innsikt")
                                        .font(.caption)
                                        .foregroundColor(Color("TextSecondary"))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color("TextSecondary").opacity(0.5))
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                #if DEBUG
                Section {
                    Toggle(isOn: $proManager.debugForceFree) {
                        Label("Test: simuler gratisbruker", systemImage: "ladybug")
                    }
                } footer: {
                    Text("Kun i testbuilds. Skjuler tidlig tester-Pro så du kan se paywallen og teste kjøp. Et (test-)kjøp slår Pro på igjen.")
                }
                #endif

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

                // Vises kun for admin. `is_admin()` spørres i basen — vi stoler
                // ikke på en lokal flagg-verdi for å skjule noe som betyr noe.
                if adminService.isAdmin {
                    Section("Administrasjon") {
                        Button {
                            showAdminSheet = true
                        } label: {
                            HStack {
                                Label("Kø", systemImage: "tray.full")
                                Spacer()
                                if adminService.antallIKo > 0 {
                                    Text("\(adminService.antallIKo)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 2)
                                        .background(Color("Accent"))
                                        .clipShape(Capsule())
                                }
                            }
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
                PaywallView().environmentObject(proManager)
            }
            .task {
                await adminService.refreshAdminStatus()
                await adminService.loadQueue()
                if let uid = authService.userId,
                   let p = try? await profileService.fetchOwnProfile(userId: uid) {
                    isFoundingMember = p.isFoundingMember ?? false
                    proManager.isFoundingMember = isFoundingMember
                }
                await proManager.refresh()
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

// MARK: - PaywallView
// SEDER Pro: ubegrenset humidor + journal-eksport + avansert statistikk + Pro-merke.
// Ingen skann-grense (skanning er alltid gratis). Kjøps-knapp stubbes til RevenueCat
// er koblet på — da bytter «Start Pro» ut placeholder-varselet med ekte kjøp.
struct PaywallView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var proManager: ProManager
    @State private var yearly = true
    @State private var showComingSoon = false
    @State private var purchasing = false
    @State private var showError = false

    // Ekte App Store-pakker (nil til produktene er lastet fra RevenueCat).
    private var annualPackage: Package? {
        proManager.offerings?.current?.availablePackages.first { $0.packageType == .annual }
    }
    private var monthlyPackage: Package? {
        proManager.offerings?.current?.availablePackages.first { $0.packageType == .monthly }
    }
    private var selectedPackage: Package? { yearly ? annualPackage : monthlyPackage }

    private var yearlyPrice: String { annualPackage?.storeProduct.localizedPriceString ?? "449 kr" }
    private var monthlyPrice: String { monthlyPackage?.storeProduct.localizedPriceString ?? "59 kr" }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                header
                comparisonCard
                Text("Skanning, journal og vurderinger er alltid gratis.")
                    .font(.footnote)
                    .foregroundColor(Color("TextSecondary"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                planSelector
            }
            .padding(.horizontal, 20)
            .padding(.top, 40)
            .padding(.bottom, 20)
        }
        .background(Color("Background").ignoresSafeArea())
        .safeAreaInset(edge: .bottom) { bottomBar }
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color("TextSecondary"))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color("TextSecondary").opacity(0.12)))
            }
            .padding(.trailing, 16)
            .padding(.top, 12)
        }
        .alert("Kommer snart", isPresented: $showComingSoon) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Betaling kobles på i neste oppdatering. Da kan du bli Pro herfra.")
        }
        .alert("Kjøpet ble ikke fullført", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Prøv igjen, eller sjekk App Store-kontoen din.")
        }
        .task { await proManager.loadOfferings() }
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "seal.fill")
                Text("SEDER Pro").fontWeight(.semibold)
            }
            .font(.system(size: 12))
            .foregroundColor(Color("Accent"))
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(Capsule().fill(Color("Accent").opacity(0.12)))

            Text("Få mest ut av samlingen din")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Color("TextPrimary"))
                .multilineTextAlignment(.center)
            Text("Ubegrenset humidor, eksport og innsikt.")
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)
        }
    }

    private var comparisonCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("").frame(maxWidth: .infinity, alignment: .leading)
                Text("Gratis").frame(width: 60)
                Text("Pro").fontWeight(.semibold).foregroundColor(Color("Accent")).frame(width: 60)
            }
            .font(.system(size: 13))
            .foregroundColor(Color("TextSecondary"))
            .padding(.horizontal, 16).padding(.vertical, 11)
            Divider()
            compareRow(label: "Humidor-størrelse", free: .text("25"), pro: .text("∞"))
            Divider().padding(.leading, 16)
            compareRow(label: "Journal-eksport (PDF/CSV)", free: .no, pro: .yes)
            Divider().padding(.leading, 16)
            compareRow(label: "Avansert statistikk", free: .no, pro: .yes)
            Divider().padding(.leading, 16)
            compareRow(label: "Pro-merke på profil", free: .no, pro: .yes)
        }
        .background(Color("Card"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private enum CellValue { case text(String), yes, no }

    @ViewBuilder
    private func compareRow(label: String, free: CellValue, pro: CellValue) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(Color("TextPrimary"))
                .frame(maxWidth: .infinity, alignment: .leading)
            cell(free, accent: false).frame(width: 60)
            cell(pro, accent: true).frame(width: 60)
        }
        .padding(.horizontal, 16).padding(.vertical, 13)
    }

    @ViewBuilder
    private func cell(_ value: CellValue, accent: Bool) -> some View {
        switch value {
        case .text(let t):
            Text(t)
                .font(.system(size: 16, weight: accent ? .semibold : .regular))
                .foregroundColor(accent ? Color("TextPrimary") : Color("TextSecondary"))
        case .yes:
            Image(systemName: "checkmark").font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color("Accent"))
        case .no:
            Image(systemName: "minus").font(.system(size: 15))
                .foregroundColor(Color("TextSecondary").opacity(0.4))
        }
    }

    private var planSelector: some View {
        HStack(spacing: 10) {
            planCard(title: "Årlig", price: yearlyPrice, note: "≈ 37 kr/mnd", badge: "Spar 37%", selected: yearly) { yearly = true }
            planCard(title: "Månedlig", price: monthlyPrice, note: "per måned", badge: nil, selected: !yearly) { yearly = false }
        }
    }

    @ViewBuilder
    private func planCard(title: String, price: String, note: String, badge: String?, selected: Bool, tap: @escaping () -> Void) -> some View {
        Button(action: tap) {
            VStack(spacing: 2) {
                Text(title).font(.system(size: 13, weight: .semibold)).foregroundColor(Color("TextPrimary"))
                Text(price).font(.system(size: 18, weight: .semibold)).foregroundColor(Color("TextPrimary"))
                Text(note).font(.system(size: 11)).foregroundColor(Color("TextSecondary"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color("Card"))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? Color("Accent") : Color("TextSecondary").opacity(0.15),
                            lineWidth: selected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(alignment: .top) {
                if let badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Capsule().fill(Color("Accent")))
                        .offset(y: -9)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            Button {
                if let pkg = selectedPackage {
                    Task {
                        purchasing = true
                        let ok = await proManager.purchase(pkg)
                        purchasing = false
                        if ok { dismiss() } else { showError = true }
                    }
                } else {
                    // RevenueCat ikke koblet på ennå (mangler API-nøkkel/produkter).
                    showComingSoon = true
                }
            } label: {
                Group {
                    if purchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text("Start Pro").font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color("Accent"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(purchasing)

            Text("Gratis fortsetter alltid · avslutt når som helst")
                .font(.system(size: 11))
                .foregroundColor(Color("TextSecondary"))
            HStack(spacing: 14) {
                Button("Gjenopprett kjøp") {
                    Task {
                        let ok = await proManager.restore()
                        if ok { dismiss() } else { showError = true }
                    }
                }
                Text("·").foregroundColor(Color("TextSecondary").opacity(0.5))
                Link("Vilkår", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                Text("·").foregroundColor(Color("TextSecondary").opacity(0.5))
                Link("Personvern", destination: URL(string: "https://vitola.app/personvern")!)
            }
            .font(.system(size: 11))
            .foregroundColor(Color("TextSecondary"))
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Color("Background"))
    }
}
