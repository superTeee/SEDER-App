import SwiftUI

/// Neutral settings destination replacing the former profile tab.
struct SettingsRootView: View {
    @EnvironmentObject var authService: AuthService
    @AppStorage("appearance") private var appearance = "system"
    @State private var showSignOutConfirm = false

    var body: some View {
        NavigationStack {
            List {
                if let email = authService.currentUser?.email {
                    Section("Konto") {
                        LabeledContent("Innlogget som", value: email)
                    }
                }

                Section("Utseende") {
                    Picker("Tema", selection: $appearance) {
                        Text("System").tag("system")
                        Text("Mørk").tag("dark")
                        Text("Lys").tag("light")
                    }
                    .pickerStyle(.segmented)
                }

                Section("Om SEDER") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Helse og formål")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Tobakk innebærer helserisiko. SEDER selger ingen produkter, formidler ingen kjøp og oppfordrer ikke til bruk. Appen er et referanse-, lagrings- og registreringsverktøy for voksne som ønsker å holde oversikt over en egen samling.")
                            .font(.system(size: 13))
                            .foregroundColor(Color("TextSecondary"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)

                    Link("Vilkår for bruk", destination: URL(string: "https://sederappen.no/terms.html")!)
                    Link("Personvern", destination: URL(string: "https://sederappen.no/privacy.html")!)
                }

                if authService.userId != nil {
                    Section {
                        Button("Logg ut", role: .destructive) {
                            showSignOutConfirm = true
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color("Background"))
            .navigationTitle("Innstillinger")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Logg ut?", isPresented: $showSignOutConfirm) {
                Button("Avbryt", role: .cancel) {}
                Button("Logg ut", role: .destructive) {
                    Task { try? await authService.signOut() }
                }
            }
        }
    }
}
