import SwiftUI

// MARK: - HumidorView
// Brukerens personlige sigarsamling — appens landingsside.

struct HumidorView: View {

    @EnvironmentObject var authService: AuthService
    @State private var entries: [HumidorEntry] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showLoginSheet = false
    private let humidorService = HumidorService()

    // MARK: Legg til sigar (foto / bibliotek / manuelt)
    @StateObject private var scanService = ScanService()
    @State private var capturedImage: UIImage?
    @State private var showCameraPicker = false
    @State private var showLibraryPicker = false
    @State private var showManualAdd = false
    @State private var showAddMenu = false
    @State private var navigateToResults = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if authService.userId == nil {
                        LoggedOutHumidorView(onLogin: { showLoginSheet = true })
                    } else if isLoading {
                        ProgressView("Laster humidor...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if entries.isEmpty {
                        EmptyHumidorView(
                            onCamera: { showCameraPicker = true },
                            onLibrary: { showLibraryPicker = true },
                            onManual: { showManualAdd = true }
                        )
                    } else {
                        List {
                            ForEach(entries) { entry in
                                if let cigar = entry.cigar {
                                    NavigationLink(destination: CigarDetailView(cigar: cigar, humidorEntry: entry)) {
                                        HumidorRow(entry: entry)
                                    }
                                }
                            }
                            .onDelete(perform: deleteEntries)
                        }
                    }
                }

                // FAB — kun når humidoren har innhold
                if authService.userId != nil && !isLoading && !entries.isEmpty {
                    Button(action: { showAddMenu = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color("Accent"))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Min Humidor")
            .onAppear { Task { await loadHumidor() } }
            .refreshable { await loadHumidor() }
            .sheet(isPresented: $showLoginSheet) {
                AuthView(onSuccess: { Task { await loadHumidor() } })
            }
            .sheet(isPresented: $showCameraPicker) {
                ImagePicker(image: $capturedImage, sourceType: .camera) {
                    if let image = capturedImage {
                        Task { await scanService.scanBandImage(image) }
                    }
                }
            }
            .sheet(isPresented: $showLibraryPicker) {
                ImagePicker(image: $capturedImage, sourceType: .photoLibrary) {
                    if let image = capturedImage {
                        Task { await scanService.scanBandImage(image) }
                    }
                }
            }
            .sheet(isPresented: $showManualAdd, onDismiss: { Task { await loadHumidor() } }) {
                NavigationStack {
                    ManualAddSearchView()
                }
            }
            .navigationDestination(isPresented: $navigateToResults) {
                ResultsView(results: scanService.scanResults, ocrText: scanService.extractedText)
            }
            .confirmationDialog("Legg til sigar", isPresented: $showAddMenu, titleVisibility: .visible) {
                Button("Ta bilde") { showCameraPicker = true }
                Button("Velg fra bibliotek") { showLibraryPicker = true }
                Button("Legg til manuelt") { showManualAdd = true }
                Button("Avbryt", role: .cancel) {}
            }
            .onChange(of: scanService.scanResults) { _, results in
                guard !results.isEmpty else { return }
                // Alltid til ResultsView — beste treff øverst (sortert på konfidens).
                navigateToResults = true
            }
            .alert("Feil", isPresented: .constant(scanService.errorMessage != nil)) {
                Button("OK") { scanService.errorMessage = nil }
            } message: {
                Text(scanService.errorMessage ?? "")
            }
        }
    }

    private func loadHumidor() async {
        guard let userId = authService.userId else {
            isLoading = false
            return
        }
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
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.cigar?.brand ?? "Ukjent")
                    .font(.headline)
                if let subtitle = subtitleText {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(Color("TextSecondary"))
                        .lineLimit(1)
                }
            }

            Spacer()

            // Antall — tydelig størrelse
            VStack(alignment: .trailing, spacing: 0) {
                Text("\(entry.quantity)")
                    .font(.title3.bold())
                    .foregroundColor(Color("TextPrimary"))
                Text("stk")
                    .font(.caption)
                    .foregroundColor(Color("TextSecondary"))
            }
        }
        .padding(.vertical, 4)
    }

    private var subtitleText: String? {
        let parts = [entry.cigar?.series, entry.cigar?.vitola].compactMap { $0 }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: " · ")
    }
}

// MARK: - Ikke innlogget
struct LoggedOutHumidorView: View {
    var onLogin: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundColor(Color("TextSecondary").opacity(0.5))
            Text("Logg inn for å se humidoren din")
                .font(.title3.bold())
                .multilineTextAlignment(.center)
            Text("Du kan fortsatt scanne og søke opp sigarer\nuten å være innlogget")
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)

            Button(action: onLogin) {
                Text("Logg inn")
                    .fontWeight(.semibold)
                    .frame(maxWidth: 200)
                    .padding()
                    .background(Color("Accent"))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Tom humidor
struct EmptyHumidorView: View {
    var onCamera: () -> Void
    var onLibrary: () -> Void
    var onManual: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "archivebox")
                .font(.system(size: 60))
                .foregroundColor(Color("TextSecondary").opacity(0.5))
            Text("Humidoren er tom")
                .font(.title3.bold())
            Text("Legg til din første sigar for\nå bygge din samling")
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                AddOptionButton(icon: "camera.fill", title: "Ta bilde", style: .filled, action: onCamera)
                AddOptionButton(icon: "photo.on.rectangle", title: "Velg fra bibliotek", style: .outlined, action: onLibrary)
                AddOptionButton(icon: "pencil.line", title: "Legg til manuelt", style: .outlined, action: onManual)
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Knapp for å legge til sigar (brukt i tom-state og i manuelt-søk)
struct AddOptionButton: View {
    enum Style { case filled, outlined }

    let icon: String
    let title: String
    let style: Style
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(style == .filled ? Color("Accent") : Color("Surface"))
            .foregroundColor(style == .filled ? .white : Color("Accent"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

// MARK: - Legg til manuelt (søk + velg sigar)
struct ManualAddSearchView: View {

    private let cigarService = CigarService()
    @State private var searchQuery = ""
    @State private var searchResults: [Cigar] = []
    @State private var isSearching = false
    @State private var searchError: String?
    @State private var hasSearched = false

    var body: some View {
        List {
            Section(header: Text("Søk på merke eller serie")) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color("TextSecondary"))
                    TextField("F.eks. My Father, Padron...", text: $searchQuery)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.search)
                        .onSubmit { Task { await runSearch() } }
                    if isSearching {
                        ProgressView()
                    }
                }
                .padding(.vertical, 4)

                if let searchError {
                    Text(searchError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                if hasSearched && searchResults.isEmpty && searchError == nil && !isSearching {
                    Text("Ingen sigarer matchet søket «\(searchQuery)».")
                        .font(.caption)
                        .foregroundColor(Color("TextSecondary"))
                }

                ForEach(searchResults) { cigar in
                    NavigationLink(destination: CigarDetailView(cigar: cigar)) {
                        CigarRow(cigar: cigar)
                    }
                }
            }
        }
        .navigationTitle("Legg til manuelt")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func runSearch() async {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            hasSearched = false
            return
        }
        isSearching = true
        searchError = nil
        hasSearched = true
        do {
            searchResults = try await cigarService.searchCigars(query: query)
        } catch {
            searchResults = []
            searchError = "Søket feilet. Sjekk internettforbindelsen og prøv igjen."
        }
        isSearching = false
    }
}
