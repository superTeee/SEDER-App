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

struct VerificationBadge: View {
    let cigar: Cigar
    var onReport: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: cigar.isVerified ? "checkmark.seal.fill" : "questionmark.circle")
                .font(.system(size: 12))
            Text(cigar.isVerified ? "Verifisert mot kilde" : "Ikke verifisert")
                .font(.system(size: 12, weight: .medium))

            Text("·")
                .font(.system(size: 12))
                .foregroundColor(Color(.tertiaryLabel))

            Button("Meld feil", action: onReport)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(cigar.isVerified ? Color("Accent") : Color(.secondaryLabel))
    }
}
