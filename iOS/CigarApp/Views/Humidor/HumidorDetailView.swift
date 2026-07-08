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
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                heroImage

                // Navn + metadata (samme stil som origin/vitola i sigar-detalj)
                VStack(alignment: .leading, spacing: 18) {
                    Text(humidor.name)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(Color("TextPrimary"))
                        .tracking(-0.4)

                    VStack(alignment: .leading, spacing: 10) {
                        if let type = humidor.typeEnum {
                            infoRow(icon: type.icon, text: type.displayName)
                        }
                        if let loc = humidor.location, !loc.isEmpty {
                            infoRow(icon: "mappin", text: loc)
                        }
                        infoRow(icon: "square.stack.3d.up.fill", text: capacityLabel)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                cigarListSection
                    .padding(.top, 28)
            }
            .padding(.bottom, 48)
        }
        .background(Color("Background"))
        .overlay {
            if isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(humidor.name)
        .navigationBarTitleDisplayMode(.inline)
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

    // ── Hero image (som i sigar-detalj) ──────────────────────────────────────
    @ViewBuilder
    private var heroImage: some View {
        Group {
            if let urlStr = humidor.imageURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img): img.resizable().scaledToFill()
                    default: heroPlaceholder
                    }
                }
            } else {
                heroPlaceholder
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .clipped()
    }

    private var heroPlaceholder: some View {
        Rectangle()
            .fill(LinearGradient(colors: [Color("Surface"), Color("Background")],
                                 startPoint: .top, endPoint: .bottom))
            .overlay {
                Image(systemName: humidor.typeEnum?.icon ?? "archivebox")
                    .font(.system(size: 46))
                    .foregroundColor(Color("Accent").opacity(0.5))
            }
    }

    @ViewBuilder
    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundColor(Color("TextPrimary"))
                .frame(width: 20, alignment: .center)
            Text(text)
                .font(.system(size: 18))
                .foregroundColor(Color("TextPrimary"))
        }
    }

    // ── Sigarliste ───────────────────────────────────────────────────────────
    @ViewBuilder
    private var cigarListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SIGARER")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color("TextSecondary"))
                .tracking(0.6)
                .padding(.horizontal, 20)

            if visibleEntries.isEmpty && !isLoading {
                VStack(spacing: 12) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 44))
                        .foregroundColor(Color("TextSecondary").opacity(0.5))
                    Text("Ingen sigarer her ennå")
                        .font(.headline)
                        .foregroundColor(Color("TextPrimary"))
                    Text("Legg til sigarer fra Utforsk eller scan,\nog velg denne humidoren.")
                        .font(.subheadline)
                        .foregroundColor(Color("TextSecondary"))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .padding(.horizontal, 32)
            } else {
                VStack(spacing: 0) {
                    ForEach(visibleEntries) { entry in
                        if let cigar = entry.cigar {
                            NavigationLink(destination: CigarDetailViewDesign(cigar: cigar, humidorEntry: entry)) {
                                HumidorRow(entry: entry)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)
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
                            if entry.id != visibleEntries.last?.id {
                                Divider().padding(.leading, 16)
                            }
                        }
                    }
                }
                .background(Color("Card"))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.horizontal, 16)
            }
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
