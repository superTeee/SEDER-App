import SwiftUI

// MARK: - AdminView
//
// Køen. To ting kan ligge her: feilmeldinger på eksisterende sigarer, og
// forslag til nye. Begge kommer fra brukere, og begge krever en avgjørelse.
//
// Visningen er bevisst tørr. Den skal ikke overtale deg til noe — den skal vise
// hva brukeren sa, hva basen sier, og hvor tallene i basen kommer fra. Så
// bestemmer du.

struct AdminView: View {

    @StateObject private var admin = AdminService()
    @Environment(\.dismiss) private var dismiss

    /// To visninger deler samme skjerm: køen (det brukerne melder) og datahull
    /// (det katalogen selv mangler). En segmentert veksler skiller dem.
    enum Fane: String, CaseIterable, Identifiable {
        case ko      = "Kø"
        case datahull = "Datahull"
        case dekning  = "Dekning"
        var id: String { rawValue }
    }
    @State private var fane: Fane = .ko

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Visning", selection: $fane) {
                    ForEach(Fane.allCases) { f in Text(f.rawValue).tag(f) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                Group {
                    switch fane {
                    case .ko:       koView
                    case .datahull: DatahullView(admin: admin)
                    case .dekning:  SkannDekningView(admin: admin)
                    }
                }
            }
            .background(Color("Background"))
            .navigationTitle(fane.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Lukk") { dismiss() }
                }
            }
        }
        .task {
            await admin.refreshAdminStatus()
            await admin.loadQueue()
        }
    }

    // MARK: - Kø

    @ViewBuilder
    private var koView: some View {
        if admin.isLoading && admin.antallIKo == 0 {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if admin.antallIKo == 0 {
            tomKo
        } else {
            List {
                if !admin.reports.isEmpty {
                    Section("Feilmeldinger") {
                        ForEach(admin.reports) { rapport in
                            ReportRow(rapport: rapport) { status in
                                Task { await admin.resolveReport(rapport.id, status: status) }
                            }
                        }
                    }
                }
                if !admin.submissions.isEmpty {
                    Section("Foreslåtte sigarer") {
                        ForEach(admin.submissions) { forslag in
                            SubmissionRow(forslag: forslag) { godkjent in
                                Task {
                                    if godkjent { await admin.approveSubmission(forslag.id) }
                                    else        { await admin.rejectSubmission(forslag.id) }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .refreshable { await admin.loadQueue() }
        }
    }

    private var tomKo: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 34))
                .foregroundColor(Color(.tertiaryLabel))
            Text("Ingenting venter")
                .font(.headline)
                .foregroundColor(Color(.secondaryLabel))
            Text("Feilmeldinger og forslag fra brukerne dukker opp her.")
                .font(.subheadline)
                .foregroundColor(Color(.tertiaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Feilmelding

private struct ReportRow: View {
    let rapport: AdminReport
    let onSvar: (ReportStatus) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(rapport.cigarNavn)
                .font(.subheadline.bold())

            HStack(spacing: 6) {
                Text(rapport.feltNavn)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color("Accent").opacity(0.15))
                    .clipShape(Capsule())

                // Er raden allerede kontrollert mot en kilde? Da veier
                // innmeldingen mindre — og du bør sjekke kilden før du retter.
                Label(rapport.verified ? "Verifisert" : "Ikke verifisert",
                      systemImage: rapport.verified ? "checkmark.seal.fill" : "questionmark.circle")
                    .font(.caption)
                    .foregroundColor(rapport.verified ? .green : Color(.secondaryLabel))
            }

            if let comment = rapport.comment, !comment.isEmpty {
                Text(comment)
                    .font(.subheadline)
                    .foregroundColor(Color(.label))
            }

            Text("Basen sier: \(rapport.maalTekst)")
                .font(.caption)
                .foregroundColor(Color(.secondaryLabel))

            if let kilde = rapport.sourceUrl {
                Text(kilde)
                    .font(.caption2)
                    .foregroundColor(Color(.tertiaryLabel))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Text("\(rapport.melder) · \(rapport.createdAt.formatted(.relative(presentation: .named)))")
                .font(.caption2)
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) {
            Button {
                onSvar(.rejected)
            } label: {
                Label("Avvis", systemImage: "xmark")
            }
            .tint(.gray)

            Button {
                onSvar(.resolved)
            } label: {
                Label("Løst", systemImage: "checkmark")
            }
            .tint(.green)
        }
    }
}

// MARK: - Foreslått sigar

private struct SubmissionRow: View {
    let forslag: AdminSubmission
    let onSvar: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(forslag.cigarNavn)
                .font(.subheadline.bold())

            Text([forslag.maalTekst, forslag.countryOrigin]
                    .compactMap { $0 }
                    .joined(separator: " · "))
                .font(.caption)
                .foregroundColor(Color(.secondaryLabel))

            if let note = forslag.note, !note.isEmpty {
                Text(note)
                    .font(.subheadline)
            }

            Text("\(forslag.foreslattAv) · \(forslag.createdAt.formatted(.relative(presentation: .named)))")
                .font(.caption2)
                .foregroundColor(Color(.tertiaryLabel))

            // Godkjenning gjør sigaren synlig for alle. Den blir IKKE verifisert.
            Text("Godkjenning gjør sigaren synlig, ikke verifisert.")
                .font(.caption2)
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) {
            Button { onSvar(false) } label: { Label("Avvis", systemImage: "xmark") }
                .tint(.gray)
            Button { onSvar(true) } label: { Label("Godkjenn", systemImage: "checkmark") }
                .tint(.green)
        }
    }
}

// MARK: - Datahull
//
// Motsatt av køen: her leter vi ikke etter feil brukerne har meldt, men etter
// tomme felt katalogen selv har. Verst først (basen sorterer). Trykk på en rad
// åpner et ark som bare viser hullene — én ting av gangen, ikke hele sigaren.

// MARK: - Skann-dekning
//
// Steg 1 i dekning-datahjulet: treffrate + sigarer folk skanner uten å få treff,
// sortert etter hvor ofte. Dette forteller nøyaktig hvilke sigarer katalogen bør
// fylles med først.
private struct SkannDekningView: View {
    @ObservedObject var admin: AdminService

    var body: some View {
        Group {
            if admin.isLoading && admin.scanGaps.isEmpty && admin.scanHitrate == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section {
                        HStack(spacing: 10) {
                            statBox(title: "Treffrate", value: admin.scanHitrate?.rateText ?? "–")
                            statBox(title: "Skann", value: "\(admin.scanHitrate?.total ?? 0)")
                            statBox(title: "Bom", value: "\(admin.scanHitrate?.misses ?? 0)")
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                        .listRowBackground(Color.clear)
                    } footer: {
                        Text("Siste 30 dager. Treffrate = andel skann som fant en sigar.")
                    }

                    if admin.scanGaps.isEmpty {
                        Section {
                            Text("Ingen bom registrert ennå.")
                                .foregroundColor(Color("TextSecondary"))
                        }
                    } else {
                        Section {
                            ForEach(admin.scanGaps) { gap in
                                HStack(spacing: 10) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(gap.visningsnavn)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundColor(Color("TextPrimary"))
                                            .lineLimit(2)
                                        if gap.sampleOcr != gap.normText {
                                            Text(gap.normText)
                                                .font(.caption)
                                                .foregroundColor(Color("TextSecondary"))
                                                .lineLimit(1)
                                        }
                                    }
                                    Spacer()
                                    Text("\(gap.misses)×")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Color("Accent"))
                                }
                                .padding(.vertical, 2)
                            }
                        } header: {
                            Text("Mest skannet som mangler")
                        } footer: {
                            Text("Sigarer folk prøvde å skanne uten treff. Legg inn de øverste først — verifisert mot produsent.")
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable { await admin.loadScanCoverage() }
            }
        }
        .task { await admin.loadScanCoverage() }
    }

    private func statBox(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Color("TextPrimary"))
            Text(title)
                .font(.caption)
                .foregroundColor(Color("TextSecondary"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color("Card"))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct DatahullView: View {
    @ObservedObject var admin: AdminService
    @State private var valgt: CigarGap?

    var body: some View {
        Group {
            if admin.isLoading && admin.gaps.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if admin.gaps.isEmpty {
                tomt
            } else {
                List {
                    Section {
                        ForEach(admin.gaps) { hull in
                            Button { valgt = hull } label: { GapRow(hull: hull) }
                                .buttonStyle(.plain)
                        }
                    } header: {
                        Text("\(admin.gaps.count) sigarer mangler noe")
                    } footer: {
                        Text("Verst først. Trykk for å tette hullene. Fylling retter ikke eksisterende verdier — den fyller bare tomme felt.")
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable { await admin.loadGaps() }
            }
        }
        .task { if admin.gaps.isEmpty { await admin.loadGaps() } }
        .sheet(item: $valgt) { hull in
            CigarFillSheet(hull: hull, admin: admin)
        }
    }

    private var tomt: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 34))
                .foregroundColor(Color(.tertiaryLabel))
            Text("Ingen hull")
                .font(.headline)
                .foregroundColor(Color(.secondaryLabel))
            Text("Alle offentlige sigarer har de feltene appen viser.")
                .font(.subheadline)
                .foregroundColor(Color(.tertiaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct GapRow: View {
    let hull: CigarGap

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(hull.visningsnavn)
                    .font(.subheadline.bold())
                    .foregroundColor(Color(.label))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(Color(.tertiaryLabel))
            }

            // Hvilke felt mangler — som chips, samme visuelle språk som køen.
            FlowChips(felt: hull.manglendeFelt)

            Text("\(hull.gapCount) \(hull.gapCount == 1 ? "hull" : "hull")")
                .font(.caption2)
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

/// Chips som brytes til ny linje. Enkel HStack-basert flyt for et fåtall felt.
private struct FlowChips: View {
    let felt: [GapField]

    var body: some View {
        // Maks seks felt, så to rader à tre holder alltid.
        let rader = stride(from: 0, to: felt.count, by: 3).map {
            Array(felt[$0 ..< min($0 + 3, felt.count)])
        }
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(rader.enumerated()), id: \.offset) { _, rad in
                HStack(spacing: 6) {
                    ForEach(rad) { f in chip(f) }
                }
            }
        }
    }

    private func chip(_ f: GapField) -> some View {
        Label(f.label, systemImage: f.systemImage)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color("Accent").opacity(0.12))
            .foregroundColor(Color("Accent"))
            .clipShape(Capsule())
    }
}
