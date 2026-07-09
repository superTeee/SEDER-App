import SwiftUI

// MARK: - Legg til sigar
//
// Finner du ikke sigaren, skal du ikke bli stående fast. Du legger den inn selv,
// og den virker umiddelbart i din humidor og journal.
//
// Men den skrives IKKE rett inn i det delte oppslagsverket. Raden opprettes
// privat (`is_public = false`, `created_by = deg`), og samtidig sendes et
// forslag til review-køen. Godkjennes det, blir den en del av basen for alle.
//
// Uten det skillet ville databasen blitt full av dubletter og gjetninger —
// nøyaktig den feilen vi bruker uker på å rydde opp i.

struct AddCigarSheet: View {

    /// Forhåndsutfylt merke eller søketekst, hvis brukeren kom fra et tomt søk.
    var prefillBrand: String = ""

    /// Kalles med den nye sigaren når den er opprettet.
    var onCreated: (Cigar) -> Void = { _ in }

    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var brand = ""
    @State private var series = ""
    @State private var vitola = ""
    @State private var country = ""
    @State private var wrapper = ""
    @State private var ringGauge = ""
    @State private var lengthInches = ""
    @State private var note = ""
    @State private var suggestToDatabase = true

    @State private var isSaving = false
    @State private var errorMessage: String?

    private let cigarService = CigarService()

    private var canSave: Bool {
        !brand.trimmingCharacters(in: .whitespaces).isEmpty && !isSaving
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Merke", text: $brand)
                        .textInputAutocapitalization(.words)
                    TextField("Serie (valgfritt)", text: $series)
                        .textInputAutocapitalization(.words)
                    TextField("Format eller vitola (valgfritt)", text: $vitola)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Sigaren")
                } footer: {
                    Text("Bare merket er påkrevd. Resten kan du fylle ut senere.")
                }

                Section("Detaljer") {
                    TextField("Opprinnelsesland", text: $country)
                        .textInputAutocapitalization(.words)
                    TextField("Dekkblad", text: $wrapper)
                        .textInputAutocapitalization(.words)
                    HStack {
                        TextField("Ringmål", text: $ringGauge)
                            .keyboardType(.numberPad)
                        Divider()
                        TextField("Lengde i tommer", text: $lengthInches)
                            .keyboardType(.decimalPad)
                    }
                }

                Section {
                    Toggle("Foreslå for sigardatabasen", isOn: $suggestToDatabase)
                    if suggestToDatabase {
                        TextField("Kilde eller kommentar (valgfritt)", text: $note, axis: .vertical)
                            .lineLimit(2...5)
                    }
                } footer: {
                    Text(suggestToDatabase
                         ? "Sigaren blir din med én gang. Vi sjekker den mot kilden, og godkjennes den blir den synlig for alle."
                         : "Sigaren blir kun liggende i din egen samling.")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                }
            }
            .background(Color("Background"))
            .navigationTitle("Legg til sigar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Avbryt") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving { ProgressView() } else { Text("Lagre").fontWeight(.semibold) }
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                if brand.isEmpty { brand = prefillBrand }
            }
        }
    }

    private func save() async {
        guard authService.userId != nil else {
            errorMessage = "Du må være innlogget for å legge til en sigar."
            return
        }
        isSaving = true
        defer { isSaving = false }
        do {
            let cigar = try await cigarService.createOwnCigar(
                brand:        brand,
                series:       series,
                vitola:       vitola,
                country:      country,
                wrapper:      wrapper,
                ringGauge:    Int(ringGauge),
                lengthInches: Double(lengthInches.replacingOccurrences(of: ",", with: ".")),
                note:         note,
                suggest:      suggestToDatabase
            )
            onCreated(cigar)
            dismiss()
        } catch {
            errorMessage = "Kunne ikke lagre sigaren — prøv igjen."
            print("createOwnCigar feilet: \(error)")
        }
    }
}

// MARK: - PrivateCigarBadge
// Vises på detaljsiden for en sigar bare du kan se.

struct PrivateCigarBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.system(size: 11))
            Text("Din egen sigar — kun synlig for deg")
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(Color(.secondaryLabel))
    }
}
