import SwiftUI

// MARK: - HumidorView
// Brukerens personlige sigarsamling

struct HumidorView: View {

    @EnvironmentObject var authService: AuthService
    @State private var entries: [HumidorEntry] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    private let humidorService = HumidorService()

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Laster humidor...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if entries.isEmpty {
                    EmptyHumidorView()
                } else {
                    List {
                        ForEach(entries) { entry in
                            if let cigar = entry.cigar {
                                NavigationLink(destination: CigarDetailView(cigar: cigar)) {
                                    HumidorRow(entry: entry)
                                }
                            }
                        }
                        .onDelete(perform: deleteEntries)
                    }
                }
            }
            .navigationTitle("Min Humidor")
            .task { await loadHumidor() }
            .refreshable { await loadHumidor() }
        }
    }

    private func loadHumidor() async {
        guard let userId = authService.userId else { return }
        isLoading = true
        do {
            entries = try await humidorService.fetchHumidor(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func deleteEntries(at offsets: IndexSet) {
        Task {
            for index in offsets {
                try? await humidorService.removeFromHumidor(entryId: entries[index].id)
            }
            await loadHumidor()
        }
    }
}

// MARK: - Humidor Row
struct HumidorRow: View {

    let entry: HumidorEntry

    var body: some View {
        HStack(spacing: 12) {
            // Bilde
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color("Surface"))
                    .frame(width: 56, height: 56)
                Image(systemName: "leaf.fill")
                    .foregroundColor(Color("Accent"))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.cigar?.brand ?? "Ukjent")
                    .font(.headline)
                if let series = entry.cigar?.series {
                    Text(series)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                if let vitola = entry.cigar?.vitola {
                    Text(vitola)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Antall
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.quantity)")
                    .font(.title3.bold())
                    .foregroundColor(Color("Accent"))
                Text("stk")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Tom humidor
struct EmptyHumidorView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "archivebox")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            Text("Humidoren er tom")
                .font(.title3.bold())
            Text("Scan en sigar og legg den til\nfor å bygge din samling")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
