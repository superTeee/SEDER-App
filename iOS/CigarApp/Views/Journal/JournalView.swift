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
    @State private var showStats = false
    @State private var exportFile: ExportFile?
    @State private var showPaywall = false

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
                    ToolbarItem(placement: .topBarLeading) { ProfileAvatarButton() }
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
                PaywallView().environmentObject(proManager)
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
            Text("Ingen røykte sigarer ennå")
                .font(.title3.bold())
            Text("Gå til en sigar i humidoren\nog trykk «Har røkt den»")
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

    private var dateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "d. MMM"
        f.locale = Locale(identifier: "nb_NO")
        return f.string(from: log.smokedAt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Bilde (hvis finnes) ───────────────────────────
            if let photoUrl = log.photoUrl, let url = URL(string: photoUrl) {
                KFImage(url)
                    // Nedskaler under dekoding — store bilder (opptil ~2 MB) lastet
                    // tregt/upålitelig i full oppløsning inn i en liten rad.
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 1200, height: 712)))
                    .cacheOriginalImage()
                    .resizable()
                    .placeholder {
                        Rectangle().fill(Color(.secondarySystemBackground)).frame(height: 178)
                    }
                    .fade(duration: 0.15)
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 178)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .padding(.bottom, 8)
            }

            // ── Rad: info + score ─────────────────────────────
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(log.cigar?.brand ?? "Ukjent sigar")
                        .font(.headline)
                    if let series = log.cigar?.series {
                        Text(series)
                            .font(.subheadline)
                            .foregroundColor(Color("TextSecondary"))
                    }
                    if let vitola = log.cigar?.vitola {
                        Text(vitola)
                            .font(.caption)
                            .foregroundColor(Color("TextSecondary"))
                    }
                    // Kilde: fra humidoren vs. røkt direkte (uten å eie sigaren)
                    HStack(spacing: 4) {
                        Image(systemName: log.humidorEntryId != nil ? "archivebox.fill" : "flame.fill")
                            .font(.system(size: 9))
                        Text(log.humidorEntryId != nil ? "Fra humidor" : "Røkt direkte")
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundColor(Color("TextSecondary"))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color("Surface"))
                    .clipShape(Capsule())
                    .padding(.top, 2)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(dateLabel)
                        .font(.caption)
                        .foregroundColor(Color("TextSecondary"))
                    if let rating = log.rating, let label = log.scoreLabel {
                        Text("\(rating) · \(label)")
                            .font(.caption.weight(.medium))
                            .foregroundColor(scoreColor(for: rating))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(scoreColor(for: rating).opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.top, 4)

            if let notes = log.personalNotes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(Color("TextSecondary"))
                    .lineLimit(2)
                    .padding(.top, 4)
            }

            if let store = log.store, !store.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "bag")
                        .font(.system(size: 10))
                    Text(store)
                        .font(.caption)
                        .lineLimit(1)
                }
                .foregroundColor(Color("TextSecondary"))
                .padding(.top, 2)
            }

        }
        .padding(.vertical, 4)
    }

    private func scoreColor(for score: Int) -> Color {
        switch score {
        case 90...100: return Color(red: 0.85, green: 0.65, blue: 0.2)
        case 80...89:  return Color(red: 0.65, green: 0.5,  blue: 0.1)
        case 70...79:  return Color(.systemGray)
        default:       return Color(.systemBrown)
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
    @State private var showSubRatings = false
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

    private var scoreLabel: String {
        switch score {
        case 95...100: return "Eksepsjonell"
        case 90...94:  return "Fremragende"
        case 85...89:  return "Meget bra"
        case 80...84:  return "Bra"
        case 70...79:  return "Grei"
        default:       return "Ikke for meg"
        }
    }

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

                    // ── Sigar-header ──────────────────────────────────
                    if let cigar = log.cigar {
                        VStack(spacing: 4) {
                            Text(cigar.brand)
                                .font(.headline)
                            if let series = cigar.series {
                                Text(series)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            if let vitola = cigar.vitola {
                                Text(vitola)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 8)
                    }

                    // ── Dato ─────────────────────────────────────────
                    DatePicker("Dato", selection: $smokedAt, displayedComponents: .date)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)

                    Divider().padding(.horizontal, 20)

                    // ── Foto ──────────────────────────────────────────
                    VStack(spacing: 10) {
                        if let photoImage {
                            // Nytt valgt bilde
                            photoImage
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 180)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .padding(.horizontal, 20)
                        } else if let url = photoUrl.flatMap({ URL(string: $0) }) {
                            // Eksisterende bilde fra Supabase
                            KFImage(url)
                                .resizable()
                                .placeholder {
                                    Rectangle().fill(Color(.secondarySystemBackground)).frame(height: 180)
                                }
                                .fade(duration: 0.15)
                                .scaledToFill()
                                .frame(maxWidth: .infinity).frame(height: 180).clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .padding(.horizontal, 20)
                        }

                        PhotosPicker(selection: $photoItem, matching: .images) {
                            HStack(spacing: 6) {
                                Image(systemName: (photoImage != nil || photoUrl != nil)
                                      ? "arrow.triangle.2.circlepath" : "camera.fill")
                                Text((photoImage != nil || photoUrl != nil) ? "Bytt bilde" : "Legg til bilde")
                                    .font(.subheadline)
                            }
                            .foregroundColor(Color("Accent"))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .onChange(of: photoItem) { _, newItem in
                            Task {
                                guard let newItem,
                                      let data = try? await newItem.loadTransferable(type: Data.self),
                                      let uiImg = UIImage(data: data) else { return }
                                cropRequest = CropRequest(image: uiImg, ratio: 1.6)
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
                            .ignoresSafeArea()
                        }
                    }
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
                                Text(scoreLabel)
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
                        Text("Ville røkt igjen?")
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
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
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
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Rediger")
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
                    statCard(label: "Røkt totalt", value: "\(s.totalLogged)")
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
                    statSection("Mest røkte merker") {
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
