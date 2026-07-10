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

    var body: some View {
        NavigationStack {
            Group {
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
            .background(Color("Background"))
            .navigationTitle("Kø")
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
