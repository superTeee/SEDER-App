import SwiftUI

// MARK: - Meld feil på sigardata
//
// Databasen er bygget av mennesker og maskiner som noen ganger tar feil.
// I stedet for å late som noe annet, lar vi entusiastene rette oss.
// Rapporten går til `cigar_reports` via report_cigar()-RPC-en, som leser
// bruker-ID fra auth.uid() — aldri fra klienten.

enum CigarReportField: String, CaseIterable, Identifiable {
    case origin      = "origin"
    case dimensions  = "dimensions"
    case tobacco     = "tobacco"
    case description = "description"
    case flavor      = "flavor"
    case other       = "other"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .origin:      return "Feil opprinnelsesland"
        case .dimensions:  return "Feil mål eller format"
        case .tobacco:     return "Feil dekkblad, omblad eller innmat"
        case .description: return "Feil i beskrivelsen"
        case .flavor:      return "Feil smaksnoter"
        case .other:       return "Noe annet"
        }
    }

    var systemImage: String {
        switch self {
        case .origin:      return "mappin.and.ellipse"
        case .dimensions:  return "ruler"
        case .tobacco:     return "leaf"
        case .description: return "text.alignleft"
        case .flavor:      return "nose"
        case .other:       return "questionmark.circle"
        }
    }
}

struct CigarReportSheet: View {

    let cigar: Cigar

    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var field: CigarReportField = .origin
    @State private var comment = ""
    @State private var isSending = false
    @State private var didSend = false
    @State private var errorMessage: String?

    private let cigarService = CigarService()

    var body: some View {
        NavigationStack {
            Group {
                if didSend { receipt } else { form }
            }
            .background(Color("Background"))
            .navigationTitle("Meld feil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Avbryt") { dismiss() }
                }
            }
        }
    }

    // MARK: - Skjema

    private var form: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(cigar.brand)
                        .font(.headline)
                    if let series = cigar.series {
                        Text(series)
                            .font(.subheadline)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                }
                .padding(.vertical, 2)
            }

            Section("Hva stemmer ikke?") {
                ForEach(CigarReportField.allCases) { option in
                    Button {
                        field = option
                    } label: {
                        HStack {
                            Label(option.label, systemImage: option.systemImage)
                                .foregroundColor(Color("TextPrimary"))
                            Spacer()
                            if field == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color("Accent"))
                            }
                        }
                    }
                }
            }

            Section {
                TextField("Skriv hva som er riktig, og gjerne hvor du vet det fra", text: $comment, axis: .vertical)
                    .lineLimit(3...8)
            } header: {
                Text("Utdyp")
            } footer: {
                Text("En kildelenke gjør at rettelsen går raskere gjennom.")
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                }
            }

            Section {
                Button {
                    Task { await send() }
                } label: {
                    HStack {
                        Spacer()
                        if isSending {
                            ProgressView().tint(.white)
                        } else {
                            Text("Send inn").fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(isSending)
                .listRowBackground(Color("Accent"))
                .foregroundColor(.white)
            }
        }
    }

    // MARK: - Kvittering

    private var receipt: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle")
                .font(.system(size: 52))
                .foregroundColor(Color("Accent"))
            Text("Takk")
                .font(.title2.bold())
                .foregroundColor(Color("TextPrimary"))
            Text("Rettelsen er sendt inn. Vi sjekker den mot kilden og oppdaterer sigaren.")
                .font(.subheadline)
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
            Button("Lukk") { dismiss() }
                .fontWeight(.semibold)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Innsending

    private func send() async {
        guard authService.userId != nil else {
            errorMessage = "Du må være innlogget for å melde feil."
            return
        }
        isSending = true
        defer { isSending = false }
        do {
            try await cigarService.reportCigar(cigarId: cigar.id, field: field.rawValue, comment: comment)
            didSend = true
        } catch {
            errorMessage = "Kunne ikke sende inn — prøv igjen."
            print("reportCigar feilet for \(cigar.id): \(error)")
        }
    }
}

// MARK: - VerificationBadge
//
// Vises under sigar-tittelen. En rad uten `verified_at` er ikke sjekket mot en
// kilde, og da sier vi det heller enn å presentere gjetning som fakta.

// MARK: - VerificationBadge
//
// Tre tilstander, ikke to. «Verifisert» betydde én ting: kontrollert mot
// produsentens egen katalog. Da vi begynte å hente mål fra butikker, kunne vi
// enten utvide løftet — og gjøre det usant for de 419 radene som allerede bar
// det — eller si tydelig hvem som står bak tallene. Vi valgte det siste.
//
// Butikker tar feil. Sol Cigar og Augusto er uenige om hvor lang en
// Arturo Fuente 8-5-8 er, med sju millimeter. Brukeren fortjener å vite
// hvem vi har spurt, ikke bare at vi har spurt noen.

struct VerificationBadge: View {
    let cigar: Cigar
    var onReport: () -> Void

    private var ikon: String {
        switch cigar.verification {
        case .manufacturer: return "checkmark.seal.fill"
        case .community:    return "person.2.fill"
        case .retailer:     return "checkmark.seal.fill"
        case .unverified:   return "info.circle"
        }
    }

    private var tekst: String {
        switch cigar.verification {
        case .manufacturer:      return "Verifisert mot produsent"
        case .community:         return "Bekreftet av brukere"
        case .retailer:          return "Verifisert"
        case .unverified:        return "Ikke bekreftet ennå"
        }
    }

    private var farge: Color {
        switch cigar.verification {
        case .manufacturer: return Color("Accent")
        case .community:    return Color("Accent")
        case .retailer:     return Color("Accent")
        case .unverified:   return Color(.label)   // ikon = tekstfarge når ubekreftet
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            // Kun ikonet bærer tilstandsfargen — accent når verifisert, tekstfarge
            // når ubekreftet. Teksten holdes alltid lesbar.
            Image(systemName: ikon)
                .font(.system(size: 13))
                .foregroundColor(farge)
            Text(tekst)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color(.label))
                .lineLimit(1)

            Text("·")
                .font(.system(size: 13))
                .foregroundColor(Color(.tertiaryLabel))

            Button("Meld feil", action: onReport)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color(.secondaryLabel))   // alltid lesbar, uansett badge-tilstand
        }
    }
}
