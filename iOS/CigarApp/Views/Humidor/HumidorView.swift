import SwiftUI
import Kingfisher

// MARK: - HumidorView
// Brukerens personlige sigarsamling — med støtte for ønskeliste.

enum HumidorTab { case humidor, favorites, wishlist }

struct HumidorView: View {

    @EnvironmentObject var authService: AuthService
    @Environment(\.colorScheme) private var colorScheme

    // Humidor-state
    @State private var entries: [HumidorEntry] = []
    @State private var humidors: [Humidor] = []
    @State private var latestReadings: [UUID: HumidorRHReading] = [:]
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showLoginSheet = false
    @State private var showCreateHumidor = false
    private let humidorService = HumidorService()

    // Ønskeliste-state
    @State private var wishlistCigars: [Cigar] = []
    @State private var isLoadingWishlist = false
    private let wishlistService = WishlistService()

    // Favoritt-state
    @State private var favoriteCigars: [Cigar] = []
    @State private var isLoadingFavorites = false
    private let favoriteService = FavoriteService()

    // Tab-valg
    @State private var selectedTab: HumidorTab = .humidor

    // Badge-kontroll: slettes når bruker besøker humidor
    @AppStorage("humidorHasNew") private var humidorHasNew: Bool = false

    // MARK: Legg til sigar (foto / bibliotek / manuelt)
    @StateObject private var scanService = ScanService()
    @State private var capturedImage: UIImage?
    @State private var showCameraPicker = false
    @State private var showLibraryPicker = false
    @State private var showManualAdd = false
    @State private var navigateToResults = false

    // Styl den native segmented-controlleren så den matcher paletten (varme kort-toner
    // i stedet for Apples kalde system-grå).
    init(initialTab: HumidorTab = .humidor) {
        _selectedTab = State(initialValue: initialTab)
        let seg = UISegmentedControl.appearance()
        // Valgt segment bruker en tydelig lysere, varm tone (SegmentActive) enn track-en
        // (Background) — paletten er ellers så mørk-tett at Card ikke ga nok kontrast.
        seg.selectedSegmentTintColor = UIColor(named: "SegmentActive")
        seg.backgroundColor = UIColor(named: "Background")
        seg.setTitleTextAttributes([.foregroundColor: UIColor(named: "TextPrimary") ?? .white], for: .selected)
        seg.setTitleTextAttributes([.foregroundColor: UIColor(named: "TextSecondary") ?? .gray], for: .normal)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    // Segmentert picker (vises kun når innlogget)
                    if authService.userId != nil {
                        Picker("", selection: $selectedTab) {
                            Text("Humidor").tag(HumidorTab.humidor)
                            Text("Favoritter").tag(HumidorTab.favorites)
                            Text("Ønskeliste").tag(HumidorTab.wishlist)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color("Background"))
                        .onChange(of: selectedTab) { _, tab in
                            if tab == .wishlist { Task { await loadWishlist() } }
                            if tab == .favorites { Task { await loadFavorites() } }
                        }
                    }

                    // Innhold basert på valgt tab
                    if selectedTab == .humidor {
                        // Fullbredde-kort i samme stil som journal-kortene, ikke liste-rader.
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                if authService.userId != nil && !isLoading {
                                    ForEach(humidors) { humidor in
                                        NavigationLink(destination: HumidorDetailView(
                                            humidor: humidor,
                                            allHumidors: humidors,
                                            onChanged: { Task { await loadHumidor() } }
                                        )) {
                                            HumidorCard(humidor: humidor, cigarCount: cigarCount(for: humidor), latestRH: latestReadings[humidor.id])
                                                .padding(12)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .background(Color("Card"))
                                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 32)
                        }
                        .background(Color("Background"))
                        .overlay {
                            if authService.userId == nil {
                                LoggedOutHumidorView(onLogin: { showLoginSheet = true })
                                    .background(Color("Background"))
                            } else if isLoading {
                                ProgressView("Laster humidorer...")
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color("Background"))
                            } else if humidors.isEmpty {
                                EmptyHumidorsView(onCreate: { showCreateHumidor = true })
                                    .background(Color("Background"))
                            }
                        }
                        .refreshable { await loadHumidor() }
                    } else if selectedTab == .favorites {
                        // Favoritter
                        List {
                            if !isLoadingFavorites && !favoriteCigars.isEmpty {
                                Section(header: Text("Favoritter (\(favoriteCigars.count))").textCase(.none).font(.headline.bold()).foregroundColor(Color("TextPrimary"))) {
                                    ForEach(favoriteCigars) { cigar in
                                        NavigationLink(destination: CigarDetailViewDesign(cigar: cigar)) {
                                            WishlistRow(cigar: cigar)
                                        }
                                        .listRowBackground(Color("Card"))
                                    }
                                    .onDelete(perform: deleteFavoriteItems)
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .background(Color("Background"))
                        .overlay {
                            if isLoadingFavorites {
                                ProgressView("Laster favoritter...")
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color("Background"))
                            } else if favoriteCigars.isEmpty {
                                EmptyFavoritesView()
                                    .background(Color("Background"))
                            }
                        }
                        .refreshable { await loadFavorites() }
                    } else {
                        // Ønskeliste
                        List {
                            if !isLoadingWishlist && !wishlistCigars.isEmpty {
                                Section(header: Text("Ønskeliste (\(wishlistCigars.count))").textCase(.none).font(.headline.bold()).foregroundColor(Color("TextPrimary"))) {
                                    ForEach(wishlistCigars) { cigar in
                                        NavigationLink(destination: CigarDetailViewDesign(cigar: cigar)) {
                                            WishlistRow(cigar: cigar)
                                        }
                                        .listRowBackground(Color("Card"))
                                    }
                                    .onDelete(perform: deleteWishlistItems)
                                }
                            } else if !isLoadingWishlist {
                                EmptyView()
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .background(Color("Background"))
                        .overlay {
                            if isLoadingWishlist {
                                ProgressView("Laster ønskeliste...")
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color("Background"))
                            } else if wishlistCigars.isEmpty {
                                EmptyWishlistView()
                                    .background(Color("Background"))
                            }
                        }
                        .refreshable { await loadWishlist() }
                    }
                }
            }
            .navigationTitle("Min Humidor")
            .navigationBarTitleDisplayMode(.inline)   // liten sentrert tittel
            .toolbarBackground(Color("Background"), for: .navigationBar)
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .toolbar {
                if authService.userId != nil && selectedTab == .humidor {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showCreateHumidor = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateHumidor) {
                if let userId = authService.userId {
                    CreateHumidorSheet(userId: userId, onSaved: { Task { await loadHumidor() } })
                }
            }
            .onAppear {
                humidorHasNew = false  // Fjern badge når bruker ser humidor-siden
                Task { await loadHumidor() }
                if selectedTab == .favorites { Task { await loadFavorites() } }
                if selectedTab == .wishlist { Task { await loadWishlist() } }
            }
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
            async let e = humidorService.fetchHumidor(userId: userId)
            async let h = humidorService.fetchHumidors(userId: userId)
            entries = try await e
            humidors = try await h
            latestReadings = (try? await humidorService.fetchLatestRHReadings()) ?? [:]
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Antall sigarer (sum av antall) i en gitt humidor.
    private func cigarCount(for humidor: Humidor) -> Int {
        entries.filter { $0.humidorId == humidor.id && $0.quantity > 0 }
               .reduce(0) { $0 + $1.quantity }
    }

    private func deleteEntries(at offsets: IndexSet) {
        Task {
            for index in offsets {
                try? await humidorService.removeFromHumidor(entryId: entries[index].id)
            }
            await loadHumidor()
        }
    }

    private func loadWishlist() async {
        guard let userId = authService.userId else { return }
        isLoadingWishlist = true
        wishlistCigars = (try? await wishlistService.fetchWishlist(userId: userId)) ?? []
        isLoadingWishlist = false
    }

    private func deleteWishlistItems(at offsets: IndexSet) {
        guard let userId = authService.userId else { return }
        Task {
            for index in offsets {
                try? await wishlistService.removeFromWishlist(userId: userId, cigarId: wishlistCigars[index].id)
            }
            await loadWishlist()
        }
    }

    private func loadFavorites() async {
        guard let userId = authService.userId else { return }
        isLoadingFavorites = true
        favoriteCigars = (try? await favoriteService.fetchFavorites(userId: userId)) ?? []
        isLoadingFavorites = false
    }

    private func deleteFavoriteItems(at offsets: IndexSet) {
        guard let userId = authService.userId else { return }
        Task {
            for index in offsets {
                try? await favoriteService.removeFavorite(userId: userId, cigarId: favoriteCigars[index].id)
            }
            await loadFavorites()
        }
    }
}

// MARK: - Wishlist Row
struct WishlistRow: View {
    let cigar: Cigar

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(cigar.brand)
                .font(.headline)
            if let subtitle = subtitleText {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(Color("TextSecondary"))
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    private var subtitleText: String? {
        let parts = [cigar.series, cigar.vitola].compactMap { $0 }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: " · ")
    }
}

// MARK: - Tom ønskeliste
struct EmptyWishlistView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "bookmark")
                .font(.system(size: 60))
                .foregroundColor(Color("TextSecondary").opacity(0.5))
            Text("Ønskelisten er tom")
                .font(.title3.bold())
            Text("Finn sigarer i Utforsk og trykk\n«Legg i ønskeliste» for å lagre dem her")
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }
}

// MARK: - Empty Favorites
struct EmptyFavoritesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "star")
                .font(.system(size: 60))
                .foregroundColor(Color("TextSecondary").opacity(0.5))
            Text("Ingen favoritter ennå")
                .font(.title3.bold())
            Text("Åpne en sigar og trykk på stjernen\nøverst for å legge den til her")
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
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
                if let days = daysInHumidor {
                    Text("I humidoren · \(days) dager")
                        .font(.caption2)
                        .foregroundColor(Color("TextSecondary").opacity(0.7))
                        .padding(.top, 2)
                }
                if let store = entry.store, !store.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "bag")
                            .font(.system(size: 9))
                        Text("Kjøpt hos \(store)")
                            .font(.caption2)
                            .lineLimit(1)
                    }
                    .foregroundColor(Color("TextSecondary").opacity(0.7))
                }
            }

            Spacer()

            // Antall — sigar-ikon + tall
            HStack(spacing: 5) {
                Image("CigarCount")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 17)
                    .foregroundColor(Color("TextSecondary"))
                Text("\(entry.quantity)")
                    .font(.callout.bold())
                    .foregroundColor(Color("TextPrimary"))
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())   // hele raden trykkbar
    }

    private var daysInHumidor: Int? {
        guard let date = entry.addedToHumidorAt else { return nil }
        return Calendar.current.dateComponents([.day], from: date, to: Date()).day
    }

    private var subtitleText: String? {
        let parts = [entry.cigar?.series, entry.cigar?.vitola].compactMap { $0 }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: " · ")
    }
}

// MARK: - Humidor Card (ett kort i humidor-lista)
struct HumidorCard: View {
    let humidor: Humidor
    let cigarCount: Int
    var latestRH: HumidorRHReading? = nil

    private func rhTrafficColor(_ s: RHStatus) -> Color {
        switch s {
        case .stable:                     return Color(red: 0.25, green: 0.64, blue: 0.30) // grønn
        case .slightlyLow, .slightlyHigh: return Color(red: 0.88, green: 0.64, blue: 0.0)  // gul
        case .tooDry, .tooWet:            return Color(red: 0.84, green: 0.27, blue: 0.27) // rød
        case .none:                       return Color(.tertiaryLabel)
        }
    }
    private func rhString(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.1f", v)
    }
    private func rhLine(_ s: RHStatus) -> String {
        if let r = latestRH { return "\(rhString(r.rh)) % RH · \(s.label)" }
        return "Mål \(humidor.rhTargetLabel ?? "") · \(s.label)"
    }

    var body: some View {
        // Vertikalt kort, samme utforming som journal-kortene: bilde på topp i
        // full bredde, deretter info under.
        VStack(alignment: .leading, spacing: 0) {

            // ── Bilde (full bredde) ───────────────────────────
            Group {
                if let urlStr = humidor.imageURL, let url = URL(string: urlStr) {
                    // Beholder setter størrelsen; bildet som overlay påvirker ikke
                    // bredden (samme scaledToFill-fiks som ellers i appen).
                    Color("Surface")
                        .frame(maxWidth: .infinity)
                        .frame(height: 154)
                        .overlay(
                            KFImage(url)
                                .resizable()
                                .fade(duration: 0.15)
                                .scaledToFill()
                        )
                        .clipped()
                } else {
                    ZStack {
                        Color("Accent").opacity(0.12)
                        Image(systemName: humidor.typeEnum?.icon ?? "archivebox")
                            .font(.system(size: 34))
                            .foregroundColor(Color("Accent"))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 154)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.bottom, 8)

            // ── Rad: navn + meta til venstre, antall til høyre ──
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(humidor.name)
                        .font(.headline)
                        .foregroundColor(Color("TextPrimary"))
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        if let type = humidor.typeEnum {
                            Text(type.displayName)
                        }
                        if let loc = humidor.location, !loc.isEmpty {
                            Text("· \(loc)")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(Color("TextSecondary"))
                    .lineLimit(1)

                    // Trafikklys-status for RH (grønn = stabil, gul = litt av, rød = for tørr/fuktig)
                    if latestRH != nil || humidor.rhTargetLabel != nil {
                        let status = humidor.rhStatus(for: latestRH?.rh)
                        HStack(spacing: 6) {
                            Circle().fill(rhTrafficColor(status)).frame(width: 9, height: 9)
                            Text(rhLine(status))
                                .font(.caption)
                                .foregroundColor(Color("TextSecondary"))
                                .lineLimit(1)
                        }
                        .padding(.top, 3)
                    }
                }

                Spacer()

                // Antall — sigar-ikon + tall (evt. antall/kapasitet)
                HStack(spacing: 5) {
                    Image("CigarCount")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 17)
                    Text(countLabel)
                        .font(.callout.weight(.medium))
                }
                .foregroundColor(Color("TextSecondary"))
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }

    private var countLabel: String {
        if let cap = humidor.capacity { return "\(cigarCount)/\(cap)" }
        return "\(cigarCount)"
    }
}

// MARK: - Tom humidor-liste (ingen humidorer ennå)
struct EmptyHumidorsView: View {
    var onCreate: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "archivebox")
                .font(.system(size: 60))
                .foregroundColor(Color("TextSecondary").opacity(0.5))
            Text("Ingen humidorer ennå")
                .font(.title3.bold())
            Text("Opprett din første humidor for å\norganisere sigarsamlingen din")
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)

            Button(action: onCreate) {
                HStack {
                    Image(systemName: "plus")
                    Text("Opprett humidor").fontWeight(.semibold)
                }
                .frame(maxWidth: 240)
                .padding()
                .background(Color("Accent"))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .padding(.top, 8)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
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
                    .clipShape(RoundedRectangle(cornerRadius: 6))
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
            .clipShape(RoundedRectangle(cornerRadius: 6))
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
                    NavigationLink(destination: CigarDetailViewDesign(cigar: cigar)) {
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
