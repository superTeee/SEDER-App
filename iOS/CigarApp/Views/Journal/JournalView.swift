import SwiftUI

// MARK: - JournalView
// Røykelogg — alle sigarer du har røkt, nyest først.
// Henter fra tasting_logs-tabellen (kobles til cigars via JOIN).

struct JournalView: View {

    @EnvironmentObject var authService: AuthService
    @State private var logs: [TastingLog] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showLoginSheet = false

    private let tastingService = TastingService()

    var body: some View {
        NavigationStack {
            Group {
                if authService.userId == nil {
                    journalLoggedOut
                } else if isLoading {
                    ProgressView("Laster journal...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if logs.isEmpty {
                    journalEmpty
                } else {
                    journalList
                }
            }
            .navigationTitle("Journal")
            .onAppear { Task { await loadLogs() } }
            .refreshable { await loadLogs() }
            .sheet(isPresented: $showLoginSheet) {
                AuthView(onSuccess: { Task { await loadLogs() } })
            }
        }
    }

    // MARK: - Liste

    private var journalList: some View {
        List {
            ForEach(groupedByMonth, id: \.0) { month, entries in
                Section(header: Text(month).textCase(nil)) {
                    ForEach(entries) { log in
                        JournalRow(log: log)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // Grupperer loggene etter måned (f.eks. "Juni 2026")
    private var groupedByMonth: [(String, [TastingLog])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "nb_NO")

        var result: [(String, [TastingLog])] = []
        var current: (String, [TastingLog])? = nil

        for log in logs {
            let label = formatter.string(from: log.smokedAt).capitalized
            if current?.0 == label {
                current?.1.append(log)
            } else {
                if let prev = current { result.append(prev) }
                current = (label, [log])
            }
        }
        if let last = current { result.append(last) }
        return result
    }

    // MARK: - Tilstander

    private var journalLoggedOut: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 48))
                .foregroundColor(Color("TextSecondary").opacity(0.4))
            Text("Logg inn for å se journalen din")
                .font(.title3.bold())
                .multilineTextAlignment(.center)
            Button("Logg inn") { showLoginSheet = true }
                .fontWeight(.semibold)
                .frame(maxWidth: 200)
                .padding()
                .background(Color("Accent"))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var journalEmpty: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(Color("TextSecondary").opacity(0.4))
            Text("Ingen røykte sigarer ennå")
                .font(.title3.bold())
            Text("Gå til en sigar i humidoren\nog trykk «Har røkt den»")
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Data

    private func loadLogs() async {
        guard let userId = authService.userId else {
            isLoading = false
            return
        }
        isLoading = true
        do {
            logs = try await tastingService.fetchLogs(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Journal Row

struct JournalRow: View {

    let log: TastingLog

    private var dateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "d. MMM"
        f.locale = Locale(identifier: "nb_NO")
        return f.string(from: log.smokedAt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(log.cigar?.brand ?? "Ukjent sigar")
                        .font(.headline)
                    if let series = log.cigar?.series {
                        Text(series)
                            .font(.subheadline)
                            .foregroundColor(Color("TextSecondary"))
                    }
                    if let vitola = log.cigar?.vitola {
                        Text(vitola)
                            .font(.caption)
                            .foregroundColor(Color("TextSecondary"))
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(dateLabel)
                        .font(.caption)
                        .foregroundColor(Color("TextSecondary"))
                    if let rating = log.rating, let label = log.scoreLabel {
                        Text("\(rating) · \(label)")
                            .font(.caption.weight(.medium))
                            .foregroundColor(scoreColor(for: rating))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(scoreColor(for: rating).opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }

            if let notes = log.personalNotes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(Color("TextSecondary"))
                    .lineLimit(2)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }

    private func scoreColor(for score: Int) -> Color {
        switch score {
        case 90...100: return Color(red: 0.85, green: 0.65, blue: 0.2)
        case 80...89:  return Color(red: 0.65, green: 0.5,  blue: 0.1)
        case 70...79:  return Color(.systemGray)
        default:       return Color(.systemBrown)
        }
    }
}
