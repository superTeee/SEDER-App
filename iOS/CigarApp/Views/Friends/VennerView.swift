import SwiftUI

// MARK: - VennerView
// Venner-fanen: din kode, søk etter brukere, innkommende
// forespørsler og venneliste. Tab-meny skiller "Venner" og "Forespørsler".

struct VennerView: View {

    @EnvironmentObject var authService: AuthService
    @Environment(\.colorScheme) private var colorScheme
    private let friendService = FriendService()

    @State private var myProfile: Profile?
    @State private var entries: [FriendEntry] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showLoginSheet = false

    // Faner
    @State private var selectedTab = 0

    // Søk
    @State private var searchQuery = ""
    @State private var searchResults: [UserSearchResult] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

    // Send-status
    @State private var isSubmitting = false
    @State private var submitError: String?
    @State private var submitSuccess: String?

    private var incomingRequests: [FriendEntry] {
        entries.filter { $0.isPending && $0.isIncoming }
    }
    private var outgoingRequests: [FriendEntry] {
        entries.filter { $0.isPending && $0.isOutgoing }
    }
    private var friends: [FriendEntry] {
        entries.filter { $0.isAccepted }
    }
    private var pendingCount: Int { incomingRequests.count + outgoingRequests.count }

    var body: some View {
        NavigationStack {
            List {
                if authService.userId != nil && !isLoading {
                    if !searchQuery.isEmpty {
                        // Søkeresultater — vises uavhengig av valgt fane
                        searchSection
                    } else {
                        // "Din kode" er alltid øverst
                        myCodeSection

                        // Tab-velger under "Din kode"
                        Section {
                            tabPicker
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(Color("Background"))

                        if selectedTab == 0 {
                            friendsOnlySection
                        } else {
                            forespørslerSection
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color("Background"))
            .searchable(text: $searchQuery,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Søk på navn eller kode")
            .onChange(of: searchQuery) { _, newValue in
                submitError = nil
                submitSuccess = nil
                scheduleSearch(query: newValue)
            }
            .overlay {
                if authService.userId == nil {
                    LoggedOutVennerView(onLogin: { showLoginSheet = true })
                        .background(Color("Background"))
                } else if isLoading {
                    ProgressView("Laster venner...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color("Background"))
                }
            }
            .navigationTitle("Venner")
            .navigationBarTitleDisplayMode(.inline)   // liten sentrert tittel
            .toolbarBackground(Color("Background"), for: .navigationBar)
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .onAppear { Task { await loadAll() } }
            .refreshable { await loadAll() }
            .sheet(isPresented: $showLoginSheet) {
                AuthView(onSuccess: { Task { await loadAll() } })
            }
            .alert("Feil", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Tab-velger

    private var tabPicker: some View {
        HStack(spacing: 0) {
            tabButton(title: "Venner", count: nil, index: 0)
            tabButton(title: "Forespørsler", count: pendingCount > 0 ? pendingCount : nil, index: 1)
        }
        .background(Color("Card"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func tabButton(title: String, count: Int?, index: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { selectedTab = index }
        } label: {
            HStack(spacing: 5) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                if let count {
                    Text("\(count)")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(selectedTab == index ? Color("Background") : Color.clear)
            .foregroundColor(selectedTab == index ? Color("TextPrimary") : Color("TextSecondary"))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .padding(3)
    }

    // MARK: - Venner-fane (uten "Din kode" — den vises alltid øverst)

    @ViewBuilder
    private var friendsOnlySection: some View {
        Section("Venner (\(friends.count))") {
            if friends.isEmpty {
                Text("Ingen venner enda. Søk etter en venn i søkefeltet.")
                    .font(.subheadline)
                    .foregroundColor(Color("TextSecondary"))
                    .listRowBackground(Color("Card"))
            } else {
                ForEach(friends) { entry in
                    NavigationLink {
                        UserProfileView(userId: entry.otherUserId, isOwnProfile: false)
                            .environmentObject(authService)
                    } label: {
                        FriendRow(entry: entry, onRemove: { remove(entry) })
                    }
                    .listRowBackground(Color("Card"))
                }
            }
        }
    }

    // MARK: - Forespørsler-fane

    @ViewBuilder
    private var forespørslerSection: some View {
        if incomingRequests.isEmpty && outgoingRequests.isEmpty {
            Section {
                Text("Ingen forespørsler for øyeblikket.")
                    .font(.subheadline)
                    .foregroundColor(Color("TextSecondary"))
                    .listRowBackground(Color("Card"))
            }
        }

        if !incomingRequests.isEmpty {
            Section("Innkommende") {
                ForEach(incomingRequests) { entry in
                    IncomingRequestRow(
                        entry: entry,
                        onAccept: { respond(entry, accept: true) },
                        onDecline: { respond(entry, accept: false) }
                    )
                    .listRowBackground(Color("Card"))
                }
            }
        }

        if !outgoingRequests.isEmpty {
            Section("Sendt, venter på svar") {
                ForEach(outgoingRequests) { entry in
                    OutgoingRequestRow(entry: entry, onCancel: { remove(entry) })
                        .listRowBackground(Color("Card"))
                }
            }
        }
    }

    // MARK: - Søkeresultater

    @ViewBuilder
    private var searchSection: some View {
        Section {
            if let submitError {
                Text(submitError)
                    .font(.caption)
                    .foregroundColor(.red)
                    .listRowBackground(Color("Card"))
            }
            if let submitSuccess {
                Text(submitSuccess)
                    .font(.caption)
                    .foregroundColor(.green)
                    .listRowBackground(Color("Card"))
            }

            if isSearching {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color("Card"))
            } else if searchResults.isEmpty {
                if searchQuery.count >= 2 {
                    Text("Ingen brukere funnet")
                        .font(.subheadline)
                        .foregroundColor(Color("TextSecondary"))
                        .listRowBackground(Color("Card"))
                }
            } else {
                ForEach(searchResults) { result in
                    SearchResultRow(
                        result: result,
                        isSubmitting: isSubmitting,
                        onSend: { sendFromSearch(result) }
                    )
                    .listRowBackground(Color("Card"))
                }
            }
        }
    }

    // MARK: - Min kode

    private var myCodeSection: some View {
        Section("Din kode") {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Del denne med en venn")
                        .font(.caption)
                        .foregroundColor(Color("TextSecondary"))
                    Text(myProfile?.friendCode ?? "—")
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.bold)
                }
                Spacer()
                if let code = myProfile?.friendCode {
                    ShareLink(item: "Legg meg til som venn i Vitola! Min kode: \(code)") {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color("Accent"))
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Actions

    private func loadAll() async {
        guard let userId = authService.userId else {
            isLoading = false
            return
        }
        isLoading = true
        do {
            myProfile = try await friendService.fetchMyProfile(userId: userId)
            entries = try await friendService.fetchFriendsAndRequests()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func scheduleSearch(query: String) {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else {
            searchResults = []
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            isSearching = true
            do {
                searchResults = try await friendService.searchUsers(query: trimmed)
            } catch {
                searchResults = []
            }
            isSearching = false
        }
    }

    private func sendFromSearch(_ result: UserSearchResult) {
        guard !isSubmitting else { return }
        isSubmitting = true
        submitError = nil
        submitSuccess = nil
        Task {
            do {
                try await friendService.sendFriendRequest(code: result.friendCode)
                submitSuccess = "Forespørsel sendt til \(result.displayName)!"
                searchResults = []
                searchQuery = ""
                await loadAll()
            } catch {
                submitError = error.localizedDescription
            }
            isSubmitting = false
        }
    }

    private func respond(_ entry: FriendEntry, accept: Bool) {
        Task {
            do {
                try await friendService.respondToRequest(friendshipId: entry.id, accept: accept)
                await loadAll()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func remove(_ entry: FriendEntry) {
        Task {
            do {
                try await friendService.removeFriendship(friendshipId: entry.id)
                await loadAll()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - SearchResultRow

struct SearchResultRow: View {
    let result: UserSearchResult
    let isSubmitting: Bool
    var onSend: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(url: result.avatarUrl, name: result.displayName, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(result.displayName)
                    .font(.headline)
                Text(result.friendCode)
                    .font(.caption)
                    .foregroundColor(Color("TextSecondary"))
                    .fontDesign(.monospaced)
            }
            Spacer()
            Button(action: onSend) {
                Text("Legg til")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color("Accent"))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isSubmitting)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Rows

struct IncomingRequestRow: View {
    let entry: FriendEntry
    var onAccept: () -> Void
    var onDecline: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(url: entry.otherAvatarUrl, name: entry.displayName, size: 36)
            Text(entry.displayName)
                .font(.headline)
                .foregroundColor(Color("TextPrimary"))

            Spacer()

            Button(action: onDecline) {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color("TextSecondary"))
            }
            .buttonStyle(.plain)

            Button(action: onAccept) {
                Text("Godkjenn")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(.green)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

struct OutgoingRequestRow: View {
    let entry: FriendEntry
    var onCancel: () -> Void

    var body: some View {
        HStack {
            Text(entry.displayName)
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
            Spacer()
            Button("Avbryt", role: .destructive, action: onCancel)
                .font(.caption)
        }
    }
}

struct FriendRow: View {
    let entry: FriendEntry
    var onRemove: () -> Void

    var body: some View {
        HStack {
            AvatarView(url: entry.otherAvatarUrl, name: entry.displayName, size: 36)
            Text(entry.displayName)
                .font(.headline)
            Spacer()
        }
        .swipeActions {
            Button("Fjern", role: .destructive, action: onRemove)
        }
    }
}

// MARK: - Ikke innlogget

struct LoggedOutVennerView: View {
    var onLogin: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 48))
                .foregroundColor(Color("TextSecondary").opacity(0.5))
            Text("Logg inn for å se vennene dine")
                .font(.title3.bold())
                .multilineTextAlignment(.center)
            Text("Legg til venner og se delte humidorer\nnår du er innlogget")
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
