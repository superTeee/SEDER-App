import SwiftUI
import PhotosUI

// MARK: - UserProfileView
// Rik profilside — gjenbrukbar for egen profil og venn sin profil.
// isOwnProfile = true  → vises fra Profil-fanen (ingen back-knapp i nav)
// isOwnProfile = false → pushes fra VennerView for å se en venns profil

struct UserProfileView: View {

    let userId: UUID
    var isOwnProfile: Bool = false

    @EnvironmentObject var authService: AuthService

    @State private var profile: FriendProfile?
    @State private var publicHumidors: [HumidorEntry] = []
    @State private var favorites: ProfileFavorites?
    @State private var lastLog: TastingLog? = nil
    @State private var isLoading = true
    @State private var showSettings = false
    @State private var showBadgeSheet = false
    @State private var showBioEditor = false

    // Profilbilde
    @State private var avatarItem: PhotosPickerItem?
    @State private var isUploadingAvatar = false
    @State private var localAvatarURL: String?

    // Toppbilde (cover)
    @State private var coverItem: PhotosPickerItem?
    @State private var isUploadingCover = false
    @State private var localCoverURL: String?

    @State private var uploadErrorMessage: String?

    private let profileService = ProfileService()

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
            } else if let p = profile {
                VStack(spacing: 0) {
                    heroSection(p)
                    statsRow(p)
                    lastSmokedSection
                    if isOwnProfile {
                        smaksprofilSection
                    }
                    if !isOwnProfile && !publicHumidors.isEmpty {
                        publicHumidorSection
                    }
                    Spacer(minLength: 32)
                }
            }
        }
        .background(Color("Background"))
        .navigationTitle(isOwnProfile ? "Profil" : (profile?.displayName ?? "Profil"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isOwnProfile {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(Color("TextPrimary"))
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings, onDismiss: {
            Task { await load() }
        }) {
            ProfileSettingsView()
        }
        .sheet(isPresented: $showBadgeSheet) {
            BadgeLevelSheet(createdAt: profile?.createdAt)
        }
        .sheet(isPresented: $showBioEditor) {
            BioEditorSheet(currentBio: profile?.bio ?? "") { newBio in
                guard let uid = authService.userId else { return }
                Task {
                    try? await profileService.saveBio(userId: uid, bio: newBio)
                    profile = try? await profileService.fetchFriendProfile(userId: userId)
                }
            }
        }
        .onChange(of: avatarItem) { _, newItem in
            guard let newItem, let uid = authService.userId else { return }
            Task {
                isUploadingAvatar = true
                defer { isUploadingAvatar = false }
                do {
                    guard let rawData = try? await newItem.loadTransferable(type: Data.self),
                          let uiImage = UIImage(data: rawData),
                          let jpegData = uiImage.jpegData(compressionQuality: 0.85) else { return }
                    let url = try await profileService.uploadAvatar(userId: uid, imageData: jpegData)
                    localAvatarURL = url
                } catch {
                    uploadErrorMessage = "Kunne ikke laste opp bilde: \(error.localizedDescription)"
                }
                avatarItem = nil
            }
        }
        .onChange(of: coverItem) { _, newItem in
            guard let newItem, let uid = authService.userId else { return }
            Task {
                isUploadingCover = true
                defer { isUploadingCover = false }
                do {
                    guard let rawData = try? await newItem.loadTransferable(type: Data.self),
                          let uiImage = UIImage(data: rawData),
                          let jpegData = uiImage.jpegData(compressionQuality: 0.85) else { return }
                    let url = try await profileService.uploadCover(userId: uid, imageData: jpegData)
                    localCoverURL = url
                } catch {
                    uploadErrorMessage = "Kunne ikke laste opp toppbilde: \(error.localizedDescription)"
                }
                coverItem = nil
            }
        }
        .task { await load() }
        .alert("Opplasting feilet", isPresented: .constant(uploadErrorMessage != nil)) {
            Button("OK") { uploadErrorMessage = nil }
        } message: {
            Text(uploadErrorMessage ?? "")
        }
    }

    // MARK: - Hero

    private func heroSection(_ p: FriendProfile) -> some View {
        let displayAvatarURL = localAvatarURL ?? p.avatarUrl
        let displayCoverURL  = localCoverURL  ?? p.coverUrl
        let badge = BadgeLevel.level(for: p.createdAt)

        return VStack(spacing: 0) {

            // Toppbilde (cover)
            ZStack(alignment: .topTrailing) {
                Group {
                    if let url = displayCoverURL.flatMap(URL.init) {
                        AsyncImage(url: url) { img in
                            img.resizable().scaledToFill()
                        } placeholder: {
                            Color("Accent").opacity(0.22)
                        }
                    } else {
                        Color("Accent").opacity(0.22)
                    }
                }
                .frame(height: 140)
                .frame(maxWidth: .infinity)
                .clipped()

                if isOwnProfile {
                    PhotosPicker(selection: $coverItem, matching: .images) {
                        HStack(spacing: 5) {
                            if isUploadingCover {
                                ProgressView().tint(.white).scaleEffect(0.7)
                            } else {
                                Image(systemName: "camera.fill").font(.system(size: 11))
                            }
                            Text("Endre").font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color.black.opacity(0.4))
                        .clipShape(Capsule())
                        .padding(10)
                    }
                }
            }

            // Horisontal info-seksjon
            HStack(alignment: .top, spacing: 16) {

                // --- Avatar (venstre) ---
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let url = displayAvatarURL.flatMap(URL.init) {
                            AsyncImage(url: url) { img in
                                img.resizable().scaledToFill()
                            } placeholder: {
                                initialsCircle(name: p.displayName, size: 80)
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                        } else {
                            initialsCircle(name: p.displayName, size: 80)
                        }
                    }
                    .overlay(Circle().stroke(Color("Accent"), lineWidth: 2))
                    .shadow(color: .black.opacity(0.25), radius: 5, x: 0, y: 2)

                    if isOwnProfile {
                        if isUploadingAvatar {
                            ProgressView()
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(Color("Accent")))
                        } else {
                            PhotosPicker(selection: $avatarItem, matching: .images) {
                                ZStack {
                                    Circle().fill(Color("Accent")).frame(width: 24, height: 24)
                                        .overlay(Circle().stroke(Color("Background"), lineWidth: 2))
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                }

                // --- Info (høyre) ---
                VStack(alignment: .leading, spacing: 4) {

                    // Navn
                    Text(bigName(for: p))
                        .font(.title2.weight(.bold))
                        .foregroundColor(hasRealName(p) ? Color("TextPrimary") : Color("TextSecondary"))

                    // Badge-nivå (amber tekst, trykk for nivå-ark)
                    Button { showBadgeSheet = true } label: {
                        Text(badge.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color("Accent"))
                    }
                    .buttonStyle(.plain)

                    // Bio
                    if let bio = p.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.system(size: 14))
                            .foregroundColor(Color("TextPrimary").opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 3)
                            .onTapGesture { if isOwnProfile { showBioEditor = true } }
                    } else if isOwnProfile {
                        Button { showBioEditor = true } label: {
                            Text("Legg til bio...")
                                .font(.system(size: 14))
                                .foregroundColor(Color("TextSecondary").opacity(0.55))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 3)
                    }

                    // Medlem siden + by + land
                    HStack(spacing: 6) {
                        if let created = p.createdAt {
                            Label(
                                "Siden \(created.formatted(.dateTime.year()))",
                                systemImage: "calendar"
                            )
                        }
                        if let city = p.city, !city.isEmpty {
                            Text("·")
                            if let country = p.country, !country.isEmpty {
                                Label("\(city), \(country)", systemImage: "mappin")
                            } else {
                                Label(city, systemImage: "mappin")
                            }
                        } else if let country = p.country, !country.isEmpty {
                            Text("·")
                            Label(country, systemImage: "mappin")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(Color("TextSecondary"))
                    .padding(.top, 5)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Color("Background"))
    }

    // MARK: - Stats (4 celler med ikoner)

    private func statsRow(_ p: FriendProfile) -> some View {
        HStack(spacing: 0) {

            // I humidor → HumidorView
            if isOwnProfile {
                NavigationLink {
                    HumidorView().environmentObject(authService)
                } label: {
                    statCell(icon: "archivebox", value: p.humidorCount, label: "I humidor")
                }
                .buttonStyle(.plain)
            } else {
                statCell(icon: "archivebox", value: p.humidorCount, label: "I humidor")
            }

            statDivider()

            // Røkt → JournalView
            if isOwnProfile {
                NavigationLink {
                    JournalView().environmentObject(authService)
                } label: {
                    statCell(icon: "smoke", value: p.cigarCount, label: "Røkt")
                }
                .buttonStyle(.plain)
            } else {
                statCell(icon: "smoke", value: p.cigarCount, label: "Røkt")
            }

            statDivider()

            // Merker prøvd
            statCell(icon: "globe", value: p.brandsTried, label: "Merker prøvd")

            statDivider()

            // Venner → VennerView (kun navigasjon på egen profil)
            if isOwnProfile {
                NavigationLink {
                    VennerView().environmentObject(authService)
                } label: {
                    statCell(icon: "person.2.fill", value: p.friendCount, label: "Venner")
                }
                .buttonStyle(.plain)
            } else {
                statCell(icon: "person.2.fill", value: p.friendCount, label: "Venner")
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color("Card"))
    }

    private func statDivider() -> some View {
        Divider().frame(height: 48)
    }

    private func statCell(icon: String, value: Int, label: String, showDash: Bool = false) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 19))
                .foregroundColor(Color("Accent"))
            Text(showDash ? "–" : "\(value)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color("TextPrimary"))
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(Color("TextSecondary"))
                .textCase(.uppercase)
                .tracking(0.3)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 2)
    }

    // MARK: - Smaksprofil

    private var smaksprofilSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Smaksprofil".uppercased())
                .font(.caption.weight(.semibold))
                .foregroundColor(Color("TextSecondary"))
                .tracking(0.5)
                .frame(maxWidth: .infinity, alignment: .leading)

            heroFavoriteCard

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                spacing: 10
            ) {
                favoriteCard(icon: "tag",          label: "Merke",      value: favorites?.favoriteBrand)
                favoriteCard(icon: "ruler",        label: "Vitola",     value: favorites?.favoriteVitola)
                favoriteCard(icon: "globe",        label: "Land",       value: favorites?.favoriteCountry)
                favoriteCard(icon: "leaf",         label: "Dekkblad",   value: favorites?.favoriteWrapper)
                favoriteCard(icon: "leaf.fill",    label: "Omblad",     value: favorites?.favoriteBinder)
                favoriteCard(icon: "square.stack", label: "Innlegg",    value: favorites?.favoriteFiller)
                favoriteCard(icon: "flame",        label: "Styrke",     value: strengthLabel(favorites?.favoriteStrength))
                favoriteCard(icon: "nose",         label: "Smaksnoter", value: favorites?.favoriteFlavor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 22)
    }

    private var heroFavoriteCard: some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color("Accent").opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: "rosette")
                    .font(.system(size: 20))
                    .foregroundColor(Color("Accent"))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Favorittsigar")
                    .font(.caption)
                    .foregroundColor(Color("TextSecondary"))
                if let cigar = favorites?.favoriteCigar, !cigar.isEmpty {
                    Text(cigar)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color("TextPrimary"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else {
                    Text("Kommer når du logger")
                        .font(.caption)
                        .foregroundColor(Color("TextSecondary").opacity(0.7))
                }
            }
            Spacer(minLength: 4)
            if let score = favorites?.favoriteCigarScore {
                Text("\(score)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Color("Accent"))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color("Card"))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func favoriteCard(icon: String, label: String, value: String?) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(Color("Accent"))
                Text(label)
                    .font(.caption)
                    .foregroundColor(Color("TextSecondary"))
            }
            if let value, !value.isEmpty {
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color("TextPrimary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            } else {
                Text("Kommer når du logger")
                    .font(.caption)
                    .foregroundColor(Color("TextSecondary").opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color("Card"))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func strengthLabel(_ s: Double?) -> String? {
        guard let s else { return nil }
        switch s {
        case ..<2.0: return "Mild"
        case ..<3.0: return "Medium"
        case ..<4.0: return "Fyldig"
        default:     return "Sterk"
        }
    }

    // MARK: - Offentlige humidorer (venn)

    private var publicHumidorSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Delt humidor")
            VStack(spacing: 8) {
                ForEach(publicHumidors) { entry in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color("Accent"))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "cabinet.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 18))
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.cigar?.series ?? entry.cigar?.brand ?? "Ukjent sigar")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Color("TextPrimary"))
                            if let brand = entry.cigar?.brand {
                                Text(brand)
                                    .font(.caption)
                                    .foregroundColor(Color("TextSecondary"))
                            }
                        }
                        Spacer()
                        Text("×\(entry.quantity)")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color("TextSecondary"))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color("Card"))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color("Background"))
        .padding(.top, 8)
    }

    // MARK: - Sist røkt

    @ViewBuilder
    private var lastSmokedSection: some View {
        if let log = lastLog, let cigar = log.cigar {
            VStack(alignment: .leading, spacing: 0) {
                sectionHeader("Sist røkt")
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 14) {
                        // Ikon eller bilde
                        if let photoUrl = log.photoUrl, let url = URL(string: photoUrl) {
                            AsyncImage(url: url) { img in
                                img.resizable().scaledToFill()
                            } placeholder: {
                                smokeIconBox
                            }
                            .frame(width: 68, height: 68)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            smokeIconBox
                        }

                        // Info — brand, series, notat
                        VStack(alignment: .leading, spacing: 4) {
                            Text(cigar.brand)
                                .font(.subheadline.bold())
                                .foregroundColor(Color("TextPrimary"))
                                .lineLimit(1)
                            if let series = cigar.series {
                                Text(series)
                                    .font(.caption)
                                    .foregroundColor(Color("TextSecondary"))
                                    .lineLimit(1)
                            }
                            if let notes = log.personalNotes, !notes.isEmpty {
                                Text(notes)
                                    .font(.caption)
                                    .foregroundColor(Color("TextSecondary").opacity(0.75))
                                    .lineLimit(2)
                            }
                        }

                        Spacer(minLength: 4)

                        // Rating-badge
                        if let rating = log.rating {
                            Text("\(rating)")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color("Accent"))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }

                    // Dato — alltid nederst
                    Text(log.smokedAt, format: .relative(presentation: .named))
                        .font(.caption)
                        .foregroundColor(Color("TextSecondary").opacity(0.55))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color("Card"))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
            }
        }
    }

    private var smokeIconBox: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color("Accent").opacity(0.12))
                .frame(width: 68, height: 68)
            Image(systemName: "smoke.fill")
                .font(.system(size: 26))
                .foregroundColor(Color("Accent"))
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundColor(Color("TextSecondary"))
            .tracking(0.5)
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 10)
    }

    private func initialsCircle(name: String?, size: CGFloat) -> some View {
        ZStack {
            Circle().fill(Color("Card"))
            Text(initials(for: name))
                .font(.system(size: size * 0.33, weight: .semibold))
                .foregroundColor(Color("Accent"))
        }
        .frame(width: size, height: size)
    }

    private func hasRealName(_ p: FriendProfile) -> Bool {
        let name = (p.displayName ?? "").trimmingCharacters(in: .whitespaces)
        return !name.isEmpty && name != "Sigar-entusiast"
    }

    private func bigName(for p: FriendProfile) -> String {
        if hasRealName(p) { return p.displayName!.trimmingCharacters(in: .whitespaces) }
        return isOwnProfile ? "Legg til navn" : (p.friendCode ?? "Bruker")
    }

    private func initials(for name: String?) -> String {
        guard let name, !name.isEmpty else { return "?" }
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    // MARK: - Load

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let p  = profileService.fetchFriendProfile(userId: userId)
            async let h  = isOwnProfile ? [] : profileService.fetchPublicHumidorEntries(userId: userId)
            async let ll = profileService.fetchRecentLogs(userId: userId, limit: 1)
            let (prof, humList, logs) = try await (p, h, ll)
            profile        = prof
            publicHumidors = humList
            lastLog        = logs.first
            if isOwnProfile {
                favorites = try? await profileService.fetchOwnFavorites()
            }
        } catch {
            print("UserProfileView load error: \(error)")
        }
    }
}

// MARK: - BioEditorSheet

struct BioEditorSheet: View {
    let currentBio: String
    var onSave: (String) -> Void

    @State private var text = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Fortell litt om deg selv")
                    .font(.subheadline)
                    .foregroundColor(Color("TextSecondary"))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .frame(minHeight: 120, maxHeight: 200)
                        .padding(10)

                    if text.isEmpty {
                        Text("Skriv noe om interesser, erfaringer...")
                            .font(.subheadline)
                            .foregroundColor(Color("TextSecondary").opacity(0.5))
                            .padding(.leading, 14)
                            .padding(.top, 18)
                            .allowsHitTesting(false)
                    }
                }
                .background(Color("Card"))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 16)

                Text("\(text.count) / 200 tegn")
                    .font(.caption)
                    .foregroundColor(Color("TextSecondary"))
                    .padding(.horizontal, 16)

                Spacer()
            }
            .background(Color("Background"))
            .navigationTitle("Bio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lagre") {
                        onSave(text.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear { text = currentBio }
            .onChange(of: text) { _, new in
                if new.count > 200 { text = String(new.prefix(200)) }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - BadgeLevelSheet

struct BadgeLevelSheet: View {
    let createdAt: Date?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(BadgeLevel.allCases) { level in
                        let current = BadgeLevel.level(for: createdAt)
                        let isActive = level == current
                        let isUnlocked = level.rawValue <= current.rawValue
                        HStack(spacing: 14) {
                            Text(level.icon)
                                .font(.system(size: 24))
                                .frame(width: 36)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(level.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(isUnlocked ? Color("TextPrimary") : Color("TextSecondary"))
                                Text(level.description)
                                    .font(.caption)
                                    .foregroundColor(Color("TextSecondary"))
                            }
                            Spacer()
                            if isActive {
                                Image(systemName: "star.fill")
                                    .foregroundColor(Color(hex: "#FFD97D"))
                                    .font(.system(size: 16))
                            } else if isUnlocked {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 16))
                            } else {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(Color("TextSecondary").opacity(0.4))
                                    .font(.system(size: 14))
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(isActive ? Color(hex: "#FFF3D6") : Color("Surface"))
                        .overlay(RoundedRectangle(cornerRadius: 6)
                            .stroke(isActive ? Color(hex: "#FFD97D") : Color.clear, lineWidth: 1.5))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .opacity(isUnlocked ? 1 : 0.45)
                    }
                }
                .padding(16)
            }
            .background(Color("Background"))
            .navigationTitle("Din status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Ferdig") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Badge Level

enum BadgeLevel: Int, CaseIterable, Identifiable {
    case starter     = 0
    case entusiast   = 1
    case connoisseur = 2
    case aficionado  = 3
    case maestro     = 4

    var id: Int { rawValue }

    var icon: String {
        switch self {
        case .starter:     return "🌱"
        case .entusiast:   return "🔥"
        case .connoisseur: return "💨"
        case .aficionado:  return "🏆"
        case .maestro:     return "👑"
        }
    }

    var title: String {
        switch self {
        case .starter:     return "Sigar-entusiast"
        case .entusiast:   return "Kjenner"
        case .connoisseur: return "Veteran"
        case .aficionado:  return "Mester"
        case .maestro:     return "Legende"
        }
    }

    var description: String {
        switch self {
        case .starter:     return "Ny bruker · < 1 måned"
        case .entusiast:   return "1–3 måneder"
        case .connoisseur: return "3–12 måneder"
        case .aficionado:  return "1–3 år"
        case .maestro:     return "3+ år"
        }
    }

    static func level(for date: Date?) -> BadgeLevel {
        guard let date else { return .starter }
        let months = Calendar.current.dateComponents([.month], from: date, to: .now).month ?? 0
        switch months {
        case ..<1:    return .starter
        case 1..<3:   return .entusiast
        case 3..<12:  return .connoisseur
        case 12..<36: return .aficionado
        default:      return .maestro
        }
    }
}

// MARK: - Color hex helper

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >>  8) & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
