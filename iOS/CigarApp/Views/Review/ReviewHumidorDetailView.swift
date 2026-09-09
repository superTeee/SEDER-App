import SwiftUI

/// Storage-focused humidor detail for the App Review build.
/// Keeps RH/history/inventory while routing cigar rows to the neutral reference detail.
struct ReviewHumidorDetailView: View {
    let humidor: Humidor
    let allHumidors: [Humidor]
    var onChanged: () -> Void

    @EnvironmentObject var authService: AuthService
    @Environment(\.colorScheme) private var colorScheme

    private let humidorService = HumidorService()

    @State private var entries: [HumidorEntry] = []
    @State private var readings: [HumidorRHReading] = []
    @State private var isLoading = true
    @State private var showEdit = false
    @State private var showRHSheet = false
    @State private var showRHHistory = false

    private var visibleEntries: [HumidorEntry] {
        entries.filter { $0.quantity > 0 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                rhCard
                inventorySection
            }
            .padding(16)
            .padding(.bottom, 60)
        }
        .background(Color("Background").ignoresSafeArea())
        .overlay {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color("Background").opacity(0.8))
            }
        }
        .navigationTitle(humidor.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEdit = true
                } label: {
                    Image(systemName: "pencil")
                }
                .accessibilityLabel("Rediger humidor")
            }
        }
        .sheet(isPresented: $showEdit) {
            if let userId = authService.userId {
                CreateHumidorSheet(existing: humidor, userId: userId, onSaved: {
                    onChanged()
                    Task { await load() }
                })
            }
        }
        .sheet(isPresented: $showRHSheet) {
            RHReadingSheet(humidorId: humidor.id, onSaved: { Task { await load() } })
        }
        .navigationDestination(isPresented: $showRHHistory) {
            RHHistoryView(humidor: humidor, readings: readings)
        }
        .task { await load() }
        .refreshable { await load() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(humidor.name)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color("TextPrimary"))

            HStack(spacing: 14) {
                if let type = humidor.typeEnum {
                    Label(type.displayName, systemImage: type.icon)
                }
                if let location = humidor.location, !location.isEmpty {
                    Label(location, systemImage: "mappin")
                }
            }
            .font(.subheadline)
            .foregroundColor(Color("TextSecondary"))

            HStack(spacing: 14) {
                Label("\(visibleEntries.reduce(0) { $0 + $1.quantity }) sigarer", systemImage: "archivebox")
                if let capacity = humidor.capacity {
                    Text("Kapasitet \(capacity)")
                }
            }
            .font(.caption)
            .foregroundColor(Color("TextSecondary"))
        }
    }

    private var rhCard: some View {
        let latest = readings.first
        let status = humidor.rhStatus(for: latest?.rh)

        return VStack(alignment: .leading, spacing: 12) {
            Text("LUFTFUKTIGHET (RH)")
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.6)
                .foregroundColor(Color("TextSecondary"))

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(latest.map { String(format: "%.0f %% RH", $0.rh) } ?? "— % RH")
                            .font(.system(size: 27, weight: .bold))
                            .foregroundColor(Color("TextPrimary"))
                        if let target = humidor.rhTargetLabel {
                            Text("Mål: \(target)")
                                .font(.caption)
                                .foregroundColor(Color("TextSecondary"))
                        }
                    }
                    Spacer()
                    Text(status.label)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color("TextSecondary"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color("TextSecondary").opacity(0.10))
                        .clipShape(Capsule())
                }

                if let latest {
                    Text("Sist registrert \(latest.measuredAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(Color("TextSecondary"))
                }

                HStack(spacing: 10) {
                    Button {
                        showRHSheet = true
                    } label: {
                        Label("Registrer", systemImage: "plus.circle")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color("Accent"))

                    Button {
                        showRHHistory = true
                    } label: {
                        Label("Historikk", systemImage: "chart.xyaxis.line")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color("TextSecondary"))
                    .disabled(readings.isEmpty)
                }
            }
            .padding(14)
            .background(Color("Card"))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var inventorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("INVENTAR")
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.6)
                .foregroundColor(Color("TextSecondary"))

            if visibleEntries.isEmpty && !isLoading {
                Text("Ingen sigarer registrert i denne humidoren.")
                    .font(.subheadline)
                    .foregroundColor(Color("TextSecondary"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color("Card"))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                VStack(spacing: 0) {
                    ForEach(visibleEntries) { entry in
                        if let cigar = entry.cigar {
                            NavigationLink(destination: ReviewCigarDetailView(cigar: cigar)) {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(cigar.brand)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color("TextPrimary"))
                                        let subtitle = [cigar.series, cigar.vitola ?? cigar.commonFormat]
                                            .compactMap { $0 }
                                            .filter { !$0.isEmpty }
                                            .joined(separator: " · ")
                                        if !subtitle.isEmpty {
                                            Text(subtitle)
                                                .font(.subheadline)
                                                .foregroundColor(Color("TextSecondary"))
                                        }
                                    }
                                    Spacer()
                                    Text("\(entry.quantity) stk")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(Color("TextSecondary"))
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(Color("TextSecondary").opacity(0.5))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                if allHumidors.count > 1 {
                                    Menu("Flytt til humidor") {
                                        ForEach(allHumidors.filter { $0.id != humidor.id }) { target in
                                            Button(target.name) { move(entry, to: target.id) }
                                        }
                                    }
                                }
                                Button("Fjern fra humidor", role: .destructive) {
                                    remove(entry)
                                }
                            }

                            if entry.id != visibleEntries.last?.id {
                                Divider().padding(.leading, 14)
                            }
                        }
                    }
                }
                .background(Color("Card"))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    @MainActor
    private func load() async {
        guard let userId = authService.userId else {
            isLoading = false
            return
        }

        isLoading = true
        let allEntries = (try? await humidorService.fetchHumidor(userId: userId)) ?? []
        entries = allEntries.filter { $0.humidorId == humidor.id }
        readings = (try? await humidorService.fetchRHReadings(humidorId: humidor.id)) ?? []
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
}
