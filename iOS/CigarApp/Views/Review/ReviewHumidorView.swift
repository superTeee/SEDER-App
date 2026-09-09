import SwiftUI

/// Humidor-only collection surface for the App Review build.
/// Favorites and wishlist are intentionally not part of this view.
struct ReviewHumidorView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var proManager: ProManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var humidors: [Humidor] = []
    @State private var latestReadings: [UUID: HumidorRHReading] = [:]
    @State private var isLoading = true
    @State private var showLogin = false
    @State private var showCreateHumidor = false
    @State private var showPaywall = false
    @State private var errorMessage: String?

    private let humidorService = HumidorService()
    private let freeHumidorLimit = 2

    var body: some View {
        NavigationStack {
            Group {
                if authService.userId == nil {
                    loggedOutState
                } else if isLoading {
                    ProgressView("Laster humidorer…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if humidors.isEmpty {
                    emptyState
                } else {
                    humidorList
                }
            }
            .background(Color("Background"))
            .navigationTitle("Humidor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("Background"), for: .navigationBar)
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .toolbar {
                if authService.userId != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            attemptCreateHumidor()
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .accessibilityLabel("Ny humidor")
                    }
                }
            }
            .task { await loadHumidors() }
            .refreshable { await loadHumidors() }
            .sheet(isPresented: $showLogin) {
                AuthView(onSuccess: { Task { await loadHumidors() } })
            }
            .sheet(isPresented: $showCreateHumidor) {
                if let userId = authService.userId {
                    CreateHumidorSheet(
                        userId: userId,
                        onSaved: { Task { await loadHumidors() } }
                    )
                }
            }
            .sheet(isPresented: $showPaywall) {
                SupportView(
                    mode: .unlock,
                    usedHumidors: humidors.count,
                    freeHumidorLimit: freeHumidorLimit
                )
            }
            .alert("Feil", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var humidorList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(humidors) { humidor in
                    NavigationLink(destination: ReviewHumidorDetailView(
                        humidor: humidor,
                        allHumidors: humidors,
                        onChanged: { Task { await loadHumidors() } }
                    )) {
                        humidorCard(humidor)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .padding(.bottom, 70)
        }
    }

    private func humidorCard(_ humidor: Humidor) -> some View {
        let reading = latestReadings[humidor.id]
        let status = humidor.rhStatus(for: reading?.rh)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: humidor.typeEnum?.icon ?? "archivebox")
                    .font(.system(size: 21))
                    .foregroundColor(Color("Accent"))
                    .frame(width: 36, height: 36)
                    .background(Color("Accent").opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 3) {
                    Text(humidor.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color("TextPrimary"))

                    let details = [humidor.type, humidor.location]
                        .compactMap { $0 }
                        .filter { !$0.isEmpty }
                        .joined(separator: " · ")
                    if !details.isEmpty {
                        Text(details)
                            .font(.subheadline)
                            .foregroundColor(Color("TextSecondary"))
                    }
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color("TextSecondary").opacity(0.5))
            }

            HStack(spacing: 16) {
                if let reading {
                    Label(String(format: "%.0f %% RH", reading.rh), systemImage: "humidity")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(Color("TextPrimary"))

                    Text(status.label)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color("TextSecondary"))
                } else if let target = humidor.rhTargetLabel {
                    Label("Mål \(target)", systemImage: "humidity")
                        .font(.subheadline)
                        .foregroundColor(Color("TextSecondary"))
                } else {
                    Label("Ingen RH-måling", systemImage: "humidity")
                        .font(.subheadline)
                        .foregroundColor(Color("TextSecondary"))
                }

                Spacer()

                if let capacity = humidor.capacity {
                    Label("\(capacity)", systemImage: "archivebox")
                        .font(.caption)
                        .foregroundColor(Color("TextSecondary"))
                }
            }
        }
        .padding(14)
        .background(Color("Card"))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var loggedOutState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "archivebox")
                .font(.system(size: 48))
                .foregroundColor(Color("TextSecondary").opacity(0.5))
            Text("Logg inn for å administrere humidorer")
                .font(.headline)
                .multilineTextAlignment(.center)
            Button("Logg inn") { showLogin = true }
                .buttonStyle(.borderedProminent)
                .tint(Color("Accent"))
            Spacer()
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "archivebox")
                .font(.system(size: 52))
                .foregroundColor(Color("TextSecondary").opacity(0.5))
            Text("Ingen humidorer ennå")
                .font(.headline)
            Text("Opprett en humidor for å holde oversikt over lagring og luftfuktighet.")
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Opprett humidor") { attemptCreateHumidor() }
                .buttonStyle(.borderedProminent)
                .tint(Color("Accent"))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func attemptCreateHumidor() {
        if proManager.isPro || StoreManager.shared.isPro || humidors.count < freeHumidorLimit {
            showCreateHumidor = true
        } else {
            showPaywall = true
        }
    }

    @MainActor
    private func loadHumidors() async {
        guard let userId = authService.userId else {
            humidors = []
            isLoading = false
            return
        }

        isLoading = true
        do {
            async let fetchedHumidors = humidorService.fetchHumidors(userId: userId)
            async let readings = humidorService.fetchLatestRHReadings()
            humidors = try await fetchedHumidors
            latestReadings = (try? await readings) ?? [:]
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
