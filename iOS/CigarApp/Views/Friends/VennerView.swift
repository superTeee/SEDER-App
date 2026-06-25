import SwiftUI

// MARK: - VennerView
// Venner-fanen: din egen delbare kode, legg-til-venn, innkommende
// forespørsler, venneliste, og en plassholder for delte humidorer
// (kommer når Min samling støtter flere/delbare humidorer).

struct VennerView: View {

    @EnvironmentObject var authService: AuthService
    private let friendService = FriendService()

    @State private var myProfile: Profile?
    @State private var entries: [FriendEntry] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showLoginSheet = false

    @State private var codeInput = ""
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

    var body: some View {
        NavigationStack {
            Group {
                if authService.userId == nil {
                    LoggedOutVennerView(onLogin: { showLoginSheet = true })
                } else if isLoading {
                    ProgressView("Laster venner...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        myCodeSection
                        addFriendSection

                        if !incomingRequests.isEmpty {
                            Section("Venneforespørsler") {
                                ForEach(incomingRequests) { entry in
                                    IncomingRequestRow(
                                        entry: entry,
                                        onAccept: { respond(entry, accept: true) },
                                        onDecline: { respond(entry, accept: false) }
                                    )
                                }
                            }
                        }

                        Section("Venner (\(friends.count))") {
                            if friends.isEmpty {
                                Text("Ingen venner enda. Del koden din, eller lim inn en venns kode ovenfor.")
                                    .font(.subheadline)
                                    .foregroundColor(Color("TextSecondary"))
                            } else {
                                ForEach(friends) { entry in
                                    FriendRow(entry: entry, onRemove: { remove(entry) })
                                }
                            }
                        }

                        if !outgoingRequests.isEmpty {
                            Section("Sendt, venter på svar") {
                                ForEach(outgoingRequests) { entry in
                                    OutgoingRequestRow(entry: entry, onCancel: { remove(entry) })
                                }
                            }
                        }

                        Section("Delte humidorer") {
                            Text("Kommer snart — når Min samling støtter flere humidorer, kan venner dele en humidor med deg her.")
                                .font(.subheadline)
                                .foregroundColor(Color("TextSecondary"))
                        }
                    }
                }
            }
            .navigationTitle("Venner")
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

    // MARK: - Legg til venn

    private var addFriendSection: some View {
        Section("Legg til venn") {
            HStack {
                TextField("Lim inn venns kode", text: $codeInput)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .submitLabel(.send)
                    .onSubmit { submitCode() }

                if isSubmitting {
                    ProgressView()
                } else {
                    Button("Send") { submitCode() }
                        .fontWeight(.semibold)
                        .disabled(codeInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            if let submitError {
                Text(submitError)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            if let submitSuccess {
                Text(submitSuccess)
                    .font(.caption)
                    .foregroundColor(.green)
            }
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

    private func submitCode() {
        let code = codeInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }
        isSubmitting = true
        submitError = nil
        submitSuccess = nil
        Task {
            do {
                try await friendService.sendFriendRequest(code: code)
                codeInput = ""
                submitSuccess = "Forespørsel sendt!"
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

// MARK: - Rows

struct IncomingRequestRow: View {
    let entry: FriendEntry
    var onAccept: () -> Void
    var onDecline: () -> Void

    var body: some View {
        HStack {
            Text(entry.displayName)
                .font(.headline)
            Spacer()
            Button(action: onDecline) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Color("TextSecondary"))
            }
            .buttonStyle(.plain)
            Button(action: onAccept) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
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
            ZStack {
                Circle()
                    .fill(Color("Surface"))
                    .frame(width: 36, height: 36)
                Image(systemName: "person.fill")
                    .foregroundColor(Color("TextPrimary"))
            }
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
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
