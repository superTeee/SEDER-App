import SwiftUI

// MARK: - Fyll datahull
//
// Arket viser BARE feltene sigaren mangler — ikke hele raden. Én ting av
// gangen, ingen skjema-vegg. Admin fyller det hun har kilde på, limer inn
// kilden, og lagrer. Basen fyller kun tomme felt (admin_fill_cigar), så det
// admin skriver her kan aldri overskrive noe som allerede står der.

struct CigarFillSheet: View {

    let hull: CigarGap
    @ObservedObject var admin: AdminService
    @Environment(\.dismiss) private var dismiss

    // Ett input per mulig hull. Bare de som ligger i hull.manglendeFelt vises.
    @State private var ringGaugeTxt = ""
    @State private var lengthTxt    = ""
    @State private var origin       = ""
    @State private var wrapper      = ""
    @State private var angiStyrke   = false
    @State private var strength     = 2.5
    @State private var flavorTxt    = ""
    @State private var descTxt      = ""
    @State private var sourceUrl    = ""

    @State private var lagrer = false
    @State private var feil: String?

    private var mangler: Set<GapField> { Set(hull.manglendeFelt) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(hull.visningsnavn)
                        .font(.headline)
                        .foregroundColor(Color("TextPrimary"))
                }

                if mangler.contains(.dimensions) { dimensjonSeksjon }
                if mangler.contains(.origin)     { tekstSeksjon(.origin, tekst: $origin, plassholder: "F.eks. Nicaragua") }
                if mangler.contains(.wrapper)    { tekstSeksjon(.wrapper, tekst: $wrapper, plassholder: "F.eks. Ecuador Habano") }
                if mangler.contains(.strength)   { styrkeSeksjon }
                if mangler.contains(.flavor)     { smakSeksjon }
                if mangler.contains(.description){ beskrivelseSeksjon }

                kildeSeksjon

                if let feil {
                    Section { Text(feil).font(.footnote).foregroundColor(.red) }
                }

                Section {
                    Button {
                        Task { await lagre() }
                    } label: {
                        HStack {
                            Spacer()
                            if lagrer { ProgressView().tint(.white) }
                            else { Text("Lagre").fontWeight(.semibold) }
                            Spacer()
                        }
                    }
                    .disabled(lagrer || !kanLagre)
                    .listRowBackground(kanLagre ? Color("Accent") : Color(.systemGray4))
                    .foregroundColor(.white)
                }
            }
            .background(Color("Background"))
            .navigationTitle("Tett hull")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Avbryt") { dismiss() }
                }
            }
        }
    }

    // MARK: - Seksjoner

    private var dimensjonSeksjon: some View {
        Section("Mål") {
            HStack {
                Text("Ringmål")
                Spacer()
                TextField("50", text: $ringGaugeTxt)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 90)
            }
            HStack {
                Text("Lengde (tommer)")
                Spacer()
                TextField("5.0", text: $lengthTxt)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 90)
            }
        }
    }

    private func tekstSeksjon(_ felt: GapField, tekst: Binding<String>, plassholder: String) -> some View {
        Section(felt.label) {
            TextField(plassholder, text: tekst)
                .autocorrectionDisabled()
        }
    }

    private var styrkeSeksjon: some View {
        Section("Styrke") {
            Toggle("Angi styrke", isOn: $angiStyrke)
            if angiStyrke {
                VStack(alignment: .leading, spacing: 6) {
                    Text(styrkeLabel(strength))
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(Color("Accent"))
                    Slider(value: $strength, in: 1...5, step: 0.5)
                }
            }
        }
    }

    private var smakSeksjon: some View {
        Section {
            TextField("kaffe, sedertre, pepper", text: $flavorTxt, axis: .vertical)
                .lineLimit(2...4)
                .autocorrectionDisabled()
        } header: {
            Text("Smaksnoter")
        } footer: {
            Text("Skill notene med komma.")
        }
    }

    private var beskrivelseSeksjon: some View {
        Section("Beskrivelse") {
            TextField("Kort beskrivelse", text: $descTxt, axis: .vertical)
                .lineLimit(3...8)
        }
    }

    private var kildeSeksjon: some View {
        Section {
            TextField("https://…", text: $sourceUrl)
                .keyboardType(.URL)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        } header: {
            Text("Kilde")
        } footer: {
            Text("Lenke til der tallene står. Kreves. Fylling verifiserer ikke raden — den lagrer bare kilden som spor.")
        }
    }

    // MARK: - Validering + lagring

    /// Kan lagre når kilden er satt og minst ett felt faktisk er fylt ut.
    private var kanLagre: Bool {
        !sourceUrl.trimmingCharacters(in: .whitespaces).isEmpty && !byggPatch().erTom
    }

    private func byggPatch() -> CigarFillPatch {
        func rens(_ s: String) -> String? {
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? nil : t
        }
        let noter = flavorTxt
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return CigarFillPatch(
            sourceUrl:     sourceUrl.trimmingCharacters(in: .whitespaces),
            ringGauge:     Int(ringGaugeTxt.trimmingCharacters(in: .whitespaces)),
            lengthInches:  Double(lengthTxt.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)),
            countryOrigin: rens(origin),
            wrapperLeaf:   rens(wrapper),
            strength:      angiStyrke ? strength : nil,
            flavorNotes:   noter.isEmpty ? nil : noter,
            description:   rens(descTxt)
        )
    }

    private func lagre() async {
        feil = nil
        lagrer = true
        defer { lagrer = false }

        let ok = await admin.fillCigar(hull.id, patch: byggPatch())
        if ok { dismiss() }
        else  { feil = "Kunne ikke lagre — prøv igjen." }
    }

    private func styrkeLabel(_ s: Double) -> String {
        switch s {
        case ..<1.5:    return "Mild"
        case 1.5..<2.5: return "Mild–Medium"
        case 2.5..<3.5: return "Medium"
        case 3.5..<4.5: return "Medium–Full"
        default:        return "Full"
        }
    }
}

private extension CigarFillPatch {
    /// Ingen felt fylt ut (kilde teller ikke som innhold).
    var erTom: Bool {
        ringGauge == nil && lengthInches == nil && countryOrigin == nil &&
        wrapperLeaf == nil && strength == nil && flavorNotes == nil && description == nil
    }
}
