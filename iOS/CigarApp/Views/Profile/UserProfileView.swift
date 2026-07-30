import SwiftUI
import PhotosUI
import Kingfisher

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
    @State private var myFavorites: [FavoriteListItem] = []
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

    // Crop-flyt (Mantis)
    private enum CropTarget { case avatar, cover }
    @State private var cropRequest: CropRequest?
    @State private var cropTarget: CropTarget = .avatar

    @Environment(\.colorScheme) private var colorScheme

    private let profileService = ProfileService()
    private let favoriteService = FavoriteService()
    private let friendService = FriendService()
    @State private var friendRequestSent = false

    // Samme farge som smaksnote-ikonene: #8F7B51 i lys modus, accent i mørk.
    private var accentIconColor: Color {
        colorScheme == .dark ? Color("Accent") : Color(hex: "#8F7B51")
    }

    // Bakgrunn for merke-pills (mellom-brun beige)
    private var badgeFill: Color { Color(hex: "#E0D2BA") }

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
                    favoritesSection
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
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        guard !friendRequestSent else { return }
                        friendRequestSent = true
                        Task { try? await friendService.requestFriendship(userId: userId) }
                    } label: {
                        Label(friendRequestSent ? "Forespørsel sendt" : "Legg til venn",
                              systemImage: friendRequestSent ? "checkmark" : "person.badge.plus")
                            .foregroundColor(Color("Accent"))
                    }
                    .disabled(friendRequestSent)
                }
            }
        }
        .sheet(isPresented: $showSettings, onDismiss: {
            Task { await load() }
        }) {
            ProfileSettingsView()
        }
        .sheet(isPresented: $showBadgeSheet) {
            if let p = profile { MerkerView(profile: p) }
        }
        .sheet(isPresented: $showBioEditor) {
            BioEditorSheet(currentBio: profile?.bio ?? "") { newBio in
                guard let uid = authService.userId else { return }
                Task {
                    await attempt("Lagre bio") {
                        try await profileService.saveBio(userId: uid, bio: newBio)
                    }
                    profile = try? await profileService.fetchFriendProfile(userId: userId)
                }
            }
        }
        .onChange(of: avatarItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let raw = try? await newItem.loadTransferable(type: Data.self),
                   let img = UIImage(data: raw) {
                    cropTarget = .avatar
                    cropRequest = CropRequest(image: img, ratio: 1)   // kvadrat
                }
                avatarItem = nil
            }
        }
        .onChange(of: coverItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let raw = try? await newItem.loadTransferable(type: Data.self),
                   let img = UIImage(data: raw) {
                    cropTarget = .cover
                    cropRequest = CropRequest(image: img, ratio: 2.6)  // bredt banner
                }
                coverItem = nil
            }
        }
        .fullScreenCover(item: $cropRequest) { req in
            ImageCropper(image: req.image, ratio: req.ratio) { cropped in
                cropRequest = nil
                uploadCropped(cropped)
            } onCancel: {
                cropRequest = nil
            }
            .ignoresSafeArea()
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
        let badge = MemberLevel.current(p.memberStats)

        return VStack(spacing: 0) {

            // Toppbilde (cover)
            ZStack(alignment: .topTrailing) {
                Group {
                    if let url = displayCoverURL.flatMap(URL.init) {
                        KFImage(url)
                            .resizable()
                            .placeholder { Color("Accent").opacity(0.22) }
                            .fade(duration: 0.15)
                            .scaledToFill()
                    } else {
                        Color("Accent").opacity(0.22)
                    }
                }
                .frame(height: 140)
                .frame(maxWidth: .infinity)
                .clipped()

                if isOwnProfile {
                    PhotosPicker(selection: $coverItem, matching: .images) {
                        EditPhotoPill(isBusy: isUploadingCover)
                    }
                }
            }

            // Horisontal info-seksjon
            HStack(alignment: .top, spacing: 16) {

                // --- Avatar (venstre) ---
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let url = displayAvatarURL.flatMap(URL.init) {
                            KFImage(url)
                                .resizable()
                                .placeholder { initialsCircle(name: p.displayName, size: 80) }
                                .fade(duration: 0.15)
                                .scaledToFill()
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

                // --- Info (høyre) — 4px eksplisitt luft mellom hvert element ---
                VStack(alignment: .leading, spacing: 0) {

                    // Navn
                    Text(bigName(for: p))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(hasRealName(p) ? Color("TextPrimary") : Color("TextSecondary"))

                    // Merker (pill-form) med ikon. Nivå-merke + evt. Tidlig tester.
                    HStack(spacing: 6) {
                        Button { showBadgeSheet = true } label: {
                            HStack(spacing: 5) {
                                Image(systemName: badge.icon)
                                Text(badge.title)
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color("Accent"))
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Capsule().fill(badgeFill))
                        }
                        .buttonStyle(.plain)

                        if p.isFoundingMember == true {
                            HStack(spacing: 5) {
                                Image(systemName: "sparkles")
                                Text("Tidlig tester")
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color("Accent"))
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Capsule().fill(badgeFill))
                        }
                    }
                    .padding(.top, 4)

                    // Bio
                    if let bio = p.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.system(size: 14))
                            .foregroundColor(Color("TextPrimary").opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 4)
                            .onTapGesture { if isOwnProfile { showBioEditor = true } }
                    } else if isOwnProfile {
                        Button { showBioEditor = true } label: {
                            Text("Legg til bio...")
                                .font(.system(size: 14))
                                .foregroundColor(Color("TextSecondary").opacity(0.55))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
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
                    .padding(.top, 4)
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
                    statCell(icon: "smoke", value: p.cigarCount, label: "I journal")
                }
                .buttonStyle(.plain)
            } else {
                statCell(icon: "smoke", value: p.cigarCount, label: "I journal")
            }

            statDivider()

            // Favoritter → HumidorView på Favoritter-fanen (kun egen profil)
            if isOwnProfile {
                NavigationLink {
                    HumidorView(initialTab: .favorites).environmentObject(authService)
                } label: {
                    statCell(icon: "star", value: myFavorites.count, label: "Favoritter")
                }
                .buttonStyle(.plain)
            } else {
                statCell(icon: "star.fill", value: myFavorites.count, label: "Favoritter")
            }

            statDivider()

            // Venner → VennerView (kun navigasjon på egen profil)
            if isOwnProfile {
                NavigationLink {
                    VennerView().environmentObject(authService)
                } label: {
                    statCell(icon: "person.2", value: p.friendCount, label: "Venner")
                }
                .buttonStyle(.plain)
            } else {
                statCell(icon: "person.2.fill", value: p.friendCount, label: "Venner")
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .background(Color("Card"))
    }

    private func statDivider() -> some View {
        Divider().frame(height: 48)
    }

    private func statCell(icon: String, value: Int, label: String, showDash: Bool = false) -> some View {
        VStack(spacing: 4) {
            // Ikon ved siden av tallet → lavere celle enn stablet layout
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(accentIconColor)
                Text(showDash ? "–" : "\(value)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color("TextPrimary"))
            }
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(Color("TextSecondary"))
                .textCase(.uppercase)
                .tracking(0.3)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 2)
        .contentShape(Rectangle())   // hele cellen trykkbar
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
                HStack(alignment: .top, spacing: 14) {
                    // Ikon eller bilde
                    if let photoUrl = log.photoUrl, let url = URL(string: photoUrl) {
                        KFImage(url)
                            .resizable()
                            .placeholder { smokeIconBox }
                            .fade(duration: 0.15)
                            .scaledToFill()
                            .frame(width: 68, height: 68)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        smokeIconBox
                    }

                    // Info — brand, series/vitola, tidspunkt (alt stablet vertikalt)
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
                        // Tidspunkt for røkt — under de andre tekstene
                        Text(log.smokedAt, format: .dateTime.day().month(.wide).year().hour().minute())
                            .font(.caption2)
                            .foregroundColor(Color("TextSecondary").opacity(0.55))
                            .padding(.top, 2)
                    }

                    Spacer(minLength: 4)

                    // Score-badge — lik som alle andre steder + vertikalt sentrert
                    if let rating = log.rating {
                        Text("\(rating)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color("Accent"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color("Accent").opacity(0.1))
                            .clipShape(Capsule())
                            .frame(maxHeight: .infinity, alignment: .center)
                    }
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

    @ViewBuilder
    private var favoritesSection: some View {
        if !myFavorites.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                sectionHeader("Favoritter")
                VStack(spacing: 8) {
                    ForEach(myFavorites) { fav in
                        HStack(spacing: 12) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                                .foregroundColor(accentIconColor)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(fav.brand)
                                    .font(.subheadline.bold())
                                    .foregroundColor(Color("TextPrimary"))
                                    .lineLimit(1)
                                let sub = [fav.series, fav.vitola].compactMap { $0 }.joined(separator: " · ")
                                if !sub.isEmpty {
                                    Text(sub)
                                        .font(.caption)
                                        .foregroundColor(Color("TextSecondary"))
                                        .lineLimit(1)
                                }
                            }
                            Spacer(minLength: 4)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color("Card"))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                .padding(.horizontal, 16)
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
            .font(.system(size: 13, weight: .semibold))   // +1px (var .caption/12)
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

    // Laster opp det ferdig-croppede bildet (tjenesten skalerer ned videre).
    private func uploadCropped(_ image: UIImage) {
        guard let uid = authService.userId,
              let data = image.jpegData(compressionQuality: 1.0) else { return }
        let isAvatar = (cropTarget == .avatar)
        Task {
            if isAvatar { isUploadingAvatar = true } else { isUploadingCover = true }
            do {
                if isAvatar {
                    localAvatarURL = try await profileService.uploadAvatar(userId: uid, imageData: data)
                } else {
                    localCoverURL = try await profileService.uploadCover(userId: uid, imageData: data)
                }
            } catch {
                uploadErrorMessage = "Kunne ikke laste opp bilde: \(error.localizedDescription)"
            }
            if isAvatar { isUploadingAvatar = false } else { isUploadingCover = false }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            // «Sist røkt» hentes kun for egen profil. RLS på tasting_logs slipper
            // uansett bare gjennom egne rader, så et kall for en venn ville stille
            // returnert tomt. Å åpne tabellen for venner ville eksponert HELE
            // journalen deres — også logger de aldri har delt i feeden — og
            // røykelogger er sannsynligvis helseopplysninger (GDPR art. 9).
            async let p  = profileService.fetchFriendProfile(userId: userId)
            async let h  = isOwnProfile ? [] : profileService.fetchPublicHumidorEntries(userId: userId)
            async let ll = isOwnProfile ? profileService.fetchRecentLogs(userId: userId, limit: 1) : []
            let (prof, humList, logs) = try await (p, h, ll)
            profile        = prof
            publicHumidors = humList
            lastLog        = logs.first
            // Favorittliste — via RPC med vennskaps-sjekk, virker for egen profil og venner
            myFavorites = (try? await favoriteService.fetchFavoriteList(userId: userId)) ?? []
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

// MARK: - Ansiennitet (Primary) — tid + handlinger

struct MemberStats {
    let months: Int
    let journal: Int          // tasting_logs (røkt/loggført)
    let humidorCigars: Int    // sigarer i humidorene
    let humidors: Int         // antall humidor-beholdere
    let rh: Int               // RH-målinger
    let brands: Int           // unike merker
}

extension FriendProfile {
    var memberStats: MemberStats {
        let months = createdAt.map {
            Calendar.current.dateComponents([.month], from: $0, to: .now).month ?? 0
        } ?? 0
        return MemberStats(
            months: months, journal: cigarCount, humidorCigars: humidorCount,
            humidors: humidorsCount ?? 0, rh: rhCount ?? 0, brands: brandsTried
        )
    }
}

enum MemberLevel: Int, CaseIterable, Identifiable {
    case sigarentusiast = 0, kjenner, samler, kurator, aficionado
    var id: Int { rawValue }

    var title: String {
        switch self {
        case .sigarentusiast: return "Sigarentusiast"
        case .kjenner:        return "Kjenner"
        case .samler:         return "Samler"
        case .kurator:        return "Kurator"
        case .aficionado:     return "Sigaraficionado"
        }
    }

    var icon: String {
        switch self {
        case .sigarentusiast: return "flame"
        case .kjenner:        return "star"
        case .samler:         return "square.stack.3d.up"
        case .kurator:        return "rosette"
        case .aficionado:     return "crown"
        }
    }

    var criteria: String {
        switch self {
        case .sigarentusiast: return "Fra dag 1"
        case .kjenner:        return "1 md · 5+ journalinnlegg"
        case .samler:         return "3 md · 2 humidorer · 10 sigarer · RH-måling"
        case .kurator:        return "6 md · 3 humidorer · 30 sigarer · 15 journalinnlegg"
        case .aficionado:     return "12 md · 100+ røkt · 20+ merker"
        }
    }

    func achieved(_ s: MemberStats) -> Bool {
        switch self {
        case .sigarentusiast: return true
        case .kjenner:        return s.months >= 1 && s.journal >= 5
        case .samler:         return s.months >= 3 && s.humidors >= 2 && s.humidorCigars >= 10 && s.rh >= 1
        case .kurator:        return s.months >= 6 && s.humidors >= 3 && s.humidorCigars >= 30 && s.journal >= 15
        case .aficionado:     return s.months >= 12 && s.journal >= 100 && s.brands >= 20
        }
    }

    /// Høyeste sammenhengende oppnådde nivå (stopper ved første hull).
    static func current(_ s: MemberStats) -> MemberLevel {
        var lvl: MemberLevel = .sigarentusiast
        for l in allCases { if l.achieved(s) { lvl = l } else { break } }
        return lvl
    }
}

// MARK: - Opptjente merker (Secondary)

struct SecondaryBadge: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let icon: String
    let earned: Bool
}

// MARK: - MerkerView (merke-oversikt)

struct MerkerView: View {
    let profile: FriendProfile
    @Environment(\.dismiss) private var dismiss

    private var stats: MemberStats { profile.memberStats }
    private var current: MemberLevel { MemberLevel.current(stats) }

    private var secondaryBadges: [SecondaryBadge] {
        [
            SecondaryBadge(id: 0, title: "Tidlig tester", subtitle: "Blant de første",
                           icon: "seal", earned: profile.isFoundingMember == true),
            SecondaryBadge(id: 1, title: "Anmelder", subtitle: "50+ vurderinger",
                           icon: "pencil", earned: stats.journal >= 50),
            SecondaryBadge(id: 2, title: "Bidragsyter", subtitle: "Godkjente rettelser",
                           icon: "hand.thumbsup", earned: false),
            SecondaryBadge(id: 3, title: "Pioner", subtitle: "Legg til nye sigarer",
                           icon: "plus.circle", earned: false),
            SecondaryBadge(id: 4, title: "Ambassadør", subtitle: "Verv 3 venner",
                           icon: "person.2.badge.plus", earned: false),
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {

                    // Ansiennitet
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("ANSIENNITET")
                        VStack(spacing: 8) {
                            ForEach(MemberLevel.allCases) { level in
                                levelRow(level, earned: level.rawValue <= current.rawValue,
                                         isCurrent: level == current)
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    // Opptjente merker
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("OPPTJENTE MERKER").padding(.horizontal, 16)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(secondaryBadges) { secondaryCard($0) }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color("Background"))
            .navigationTitle("Merker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Ferdig") { dismiss() } }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func sectionLabel(_ t: String) -> some View {
        Text(t).font(.system(size: 12, weight: .semibold))
            .foregroundColor(Color("TextSecondary")).tracking(0.6)
    }

    private func levelRow(_ level: MemberLevel, earned: Bool, isCurrent: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color("Accent").opacity(earned ? 0.14 : 0.06)).frame(width: 42, height: 42)
                Image(systemName: level.icon)
                    .font(.system(size: 18))
                    .foregroundColor(earned ? Color("Accent") : Color("TextSecondary").opacity(0.5))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(level.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(earned ? Color("TextPrimary") : Color("TextSecondary"))
                Text(level.criteria)
                    .font(.system(size: 11))
                    .foregroundColor(Color("TextSecondary"))
            }
            Spacer(minLength: 8)
            if earned {
                Text("Samlet")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color("Accent"))
                    .padding(.horizontal, 9).padding(.vertical, 3)
                    .background(Capsule().fill(Color("Accent").opacity(0.12)))
            } else {
                Image(systemName: "lock").font(.system(size: 14)).foregroundColor(Color("TextSecondary").opacity(0.5))
            }
        }
        .padding(12)
        .background(Color("Card"))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(isCurrent ? Color("Accent") : Color.clear, lineWidth: 1.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func secondaryCard(_ b: SecondaryBadge) -> some View {
        VStack(spacing: 6) {
            Image(systemName: b.icon)
                .font(.system(size: 22))
                .foregroundColor(b.earned ? Color("Accent") : Color("TextSecondary").opacity(0.5))
            Text(b.title).font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color("TextPrimary"))
            Text(b.subtitle).font(.system(size: 11))
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)
            if b.earned {
                Text("Samlet").font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color("Accent"))
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(Capsule().fill(Color("Accent").opacity(0.12)))
            } else {
                Image(systemName: "lock").font(.system(size: 12)).foregroundColor(Color("TextSecondary").opacity(0.5))
            }
        }
        .frame(width: 128)
        .padding(.vertical, 14).padding(.horizontal, 10)
        .background(Color("Card"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
