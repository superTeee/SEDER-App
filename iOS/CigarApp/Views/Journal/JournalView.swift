import SwiftUI
import PhotosUI
import Kingfisher
import Charts
import UIKit

// MARK: - JournalView
// Røykelogg — alle sigarer du har røkt, nyest først.
// Henter fra tasting_logs-tabellen (kobles til cigars via JOIN).

struct JournalView: View {

    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var proManager: ProManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var logs: [TastingLog] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showLoginSheet = false
    @State private var logToEdit: TastingLog? = nil
    @State private var logToView: TastingLog? = nil
    @State private var showStats = false
    @State private var exportFile: ExportFile?
    @State private var showPaywall = false
    @EnvironmentObject private var appShell: AppShell
    @State private var showLogChooser = false
    @State private var showSearchToLog = false
    @State private var showLogFromHumidor = false

    private func export(_ kind: ExportKind) {
        // Pro-funksjon — vis paywall for gratisbrukere.
        guard proManager.isPro else { showPaywall = true; return }
        let url: URL? = (kind == .pdf) ? JournalExporter.writePDF(logs) : JournalExporter.writeCSV(logs)
        if let url { exportFile = ExportFile(url: url) }
    }

    private let tastingService = TastingService()

    var body: some View {
        NavigationStack {
            journalList
                .overlay {
                    if authService.userId == nil {
                        journalLoggedOut
                            .background(Color("Background"))
                    } else if isLoading {
                        ProgressView("Laster journal...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color("Background"))
                    } else if logs.isEmpty {
                        journalEmpty
                            .background(Color("Background"))
                    }
                }
                .navigationTitle("Journal")
                .navigationBarTitleDisplayMode(.inline)   // liten sentrert tittel
                .toolbarBackground(Color("Background"), for: .navigationBar)
                .toolbarColorScheme(colorScheme, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { showLogChooser = true } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color("TextPrimary"))
                        }
                        .accessibilityLabel("Ny loggføring")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button { if proManager.isPro { showStats = true } else { showPaywall = true } } label: {
                                Label("Statistikk", systemImage: "chart.bar.xaxis")
                            }
                            Divider()
                            Button { export(.pdf) } label: {
                                Label("Eksporter som PDF", systemImage: "doc.richtext")
                            }
                            Button { export(.csv) } label: {
                                Label("Eksporter som CSV", systemImage: "tablecells")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            .onAppear { Task { await loadLogs() } }
            .refreshable { await loadLogs() }
            .sheet(isPresented: $showStats) {
                StatistikkView().environmentObject(authService)
            }
            .sheet(isPresented: $showPaywall) {
                SupportView(mode: .unlock,
                            unlockTitle: "Lås opp SEDER Pro",
                            unlockSubtitle: "Statistikk, eksport og ubegrensede humidorer – én betaling, for alltid.",
                            showQuota: false)
            }
            .sheet(item: $exportFile) { file in
                IOSShareSheet(items: [file.url])
            }
            .sheet(isPresented: $showLoginSheet) {
                AuthView(onSuccess: { Task { await loadLogs() } })
            }
            .sheet(item: $logToEdit) { log in
                EditLogSheet(log: log) {
                    Task { await loadLogs() }
                }
                .environmentObject(authService)
            }
            .sheet(isPresented: $showLogChooser) {
                NewLogChooserSheet(
                    onScan:    { appShell.pendingScan = .band },
                    onSearch:  { showSearchToLog = true },
                    onHumidor: { showLogFromHumidor = true }
                )
                .presentationDetents([.height(290)])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showLogFromHumidor) {
                LogFromHumidorSheet()
                    .environmentObject(authService)
            }
            .sheet(isPresented: $showSearchToLog) {
                LogCigarSearchSheet()
                    .environmentObject(authService)
            }
        }
    }

    // MARK: - Liste

    private var journalList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(groupedByMonth, id: \.0) { month, entries in
                    // Månedstittel
                    Text(month)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color("TextSecondary"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 10)

                    ForEach(Array(entries.enumerated()), id: \.element.id) { idx, log in
                        let isFirst = idx == 0
                        let isLast  = idx == entries.count - 1

                        HStack(alignment: .top, spacing: 0) {
                            // Tidslinje (venstre side)
                            VStack(spacing: 0) {
                                Color(.separator)
                                    .frame(width: 1.5)
                                    .frame(maxHeight: .infinity)
                                    .opacity(isFirst ? 0 : 1)

                                Circle()
                                    .fill(Color("Accent"))
                                    .frame(width: 10, height: 10)

                                Color(.separator)
                                    .frame(width: 1.5)
                                    .frame(maxHeight: .infinity)
                                    .opacity(isLast ? 0 : 1)
                            }
                            .frame(width: 24)

                            Spacer(minLength: 10)

                            // Kort (hvit bakgrunn)
                            VStack(spacing: 0) {
                                JournalRow(log: log)
                                    .padding(12)
                                    .padding(.trailing, 4)
                                    .background(Color("Card"))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .contentShape(Rectangle())
                                    .onTapGesture { logToEdit = log }

                                if !isLast { Color.clear.frame(height: 18) }
                            }
                        }
                        .padding(.leading, 12)
                        .padding(.trailing, 16)
                    }
                }
            }
            .padding(.bottom, 32)
        }
        .contentMargins(.bottom, 60, for: .scrollContent) // klarering for egen tab-bar
        .background(Color("Background"))
    }

    // Grupperer loggene etter måned (f.eks. "Juni 2026")
    private var groupedByMonth: [(String, [TastingLog])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "nb_NO")

        var result: [(String, [TastingLog])] = []
        var current: (String, [TastingLog])? = nil

        for log in logs {
            let label = formatter.string(from: log.smokedAt).capitalized
            if current?.0 == label {
                current?.1.append(log)
            } else {
                if let prev = current { result.append(prev) }
                current = (label, [log])
            }
        }
        if let last = current { result.append(last) }
        return result
    }

    // MARK: - Tilstander

    private var journalLoggedOut: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 48))
                .foregroundColor(Color("TextSecondary").opacity(0.4))
            Text("Logg inn for å se journalen din")
                .font(.title3.bold())
                .multilineTextAlignment(.center)
            Button("Logg inn") { showLoginSheet = true }
                .fontWeight(.semibold)
                .frame(maxWidth: 200)
                .padding()
                .background(Color("Accent"))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var journalEmpty: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(Color("TextSecondary").opacity(0.4))
            Text("Ingen oppføringer ennå")
                .font(.title3.bold())
            Text("Gå til en sigar og trykk «Loggfør sigar»")
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Data

    private func loadLogs() async {
        guard let userId = authService.userId else {
            isLoading = false
            return
        }
        isLoading = true
        do {
            logs = try await tastingService.fetchLogs(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func performDelete(log: TastingLog) async {
        do {
            try await tastingService.deleteLog(id: log.id)
            withAnimation { logs.removeAll { $0.id == log.id } }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Journal Row

struct JournalRow: View {

    let log: TastingLog
    private let tastingService = TastingService()
    @Environment(\.colorScheme) private var colorScheme

    private var dateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "d. MMM"
        f.locale = Locale(identifier: "nb_NO")
        return f.string(from: log.smokedAt)
    }

    private var titleText: String {
        log.cigar?.brand ?? "Ukjent sigar"
    }
    private var subtitleText: String? {
        let parts = [log.cigar?.series, log.cigar?.vitola].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    // Lite kvadratisk thumbnail til venstre i kortet.
    @ViewBuilder private var thumbnail: some View {
        if let photoUrl = log.photoUrl, let url = URL(string: photoUrl) {
            KFImage(url)
                .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 200, height: 200)))
                .cacheOriginalImage()
                .resizable()
                .placeholder { Rectangle().fill(Color(.secondarySystemBackground)) }
                .fade(duration: 0.15)
                .scaledToFill()
        } else {
            ZStack {
                Rectangle().fill(Color(.secondarySystemBackground))
                Image(systemName: "leaf")
                    .font(.system(size: 20))
                    .foregroundColor(Color("TextSecondary").opacity(0.45))
            }
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
                .frame(width: 62, height: 62)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(titleText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color("TextPrimary"))
                    .lineLimit(1)
                if let sub = subtitleText {
                    Text(sub)
                        .font(.system(size: 14))
                        .foregroundColor(Color("TextSecondary"))
                        .lineLimit(1)
                }
                Text(dateLabel)
                    .font(.system(size: 12))
                    .foregroundColor(Color("TextSecondary"))
            }

            Spacer(minLength: 8)

            if let rating = log.rating {
                ScoreBadge(text: "\(rating)")
            }
        }
    }
}

// MARK: - Edit Log Sheet
// Lar brukeren redigere en eksisterende røykelogg.
// Pre-fyller alle felter fra TastingLog, og har slett-knapp nederst.

struct EditLogSheet: View {

    let log: TastingLog
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService

    @State private var smokedAt: Date
    @State private var hasScore: Bool
    @State private var score: Int
    @State private var smokeAgain: Bool?
    @State private var drawRating: Int
    @State private var burnRating: Int
    @State private var flavorRating: Int
    @State private var notes: String
    @State private var showSubRatings = true
    @State private var isSaving = false
    @State private var showDeleteConfirm = false
    @State private var saveError: String?

    // Foto
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var photoImage: Image?
    @State private var photoUrl: String?
    @State private var cropRequest: CropRequest?

    private let tastingService = TastingService()

    init(log: TastingLog, onComplete: @escaping () -> Void) {
        self.log = log
        self.onComplete = onComplete
        _smokedAt     = State(initialValue: log.smokedAt)
        _hasScore     = State(initialValue: log.rating != nil)
        _score        = State(initialValue: max(50, log.rating ?? 85))
        _smokeAgain   = State(initialValue: log.smokeAgain)
        _drawRating   = State(initialValue: log.drawRating ?? 0)
        _burnRating   = State(initialValue: log.burnRating ?? 0)
        _flavorRating = State(initialValue: log.flavorRating ?? 0)
        _notes        = State(initialValue: log.personalNotes ?? "")
        _photoUrl     = State(initialValue: log.photoUrl)
    }

    // MARK: Hjelpere

    private var scoreColor: Color {
        switch score {
        case 90...100: return Color(red: 0.85, green: 0.65, blue: 0.2)
        case 80...89:  return Color(red: 0.75, green: 0.55, blue: 0.15)
        case 70...79:  return Color(red: 0.5,  green: 0.5,  blue: 0.5)
        default:       return Color(red: 0.55, green: 0.35, blue: 0.25)
        }
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {

                    // ── Header: stort kvadratisk bilde (trykk for å bytte) + sigarnavn ──
                    VStack(spacing: 12) {
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Color.clear
                                .aspectRatio(1, contentMode: .fit)
                                .overlay {
                                    if let photoImage {
                                        photoImage.resizable().scaledToFill()
                                    } else if let url = photoUrl.flatMap({ URL(string: $0) }) {
                                        KFImage(url)
                                            .resizable()
                                            .placeholder { Rectangle().fill(Color(.secondarySystemBackground)) }
                                            .fade(duration: 0.15)
                                            .scaledToFill()
                                    } else {
                                        Rectangle().fill(Color(.secondarySystemBackground))
                                            .overlay { UploadPhotoPlaceholder() }
                                    }
                                }
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(alignment: .topTrailing) {
                                    if photoImage != nil || photoUrl != nil { EditPhotoPill() }
                                }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(log.cigar?.displayName ?? "Ukjent sigar")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(Color("TextPrimary"))
                            if let v = log.cigar?.vitola, !v.isEmpty {
                                Text(v).font(.subheadline).foregroundColor(Color("TextSecondary"))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)

                        if photoImage != nil || photoUrl != nil {
                            Button {
                                photoImage = nil
                                photoData = nil
                                photoUrl = nil
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "trash")
                                    Text("Fjern bilde").font(.subheadline)
                                }
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .onChange(of: photoItem) { _, newItem in
                        Task {
                            guard let newItem,
                                  let data = try? await newItem.loadTransferable(type: Data.self),
                                  let uiImg = UIImage(data: data) else { return }
                            cropRequest = CropRequest(image: uiImg, ratio: 1.0)
                            photoItem = nil
                        }
                    }
                    .fullScreenCover(item: $cropRequest) { req in
                        ImageCropper(image: req.image, ratio: req.ratio) { cropped in
                            cropRequest = nil
                            photoData = cropped.jpegData(compressionQuality: 0.9)
                            photoImage = Image(uiImage: cropped)
                        } onCancel: {
                            cropRequest = nil
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                    Divider().padding(.horizontal, 20)

                    // ── Dato ─────────────────────────────────────────
                    DatePicker("Dato", selection: $smokedAt, displayedComponents: .date)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)

                    Divider().padding(.horizontal, 20)

                    // ── Score-seksjon ─────────────────────────────────
                    VStack(spacing: 16) {
                        Toggle("Gi score", isOn: $hasScore)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        if hasScore {
                            VStack(spacing: 4) {
                                Text("\(score)")
                                    .font(.system(size: 80, weight: .semibold, design: .rounded))
                                    .foregroundColor(scoreColor)
                                    .contentTransition(.numericText())
                                    .animation(.spring(duration: 0.2), value: score)
                                Text("Min vurdering")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Slider(
                                value: Binding(get: { Double(score) }, set: { score = Int($0) }),
                                in: 50...100, step: 1
                            )
                            .tint(Color("Accent"))
                            .padding(.horizontal, 24)

                            HStack(spacing: 10) {
                                ForEach([-5, -1], id: \.self) { delta in
                                    Button("\(delta)") {
                                        score = max(50, min(100, score + delta))
                                    }
                                    .buttonStyle(.bordered).tint(.secondary).font(.subheadline)
                                }
                                Spacer()
                                ForEach([1, 5], id: \.self) { delta in
                                    Button("+\(delta)") {
                                        score = max(50, min(100, score + delta))
                                    }
                                    .buttonStyle(.bordered).tint(Color("Accent")).font(.subheadline)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 8)

                    Divider().padding(.horizontal, 20)

                    // ── Smoke again ───────────────────────────────────
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Prøve igjen?")
                            .font(.subheadline).foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        HStack(spacing: 10) {
                            smokeAgainButton(label: "Ja",      icon: "checkmark.circle.fill", value: true)
                            smokeAgainButton(label: "Kanskje", icon: "minus.circle.fill",     value: nil)
                            smokeAgainButton(label: "Nei",     icon: "xmark.circle.fill",     value: false)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                    Divider().padding(.horizontal, 20)

                    // ── Sub-ratings ───────────────────────────────────
                    VStack(spacing: 12) {
                        Button { withAnimation { showSubRatings.toggle() } } label: {
                            HStack {
                                Text("Detaljer (valgfritt)")
                                    .font(.subheadline).foregroundColor(.secondary)
                                Spacer()
                                Image(systemName: showSubRatings ? "chevron.up" : "chevron.down")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 14)

                        if showSubRatings {
                            VStack(spacing: 14) {
                                dotRatingRow(label: "Trekk",    value: $drawRating)
                                dotRatingRow(label: "Brenning", value: $burnRating)
                                dotRatingRow(label: "Smak",     value: $flavorRating)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 4)
                        }
                    }

                    Divider().padding(.horizontal, 20).padding(.top, 12)

                    // ── Notater ───────────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kommentar")
                            .font(.subheadline).foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        TextField("Smaksnotat, anledning, pairing...", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(12)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color("Accent"), lineWidth: 1.2))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                    // ── Handlingsknapper ──────────────────────────────
                    VStack(spacing: 10) {
                        Button(action: save) {
                            HStack {
                                if isSaving {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Lagre endringer").fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color("Accent"))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .disabled(isSaving)

                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Text("Slett oppføring")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                        .padding(.top, 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Loggføring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
            }
            .alert("Slett oppføring", isPresented: $showDeleteConfirm) {
                Button("Slett", role: .destructive) { deleteEntry() }
                Button("Avbryt", role: .cancel) {}
            } message: {
                Text("Dette kan ikke angres.")
            }
            .alert("Feil", isPresented: .constant(saveError != nil)) {
                Button("OK") { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
        }
    }

    // MARK: - Handlinger

    private func save() {
        guard !isSaving else { return }
        isSaving = true
        Task {
            do {
                var finalPhotoUrl = photoUrl
                if let data = photoData, let userId = authService.userId {
                    finalPhotoUrl = try await tastingService.uploadLogPhoto(
                        logId: log.id,
                        userId: userId,
                        imageData: data
                    )
                }

                try await tastingService.updateLog(
                    id:            log.id,
                    smokedAt:      smokedAt,
                    rating:        hasScore ? score : nil,
                    smokeAgain:    smokeAgain,
                    drawRating:    drawRating > 0 ? drawRating : nil,
                    burnRating:    burnRating > 0 ? burnRating : nil,
                    flavorRating:  flavorRating > 0 ? flavorRating : nil,
                    personalNotes: notes.isEmpty ? nil : notes,
                    photoUrl:      finalPhotoUrl
                )

                dismiss()
                onComplete()
            } catch {
                // Vis full feildetalj for debugging
                saveError = String(describing: error)
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
                saveError = error.localizedDescription
            }
        }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private func smokeAgainButton(label: String, icon: String, value: Bool?) -> some View {
        let isSelected: Bool = {
            switch (smokeAgain, value) {
            case (.none, .none): return true
            case (.some(let a), .some(let b)): return a == b
            default: return false
            }
        }()

        Button { smokeAgain = value } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(label).font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
            .foregroundColor(isSelected ? Color.accentColor : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func dotRatingRow(label: String, value: Binding<Int>) -> some View {
        HStack {
            Text(label).font(.subheadline).frame(width: 80, alignment: .leading)
            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { dot in
                    Circle()
                        .fill(dot <= value.wrappedValue ? Color("Accent") : Color(.tertiarySystemBackground))
                        .frame(width: 26, height: 26)
                        .overlay(Circle().stroke(
                            dot <= value.wrappedValue ? Color("Accent") : Color(.systemGray4), lineWidth: 1.5
                        ))
                        .onTapGesture {
                            value.wrappedValue = (value.wrappedValue == dot) ? 0 : dot
                        }
                }
            }
            Spacer()
        }
    }
}

// MARK: - StatistikkView (avansert statistikk / innsikt)

struct StatistikkView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    private let profileService = ProfileService()

    @State private var stats: UserStats?
    @State private var loading = true

    var body: some View {
        NavigationStack {
            Group {
                if loading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let s = stats, s.totalLogged > 0 {
                    content(s)
                } else {
                    emptyState
                }
            }
            .background(Color("Background"))
            .navigationTitle("Statistikk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Ferdig") { dismiss() } } }
        }
        .task { await load() }
    }

    private func load() async {
        loading = true
        stats = try? await profileService.fetchUserStats()
        loading = false
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 42)).foregroundColor(Color("TextSecondary").opacity(0.5))
            Text("Ingen data ennå").font(.headline).foregroundColor(Color("TextPrimary"))
            Text("Loggfør noen sigarer, så dukker innsikten opp her.")
                .font(.subheadline).foregroundColor(Color("TextSecondary")).multilineTextAlignment(.center)
        }.padding(40)
    }

    @ViewBuilder
    private func content(_ s: UserStats) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    statCard(label: "Registrert totalt", value: "\(s.totalLogged)")
                    statCard(label: "Merker prøvd", value: "\(s.brandsTried)")
                    statCard(label: "Snittscore", value: s.avgScore.map { "\($0)" } ?? "–")
                    statCard(label: "Humidor-verdi", value: "\(kr(s.humidorValue)) kr")
                }

                if s.scoreSeries.count >= 2 {
                    statSection("Score over tid") {
                        Chart(s.scoreSeries) { p in
                            LineMark(x: .value("Tid", p.d), y: .value("Score", p.s))
                                .foregroundStyle(Color("Accent")).interpolationMethod(.catmullRom)
                            PointMark(x: .value("Tid", p.d), y: .value("Score", p.s))
                                .foregroundStyle(Color("Accent")).symbolSize(22)
                        }
                        .chartYScale(domain: 40...100)
                        .frame(height: 190)
                    }
                }

                if let st = s.strengthAvg {
                    statSection("Snitt-styrke") {
                        HStack(spacing: 9) {
                            ForEach(1...5, id: \.self) { i in
                                Capsule().fill(Double(i) <= st ? Color("Accent") : Color("Surface"))
                                    .frame(height: 8).frame(maxWidth: .infinity)
                            }
                        }
                        Text(strengthText(st)).font(.caption).foregroundColor(Color("TextSecondary")).padding(.top, 6)
                    }
                }

                if !s.topBrands.isEmpty {
                    statSection("Mest registrerte merker") {
                        let maxN = s.topBrands.map(\.n).max() ?? 1
                        VStack(spacing: 10) {
                            ForEach(s.topBrands) { b in
                                HStack(spacing: 10) {
                                    Text(b.brand).font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color("TextPrimary")).frame(width: 110, alignment: .leading).lineLimit(1)
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule().fill(Color("Accent").opacity(0.12)).frame(height: 18)
                                            Capsule().fill(Color("Accent"))
                                                .frame(width: max(12, geo.size.width * CGFloat(b.n) / CGFloat(maxN)), height: 18)
                                        }
                                    }.frame(height: 18)
                                    Text("\(b.n)").font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(Color("TextSecondary")).frame(width: 26, alignment: .trailing)
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private func statCard(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased()).font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color("TextSecondary")).tracking(0.5)
            Text(value).font(.system(size: 22, weight: .bold)).foregroundColor(Color("TextPrimary"))
                .lineLimit(1).minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16).background(Color("Card")).clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func statSection<C: View>(_ title: String, @ViewBuilder _ inner: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased()).font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color("TextSecondary")).tracking(0.6)
            VStack(alignment: .leading, spacing: 0) { inner() }
                .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                .background(Color("Card")).clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func kr(_ v: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal; f.maximumFractionDigits = 0; f.groupingSeparator = " "
        return f.string(from: NSNumber(value: v)) ?? "\(Int(v))"
    }
    private func strengthText(_ v: Double) -> String {
        switch v { case ..<2: return "Mild"; case ..<3: return "Medium"; case ..<4: return "Fyldig"; default: return "Sterk" }
    }
}

// MARK: - Journal-eksport (PDF / CSV)

enum ExportKind { case pdf, csv }
struct ExportFile: Identifiable { let id = UUID(); let url: URL }

enum JournalExporter {

    private static func dateStr(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "nb_NO")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: d)
    }

    private static func write(_ data: Data?, name: String) -> URL? {
        guard let data else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do { try data.write(to: url); return url } catch { return nil }
    }

    // CSV — UTF-8 med BOM (så Excel viser æøå riktig).
    static func writeCSV(_ logs: [TastingLog]) -> URL? {
        func esc(_ s: String?) -> String {
            "\"" + (s ?? "").replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        var rows = ["Dato,Merke,Serie,Vitola,Score,Røyk igjen,Trekk,Brenning,Smak,Kutt,Kjøpt hos,Notat"]
        for l in logs.sorted(by: { $0.smokedAt > $1.smokedAt }) {
            let c = l.cigar
            let cols: [String] = [
                dateStr(l.smokedAt), c?.brand, c?.series, c?.vitola,
                l.rating.map { "\($0)" }, l.smokeAgain.map { $0 ? "Ja" : "Nei" },
                l.drawRating.map { "\($0)" }, l.burnRating.map { "\($0)" }, l.flavorRating.map { "\($0)" },
                l.cutType?.displayName, l.store, l.personalNotes
            ].map(esc)
            rows.append(cols.joined(separator: ","))
        }
        let csv = "\u{FEFF}" + rows.joined(separator: "\n")
        return write(csv.data(using: .utf8), name: "seder-journal.csv")
    }

    // PDF — enkel, lesbar liste (A4).
    static func writePDF(_ logs: [TastingLog]) -> URL? {
        let pageW: CGFloat = 595, pageH: CGFloat = 842, margin: CGFloat = 40
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageW, height: pageH))
        let sorted = logs.sorted(by: { $0.smokedAt > $1.smokedAt })

        let data = renderer.pdfData { ctx in
            var y: CGFloat = margin

            func header() {
                "SEDER — Journal".draw(at: CGPoint(x: margin, y: y),
                    withAttributes: [.font: UIFont.boldSystemFont(ofSize: 20)])
                y += 28
                "\(sorted.count) registreringer · eksportert \(dateStr(Date()))"
                    .draw(at: CGPoint(x: margin, y: y),
                          withAttributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.gray])
                y += 26
            }
            func newPage() { ctx.beginPage(); y = margin; header() }

            newPage()
            for l in sorted {
                if y > pageH - margin - 60 { newPage() }
                let c = l.cigar
                let name = [c?.brand, c?.series, c?.vitola].compactMap { $0 }.joined(separator: " ")
                (name.isEmpty ? "Ukjent sigar" : name).draw(at: CGPoint(x: margin, y: y),
                    withAttributes: [.font: UIFont.boldSystemFont(ofSize: 13)])
                y += 18

                var meta = dateStr(l.smokedAt)
                if let r = l.rating { meta += " · \(r)/100" }
                if let s = l.store, !s.isEmpty { meta += " · \(s)" }
                meta.draw(at: CGPoint(x: margin, y: y),
                          withAttributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.darkGray])
                y += 16

                if let note = l.personalNotes, !note.isEmpty {
                    let ns = note as NSString
                    let w = pageW - margin * 2
                    let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.black]
                    let h = ns.boundingRect(with: CGSize(width: w, height: 400),
                        options: [.usesLineFragmentOrigin], attributes: attrs, context: nil).height
                    ns.draw(with: CGRect(x: margin, y: y, width: w, height: h),
                            options: [.usesLineFragmentOrigin], attributes: attrs, context: nil)
                    y += h + 6
                }

                ctx.cgContext.setStrokeColor(UIColor.systemGray4.cgColor)
                ctx.cgContext.setLineWidth(0.5)
                ctx.cgContext.move(to: CGPoint(x: margin, y: y))
                ctx.cgContext.addLine(to: CGPoint(x: pageW - margin, y: y))
                ctx.cgContext.strokePath()
                y += 12
            }
        }
        return write(data, name: "seder-journal.pdf")
    }
}

// MARK: - NewLogChooserSheet
// Valg-ark for journalens «+»: skann båndet, eller søk opp sigaren. Begge ender
// i loggføring. Samme visuelle stil som ScanSheet.
private struct NewLogChooserSheet: View {
    var onScan: () -> Void = {}
    var onSearch: () -> Void = {}
    var onHumidor: () -> Void = {}
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var sheetBackground: Color { colorScheme == .light ? .white : Color("Card") }

    var body: some View {
        VStack(spacing: 0) {
            Text("Ny loggføring")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color("TextPrimary"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 12)

            VStack(spacing: 0) {
                row(icon: "camera.viewfinder", title: "Skann sigarbånd",
                    subtitle: "Identifiser sigaren via båndet", action: onScan)
                Rectangle().fill(Color("TextSecondary").opacity(0.12)).frame(height: 0.5).padding(.leading, 72)
                row(icon: "magnifyingglass", title: "Søk etter sigar",
                    subtitle: "Finn sigaren i katalogen", action: onSearch)
                Rectangle().fill(Color("TextSecondary").opacity(0.12)).frame(height: 0.5).padding(.leading, 72)
                row(icon: "archivebox", title: "Fra humidoren min",
                    subtitle: "Loggfør en du allerede eier", action: onHumidor)
            }
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(sheetBackground.ignoresSafeArea())
    }

    private func row(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { action() }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11).fill(Color("Accent").opacity(0.14)).frame(width: 44, height: 44)
                    Image(systemName: icon).font(.system(size: 24, weight: .medium)).foregroundColor(Color("Accent"))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 17, weight: .semibold)).foregroundColor(Color("TextPrimary"))
                    Text(subtitle).font(.system(size: 14)).foregroundColor(Color("TextSecondary"))
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundColor(Color("TextSecondary").opacity(0.5))
            }
            .padding(.horizontal, 20).padding(.vertical, 12).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - LogCigarSearchSheet
// Søk opp en sigar i katalogen og loggfør den direkte. Ender i SmokingLogSheet;
// ved lagring sendes .didLogTasting som bytter til Journal-fanen.
private struct LogCigarSearchSheet: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var results: [Cigar] = []
    @State private var isSearching = false
    @State private var selectedCigar: Cigar?

    private let cigarService = CigarService()
    private let humidorService = HumidorService()
    private let tastingService = TastingService()

    var body: some View {
        NavigationStack {
            List {
                if isSearching {
                    HStack { Spacer(); ProgressView(); Spacer() }
                } else if !query.trimmingCharacters(in: .whitespaces).isEmpty && results.isEmpty {
                    Text("Ingen treff på «\(query)»")
                        .foregroundColor(Color("TextSecondary"))
                } else {
                    ForEach(results, id: \.id) { cigar in
                        Button { selectedCigar = cigar } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(title(cigar))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color("TextPrimary"))
                                if let sub = subtitle(cigar) {
                                    Text(sub)
                                        .font(.system(size: 13))
                                        .foregroundColor(Color("TextSecondary"))
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Søk etter sigar")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Merke, serie eller størrelse")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Avbryt") { dismiss() } } }
            .task(id: query) { await runSearch() }
            .sheet(item: $selectedCigar) { cigar in
                SmokingLogSheet(cigar: cigar, userId: authService.userId) { smokedAt, rating, smokeAgain, draw, burn, flavor, notes, photoData, cutType, store in
                    guard let uid = authService.userId else { return }
                    Task {
                        do {
                            let logId = try await humidorService.logTastingForCigar(
                                cigarId: cigar.id, userId: uid, smokedAt: smokedAt, rating: rating,
                                smokeAgain: smokeAgain, drawRating: draw, burnRating: burn,
                                flavorRating: flavor, notes: notes, cutType: cutType, store: store)
                            if let data = photoData {
                                let url = try await tastingService.uploadLogPhoto(logId: logId, userId: uid, imageData: data)
                                try await tastingService.updateLog(
                                    id: logId, smokedAt: smokedAt, rating: rating, smokeAgain: smokeAgain,
                                    drawRating: draw, burnRating: burn, flavorRating: flavor,
                                    personalNotes: notes, photoUrl: url)
                            }
                            await MainActor.run {
                                NotificationCenter.default.post(name: .didLogTasting, object: nil)
                                dismiss()   // lukk søke-arket → Journal-fanen vises
                            }
                        } catch { print("Logg fra søk feilet: \(error)") }
                    }
                }
                .environmentObject(authService)
            }
        }
    }

    private func runSearch() async {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard q.count >= 2 else { results = []; return }
        isSearching = true
        defer { isSearching = false }
        do { results = try await cigarService.searchCigars(query: q) }
        catch { results = [] }
    }

    private func title(_ c: Cigar) -> String {
        var t = c.brand
        if let s = c.series, !s.isEmpty { t += " " + s }
        return t
    }
    private func subtitle(_ c: Cigar) -> String? {
        guard let v = c.vitola, !v.isEmpty else { return nil }
        return v
    }
}

// MARK: - LogFromHumidorSheet
// Velg en sigar du allerede har i humidoren og loggfør den. Bruker
// logSmokingSession (reduserer antallet i humidoren), og sender .didLogTasting
// som bytter til Journal-fanen.
private struct LogFromHumidorSheet: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var entries: [HumidorEntry] = []
    @State private var humidors: [Humidor] = []
    @State private var isLoading = true
    @State private var selectedEntry: HumidorEntry?

    private let humidorService = HumidorService()
    private let tastingService = TastingService()

    private var loggable: [HumidorEntry] {
        entries.filter { $0.quantity > 0 && $0.cigar != nil }
    }

    // Grupperer de loggbare sigarene per humidor (rekkefølge følger humidor-lista).
    private var groupedByHumidor: [(name: String, entries: [HumidorEntry])] {
        let grouped = Dictionary(grouping: loggable) { $0.humidorId }
        var result: [(String, [HumidorEntry])] = []
        for h in humidors {
            if let items = grouped[h.id], !items.isEmpty { result.append((h.name, items)) }
        }
        let known = Set(humidors.map { $0.id })
        let orphans = loggable.filter { $0.humidorId == nil || !known.contains($0.humidorId!) }
        if !orphans.isEmpty { result.append(("Uten humidor", orphans)) }
        return result
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if loggable.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 40))
                            .foregroundColor(Color("TextSecondary").opacity(0.5))
                        Text("Humidoren er tom")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color("TextPrimary"))
                        Text("Legg sigarer i humidoren for å kunne loggføre dem herfra.")
                            .font(.system(size: 14))
                            .foregroundColor(Color("TextSecondary"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(groupedByHumidor, id: \.name) { group in
                            Section(group.name) {
                                ForEach(group.entries) { entry in
                                    Button { selectedEntry = entry } label: {
                                        HStack(spacing: 12) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(title(entry.cigar))
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(Color("TextPrimary"))
                                                if let sub = subtitle(entry.cigar) {
                                                    Text(sub)
                                                        .font(.system(size: 13))
                                                        .foregroundColor(Color("TextSecondary"))
                                                }
                                            }
                                            Spacer()
                                            Text("×\(entry.quantity)")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(Color("TextSecondary"))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Fra humidoren min")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Avbryt") { dismiss() } } }
            .task { await load() }
            .sheet(item: $selectedEntry) { entry in
                if let cigar = entry.cigar {
                    SmokingLogSheet(cigar: cigar, userId: authService.userId) { smokedAt, rating, smokeAgain, draw, burn, flavor, notes, photoData, cutType, store in
                        guard let uid = authService.userId else { return }
                        Task {
                            do {
                                let logId = try await humidorService.logSmokingSession(
                                    humidorEntry: entry, userId: uid, smokedAt: smokedAt, rating: rating,
                                    smokeAgain: smokeAgain, drawRating: draw, burnRating: burn,
                                    flavorRating: flavor, notes: notes, cutType: cutType, store: store)
                                if let data = photoData {
                                    let url = try await tastingService.uploadLogPhoto(logId: logId, userId: uid, imageData: data)
                                    try await tastingService.updateLog(
                                        id: logId, smokedAt: smokedAt, rating: rating, smokeAgain: smokeAgain,
                                        drawRating: draw, burnRating: burn, flavorRating: flavor,
                                        personalNotes: notes, photoUrl: url)
                                }
                                await MainActor.run {
                                    NotificationCenter.default.post(name: .didLogTasting, object: nil)
                                    dismiss()   // lukk humidor-arket → Journal-fanen vises
                                }
                            } catch { print("Logg fra humidor feilet: \(error)") }
                        }
                    }
                    .environmentObject(authService)
                }
            }
        }
    }

    private func load() async {
        guard let uid = authService.userId else { isLoading = false; return }
        isLoading = true
        defer { isLoading = false }
        do {
            async let e = humidorService.fetchHumidor(userId: uid)
            async let h = humidorService.fetchHumidors(userId: uid)
            entries = try await e
            humidors = try await h
        } catch { entries = []; humidors = [] }
    }

    private func title(_ c: Cigar?) -> String {
        guard let c else { return "Ukjent sigar" }
        var t = c.brand
        if let s = c.series, !s.isEmpty { t += " " + s }
        return t
    }
    private func subtitle(_ c: Cigar?) -> String? {
        guard let v = c?.vitola, !v.isEmpty else { return nil }
        return v
    }
}

// MARK: - JournalLogDetailSheet
// Detaljvisning av én loggføring i et ark. «Rediger» åpner EditLogSheet.
struct JournalLogDetailSheet: View {
    let log: TastingLog
    var onChanged: () -> Void = {}

    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false

    private var dateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "d. MMMM yyyy"
        f.locale = Locale(identifier: "nb_NO")
        return f.string(from: log.smokedAt)
    }
    private var cigarTitle: String {
        var words: [String] = []
        if let b = log.cigar?.brand, !b.isEmpty { words += b.split(separator: " ").map(String.init) }
        if let s = log.cigar?.series, !s.isEmpty { words += s.split(separator: " ").map(String.init) }
        guard !words.isEmpty else { return "Ukjent sigar" }
        // Slå sammen gjentatte ord ved siden av hverandre, f.eks.
        // «Arturo Fuente Fuente Fuente OpusX» → «Arturo Fuente OpusX».
        var out: [String] = []
        for w in words where out.last?.lowercased() != w.lowercased() { out.append(w) }
        return out.joined(separator: " ")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let photoUrl = log.photoUrl, let url = URL(string: photoUrl) {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                KFImage(url)
                                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 1200, height: 1200)))
                                    .cacheOriginalImage()
                                    .resizable()
                                    .placeholder { Rectangle().fill(Color(.secondarySystemBackground)) }
                                    .fade(duration: 0.15)
                                    .scaledToFill()
                            }
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(cigarTitle)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color("TextPrimary"))
                        if let v = log.cigar?.vitola, !v.isEmpty {
                            Text(v).font(.subheadline).foregroundColor(Color("TextSecondary"))
                        }
                        Label(dateLabel, systemImage: "calendar")
                            .font(.subheadline).foregroundColor(Color("TextSecondary"))
                    }

                    VStack(spacing: 10) {
                        if let rating = log.rating { infoRow("Vurdering", "\(rating) / 100") }
                        if let again = log.smokeAgain { infoRow("Røyke igjen?", again ? "Ja" : "Nei") }
                        if let d = log.drawRating { subRatingRow("Trekk", d) }
                        if let b = log.burnRating { subRatingRow("Brenning", b) }
                        if let fl = log.flavorRating { subRatingRow("Smak", fl) }
                        if let store = log.store, !store.isEmpty { infoRow("Kjøpt hos", store) }
                    }

                    if let notes = log.personalNotes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notater")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color("TextSecondary"))
                            Text(notes)
                                .font(.body)
                                .foregroundColor(Color("TextPrimary"))
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color("Background"))
            .navigationTitle("Loggføring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Lukk") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Button("Rediger") { showEdit = true }.fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showEdit) {
                EditLogSheet(log: log) {
                    onChanged()
                    dismiss()
                }
                .environmentObject(authService)
            }
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundColor(Color("TextSecondary"))
            Spacer()
            Text(value).font(.system(size: 15, weight: .semibold)).foregroundColor(Color("TextPrimary"))
        }
    }
    private func subRatingRow(_ label: String, _ value: Int) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundColor(Color("TextSecondary"))
            Spacer()
            HStack(spacing: 3) {
                ForEach(1...5, id: \.self) { i in
                    Image(systemName: i <= value ? "circle.fill" : "circle")
                        .font(.system(size: 8))
                        .foregroundColor(i <= value ? Color("Accent") : Color("TextSecondary").opacity(0.3))
                }
            }
        }
    }
}
