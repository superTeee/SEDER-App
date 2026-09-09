import SwiftUI

/// Neutral record view for the App Review build.
/// Ratings and taste-profile signals are not displayed.
struct ReviewLogView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.colorScheme) private var colorScheme

    @State private var logs: [TastingLog] = []
    @State private var isLoading = true
    @State private var selectedLog: TastingLog?
    @State private var showLogin = false

    private let tastingService = TastingService()

    var body: some View {
        NavigationStack {
            Group {
                if authService.userId == nil {
                    loggedOutState
                } else if isLoading {
                    ProgressView("Laster logg…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if logs.isEmpty {
                    emptyState
                } else {
                    logList
                }
            }
            .background(Color("Background"))
            .navigationTitle("Logg")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("Background"), for: .navigationBar)
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .task { await loadLogs() }
            .refreshable { await loadLogs() }
            .sheet(item: $selectedLog) { log in
                NotesOnlyLogEditor(log: log) {
                    Task { await loadLogs() }
                }
            }
            .sheet(isPresented: $showLogin) {
                AuthView(onSuccess: { Task { await loadLogs() } })
            }
        }
    }

    private var logList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(logs) { log in
                    Button {
                        selectedLog = log
                    } label: {
                        VStack(alignment: .leading, spacing: 7) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(log.cigar?.brand ?? "Ukjent sigar")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color("TextPrimary"))

                                    let subtitle = [log.cigar?.series, log.cigar?.vitola]
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

                                Text(log.smokedAt.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundColor(Color("TextSecondary"))
                            }

                            if let notes = log.personalNotes,
                               !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(notes)
                                    .font(.subheadline)
                                    .foregroundColor(Color("TextSecondary"))
                                    .lineLimit(3)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color("Card"))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .padding(.bottom, 70)
        }
    }

    private var loggedOutState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 46))
                .foregroundColor(Color("TextSecondary").opacity(0.5))
            Text("Logg inn for å se registreringene dine")
                .font(.headline)
            Button("Logg inn") { showLogin = true }
                .buttonStyle(.borderedProminent)
                .tint(Color("Accent"))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 46))
                .foregroundColor(Color("TextSecondary").opacity(0.5))
            Text("Ingen registreringer ennå")
                .font(.headline)
            Text("Registreringer du oppretter vil vises her.")
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @MainActor
    private func loadLogs() async {
        guard let userId = authService.userId else {
            logs = []
            isLoading = false
            return
        }

        isLoading = true
        logs = (try? await tastingService.fetchLogs(userId: userId)) ?? []
        isLoading = false
    }
}

/// Notes-only editor. Existing hidden legacy rating values are preserved in storage,
/// but are not shown or editable in the review build.
struct NotesOnlyLogEditor: View {
    let log: TastingLog
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var date: Date
    @State private var notes: String
    @State private var isSaving = false
    @State private var showDeleteConfirm = false
    @State private var errorMessage: String?

    private let tastingService = TastingService()

    init(log: TastingLog, onComplete: @escaping () -> Void) {
        self.log = log
        self.onComplete = onComplete
        _date = State(initialValue: log.smokedAt)
        _notes = State(initialValue: log.personalNotes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Registrering") {
                    LabeledContent("Sigar", value: log.cigar?.displayName ?? "Ukjent sigar")
                    DatePicker("Dato", selection: $date, displayedComponents: .date)
                }

                Section("Notat") {
                    TextField("Egne notater…", text: $notes, axis: .vertical)
                        .lineLimit(4...8)
                }

                Section {
                    Button("Slett registrering", role: .destructive) {
                        showDeleteConfirm = true
                    }
                }
            }
            .navigationTitle("Registrering")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lagre") { save() }
                        .disabled(isSaving)
                }
            }
            .alert("Slett registrering?", isPresented: $showDeleteConfirm) {
                Button("Avbryt", role: .cancel) {}
                Button("Slett", role: .destructive) { deleteEntry() }
            }
            .alert("Kunne ikke lagre", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func save() {
        guard !isSaving else { return }
        isSaving = true

        Task {
            do {
                try await tastingService.updateLog(
                    id: log.id,
                    smokedAt: date,
                    rating: log.rating,
                    smokeAgain: log.smokeAgain,
                    drawRating: log.drawRating,
                    burnRating: log.burnRating,
                    flavorRating: log.flavorRating,
                    personalNotes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes,
                    photoUrl: log.photoUrl
                )
                dismiss()
                onComplete()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }

    private func deleteEntry() {
        Task {
            do {
                try await tastingService.deleteLog(id: log.id)
                dismiss()
                onComplete()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
