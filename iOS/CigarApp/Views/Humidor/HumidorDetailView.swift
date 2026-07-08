import SwiftUI

// MARK: - HumidorDetailView
// Viser sigarene i én humidor. Per-sigar kontekstmeny for å flytte mellom humidorer.
// Toolbar: rediger / slett humidor (med bekreftelse).

struct HumidorDetailView: View {

    let humidor: Humidor
    let allHumidors: [Humidor]
    var onChanged: () -> Void

    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    private let humidorService = HumidorService()

    @State private var entries: [HumidorEntry] = []
    @State private var isLoading = true
    @State private var showEdit = false
    @State private var showDeleteConfirm = false

    private var visibleEntries: [HumidorEntry] {
        entries.filter { $0.quantity > 0 }
    }

    var body: some View {
        List {
            // Info-topp
            Section {
                HStack(spacing: 14) {
                    coverThumb
                    VStack(alignment: .leading, spacing: 3) {
                        if let type = humidor.typeEnum {
                            Label(type.displayName, systemImage: type.icon)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(Color("TextPrimary"))
                        }
                        if let loc = humidor.location, !loc.isEmpty {
                            Text(loc).font(.caption).foregroundColor(Color("TextSecondary"))
                        }
                        Text(capacityLabel)
                            .font(.caption).foregroundColor(Color("TextSecondary"))
                    }
                    Spacer()
                }
            }
            .listRowBackground(Color("Card"))

            Section("Sigarer") {
                ForEach(visibleEntries) { entry in
                    if let cigar = entry.cigar {
                        NavigationLink(destination: CigarDetailViewDesign(cigar: cigar, humidorEntry: entry)) {
                            HumidorRow(entry: entry)
                        }
                        .listRowBackground(Color("Card"))
                        .contextMenu {
                            if allHumidors.count > 1 {
                                Menu {
                                    ForEach(allHumidors.filter { $0.id != humidor.id }) { h in
                                        Button(h.name) { move(entry, to: h.id) }
                                    }
                                } label: {
                                    Label("Flytt til humidor", systemImage: "arrow.right.arrow.left")
                                }
                            }
                            Button(role: .destructive) { remove(entry) } label: {
                                Label("Fjern fra humidor", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { remove(entry) } label: {
                                Label("Fjern", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color("Background"))
        .overlay {
            if isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if visibleEntries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 48))
                        .foregroundColor(Color("TextSecondary").opacity(0.5))
                    Text("Ingen sigarer her ennå")
                        .font(.headline)
                    Text("Legg til sigarer fra Utforsk eller scan,\nog velg denne humidoren.")
                        .font(.subheadline)
                        .foregroundColor(Color("TextSecondary"))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color("Background"))
            }
        }
        .navigationTitle(humidor.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEdit = true } label: { Label("Rediger humidor", systemImage: "pencil") }
                    Button(role: .destructive) { showDeleteConfirm = true } label: {
                        Label("Slett humidor", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog("Slett humidoren «\(humidor.name)»?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Slett humidor", role: .destructive) { deleteHumidor() }
            Button("Avbryt", role: .cancel) {}
        } message: {
            Text("Humidoren slettes. Sigarene beholdes, men blir ikke lenger tilknyttet en humidor.")
        }
        .sheet(isPresented: $showEdit) {
            if let userId = authService.userId {
                CreateHumidorSheet(existing: humidor, userId: userId, onSaved: {
                    onChanged()
                    Task { await load() }
                })
            }
        }
        .task { await load() }
        .refreshable { await load() }
    }

    @ViewBuilder
    private var coverThumb: some View {
        if let urlStr = humidor.imageURL, let url = URL(string: urlStr) {
            AsyncImage(url: url) { img in img.resizable().scaledToFill() } placeholder: { placeholder }
                .frame(width: 60, height: 60).clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8).fill(Color("Accent").opacity(0.12)).frame(width: 60, height: 60)
            Image(systemName: humidor.typeEnum?.icon ?? "archivebox").foregroundColor(Color("Accent"))
        }
    }

    private var capacityLabel: String {
        let count = visibleEntries.reduce(0) { $0 + $1.quantity }
        if let cap = humidor.capacity {
            return "\(count) / \(cap) sigarer"
        }
        return "\(count) sigarer"
    }

    private func load() async {
        guard let userId = authService.userId else { isLoading = false; return }
        isLoading = true
        let all = (try? await humidorService.fetchHumidor(userId: userId)) ?? []
        entries = all.filter { $0.humidorId == humidor.id }
        isLoading = false
    }

    private func move(_ entry: HumidorEntry, to humidorId: UUID) {
        Task {
            try? await humidorService.moveEntry(entryId: entry.id, toHumidorId: humidorId)
            await load()
            onChanged()
        }
    }

    private func remove(_ entry: HumidorEntry) {
        Task {
            try? await humidorService.removeFromHumidor(entryId: entry.id)
            await load()
            onChanged()
        }
    }

    private func deleteHumidor() {
        Task {
            try? await humidorService.deleteHumidor(id: humidor.id)
            onChanged()
            dismiss()
        }
    }
}
