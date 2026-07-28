import SwiftUI
import LinkPresentation
import PhotosUI
import Kingfisher

// MARK: - FeedView
// Sosial feed — poster fra deg selv og venner.
// Inneholder: FeedView, FeedPostCard, CreatePostView, PostDetailView, SEDERSharingCard

/// Oppdater denne til App Store-lenken når appen er publisert
private let vitolaShareURL = "https://vitola.app"

// ═══════════════════════════════════════════════════════════
// MARK: FeedView — hoved-tab
// ═══════════════════════════════════════════════════════════

struct FeedView: View {

    @EnvironmentObject var authService: AuthService
    @Environment(\.colorScheme) private var colorScheme

    @State private var posts: [FeedPost] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showCreatePost = false
    @State private var showLoginSheet = false

    private let feedService = FeedService()

    var body: some View {
        NavigationStack {
            Group {
                if authService.userId == nil {
                    feedLoggedOut
                } else if isLoading {
                    ProgressView("Laster feed...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color("Background"))
                } else if posts.isEmpty {
                    feedEmpty
                } else {
                    postsList
                }
            }
            .background(Color("Background"))
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.inline)   // liten sentrert tittel → lista høyere opp
            .toolbarBackground(Color("Background"), for: .navigationBar)
            // Tittelfargen fulgte ikke lys/mørk modus når baren fikk egen bakgrunn
            // (ble hvit og usynlig i lys modus ved scroll). Tving riktig kontrast.
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .toolbar {
                if authService.userId != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showCreatePost = true
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color("Accent"))
                        }
                    }
                }
            }
            .onAppear { Task { await loadFeed() } }
            .refreshable { await loadFeed() }
            .sheet(isPresented: $showCreatePost) {
                CreatePostView { newPost in
                    withAnimation { posts.insert(newPost, at: 0) }
                }
                .environmentObject(authService)
            }
            .sheet(isPresented: $showLoginSheet) {
                AuthView(onSuccess: { Task { await loadFeed() } })
            }
            .alert("Feil", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: Liste

    private var postsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(posts) { post in
                    FeedPostCard(
                        post: post,
                        onLike: { await toggleLike(post) }
                    )
                    .environmentObject(authService)
                    .overlay(alignment: .topTrailing) {
                        PostMenuButton(
                            post: post,
                            currentUserId: authService.userId,
                            onDelete: { await deletePost(post) },
                            onReport: { reason in await reportPost(post, reason: reason) },
                            onBlock: { await blockUser(post) }
                        )
                        .padding(.top, 14)
                        .padding(.trailing, 14)
                    }
                    // Facebook-stil skillestrek mellom innlegg
                    Color("Background").frame(height: 8)
                }
            }
        }
        .background(Color("Background"))
    }

    // MARK: Tomme tilstander

    private var feedLoggedOut: some View {
        VStack(spacing: 16) {
            Image(systemName: "newspaper")
                .font(.system(size: 52))
                .foregroundColor(Color("TextSecondary").opacity(0.4))
            Text("Logg inn for å se feeden")
                .font(.title3.bold())
                .multilineTextAlignment(.center)
            Text("Se hva vennene dine røyker\nog del dine egne innlegg")
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)
            Button("Logg inn") { showLoginSheet = true }
                .fontWeight(.semibold)
                .frame(maxWidth: 200)
                .padding()
                .background(Color("Accent"))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.top, 4)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var feedEmpty: some View {
        VStack(spacing: 16) {
            Image(systemName: "newspaper")
                .font(.system(size: 52))
                .foregroundColor(Color("TextSecondary").opacity(0.4))
            Text("Ingen innlegg ennå")
                .font(.title3.bold())
            Text("Legg til venner og del dine\nfavoritt-sigarer med dem")
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)
            Button("Del et innlegg") { showCreatePost = true }
                .fontWeight(.semibold)
                .frame(maxWidth: 200)
                .padding()
                .background(Color("Accent"))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.top, 4)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Actions

    private func loadFeed() async {
        guard authService.userId != nil else {
            isLoading = false
            return
        }
        isLoading = true
        do {
            posts = try await feedService.fetchFeed()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func toggleLike(_ post: FeedPost) async {
        guard authService.userId != nil,
              let idx = posts.firstIndex(where: { $0.id == post.id }) else { return }
        do {
            let liked = try await feedService.toggleLike(postId: post.id)
            posts[idx].likedByMe = liked
            posts[idx].likeCount += liked ? 1 : -1
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deletePost(_ post: FeedPost) async {
        do {
            try await feedService.deletePost(postId: post.id)
            posts.removeAll { $0.id == post.id }   // fjern lokalt med en gang
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func reportPost(_ post: FeedPost, reason: String) async {
        do {
            try await feedService.reportPost(postId: post.id, reason: reason)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func blockUser(_ post: FeedPost) async {
        do {
            try await feedService.blockUser(userId: post.userId)
            posts.removeAll { $0.userId == post.userId }   // skjul alle deres innlegg
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: PostMenuButton — 3-dot kontekstmeny på et innlegg
// ═══════════════════════════════════════════════════════════

private struct PostMenuButton: View {
    let post: FeedPost
    let currentUserId: UUID?
    let onDelete: () async -> Void
    let onReport: (String) async -> Void
    let onBlock: () async -> Void

    @State private var showDeleteConfirm = false
    @State private var showReportReasons = false
    @State private var showBlockConfirm = false
    @State private var showReportDone = false

    private var isOwner: Bool {
        currentUserId != nil && post.userId == currentUserId
    }

    var body: some View {
        Menu {
            if isOwner {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Slett innlegg", systemImage: "trash")
                }
            } else {
                Button {
                    showReportReasons = true
                } label: {
                    Label("Rapporter innlegg", systemImage: "flag")
                }
                Button(role: .destructive) {
                    showBlockConfirm = true
                } label: {
                    Label("Blokker \(post.authorName)", systemImage: "hand.raised")
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 14))
                .foregroundColor(Color("TextSecondary"))
                .frame(width: 30, height: 24)
                .contentShape(Rectangle())
        }
        // Slett (eier)
        .confirmationDialog("Slett innlegg?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Slett innlegg", role: .destructive) { Task { await onDelete() } }
            Button("Avbryt", role: .cancel) {}
        } message: {
            Text("Dette fjerner innlegget permanent. Handlingen kan ikke angres.")
        }
        // Rapporter — velg grunn
        .confirmationDialog("Rapporter innlegg", isPresented: $showReportReasons, titleVisibility: .visible) {
            Button("Spam eller villedende") { report("spam") }
            Button("Upassende innhold") { report("inappropriate") }
            Button("Trakassering eller hat", role: .destructive) { report("harassment") }
            Button("Annet") { report("other") }
            Button("Avbryt", role: .cancel) {}
        } message: {
            Text("Hvorfor rapporterer du dette innlegget?")
        }
        // Blokker bruker
        .confirmationDialog("Blokker \(post.authorName)?", isPresented: $showBlockConfirm, titleVisibility: .visible) {
            Button("Blokker", role: .destructive) { Task { await onBlock() } }
            Button("Avbryt", role: .cancel) {}
        } message: {
            Text("Du vil ikke lenger se innlegg eller kommentarer fra \(post.authorName), og dere fjernes som venner.")
        }
        // Kvittering på rapport
        .alert("Takk for rapporten", isPresented: $showReportDone) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Vi ser på innlegget.")
        }
    }

    private func report(_ reason: String) {
        Task {
            await onReport(reason)
            try? await Task.sleep(nanoseconds: 400_000_000)  // la dialogen lukkes først
            showReportDone = true
        }
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: FeedPostCard — ett innlegg i feeden
// ═══════════════════════════════════════════════════════════

struct FeedPostCard: View {

    @EnvironmentObject var authService: AuthService
    let post: FeedPost
    var onLike: () async -> Void

    @State private var showShareSheet = false
    @State private var previewComments: [FeedComment] = []

    private let feedService = FeedService()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Kun innholdet navigerer til detaljvisning. Handlingsraden under
            // ligger UTENFOR denne lenken, ellers svelger NavigationLink
            // trykkene på like/kommentar/del-knappene.
            NavigationLink {
                PostDetailView(post: post)
                    .environmentObject(authService)
            } label: {
              VStack(alignment: .leading, spacing: 0) {

            // ── Header: forfatter + tid ──────────────────────
            HStack(spacing: 10) {
                AvatarView(url: post.authorAvatarUrl, name: post.authorName, size: 40)
                VStack(alignment: .leading, spacing: 1) {
                    Text(post.authorName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color("TextPrimary"))
                    Text(post.relativeTime)
                        .font(.caption)
                        .foregroundColor(Color("TextSecondary"))
                }
                Spacer()
                // 3-dot-menyen tegnes som overlay i FeedView (utenfor NavigationLink),
                // slik at trykk åpner en kontekstmeny i stedet for å navigere.
                // Reserver plass her så forfatter-teksten ikke går under menyen.
                Color.clear.frame(width: 30, height: 24)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // ── Tekst (over bildet, som Facebook) ─────────────
            if let text = post.content, !text.isEmpty {
                Text(text)
                    .font(.system(size: 15))
                    .foregroundColor(Color("TextPrimary"))
                    .lineLimit(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
            }

            // ── Sigar-chip (hvis koblet til tasting_log) ────
            if let name = post.cigarDisplayName {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11))
                    Text(name)
                        .font(.caption.weight(.semibold))
                    if let label = post.cigarScoreLabel, let rating = post.cigarRating {
                        Spacer()
                        Text("\(rating) · \(label)")
                            .font(.caption.weight(.medium))
                            .foregroundColor(scoreColor(for: post.cigarRating))
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(scoreColor(for: post.cigarRating).opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                .foregroundColor(Color("Accent"))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color("Accent").opacity(0.08))
                .padding(.bottom, 8)
            }

            // ── Bilde — full bredde, naturlig format (ingen crop, som Facebook) ──
            let photoUrl = post.imageUrl ?? post.tastingPhotoUrl
            if let urlStr = photoUrl, let url = URL(string: urlStr) {
                KFImage(url)
                    .resizable()
                    .placeholder {
                        Color("Surface").frame(height: 220).overlay(ProgressView())
                    }
                    .fade(duration: 0.15)
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
            }

              }
            }
            .buttonStyle(.plain)

            Divider().padding(.horizontal, 14)

            // ── Handlingsrad: like, kommentar, del ───────────
            HStack(spacing: 0) {
                // Like
                Button {
                    Task { await onLike() }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: post.likedByMe ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                            .foregroundColor(post.likedByMe ? .red : Color("TextSecondary"))
                        if post.likeCount > 0 {
                            Text("\(post.likeCount)")
                                .font(.caption.weight(.medium))
                                .foregroundColor(Color("TextSecondary"))
                        }
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)

                // Kommentar — åpner detaljvisningen med kommentarfeltet
                NavigationLink {
                    PostDetailView(post: post)
                        .environmentObject(authService)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 16))
                            .foregroundColor(Color("TextSecondary"))
                        if post.commentCount > 0 {
                            Text("\(post.commentCount)")
                                .font(.caption.weight(.medium))
                                .foregroundColor(Color("TextSecondary"))
                        }
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)

                // Del (Facebook + iOS share sheet)
                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                        .foregroundColor(Color("TextSecondary"))
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .sheet(isPresented: $showShareSheet) {
                    SEDERSharingSheet(post: post)
                }
            }
            .padding(.horizontal, 6)

            // ── Kommentar-forhåndsvisning (som Facebook) ─────
            if post.commentCount > 0 {
                Divider().padding(.horizontal, 14)
                VStack(alignment: .leading, spacing: 6) {
                    if post.commentCount > previewComments.count {
                        NavigationLink {
                            PostDetailView(post: post)
                                .environmentObject(authService)
                        } label: {
                            Text("Vis alle \(post.commentCount) kommentarer")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(Color("TextSecondary"))
                        }
                        .buttonStyle(.plain)
                    }
                    ForEach(previewComments) { c in
                        (Text(c.authorName).font(.subheadline.weight(.semibold))
                            + Text("  ").font(.subheadline)
                            + Text(c.content).font(.subheadline))
                            .foregroundColor(Color("TextPrimary"))
                            .lineLimit(3)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
        }
        .background(Color("Card"))
        .task {
            if post.commentCount > 0 {
                previewComments = (try? await feedService.fetchComments(postId: post.id).suffix(2).map { $0 }) ?? []
            }
        }
    }

    private func scoreColor(for rating: Int?) -> Color {
        guard let r = rating else { return Color("TextSecondary") }
        switch r {
        case 90...: return Color(red: 0.85, green: 0.65, blue: 0.2)
        case 80...: return Color(red: 0.65, green: 0.5, blue: 0.1)
        default:    return Color(.systemGray)
        }
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: CreatePostView — skriv nytt innlegg
// ═══════════════════════════════════════════════════════════

struct CreatePostView: View {

    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    var onCreated: (FeedPost) -> Void

    @State private var contentText = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var photoImage: Image?
    @State private var cropRequest: CropRequest?
    @State private var isPosting = false
    @State private var errorMessage: String?
    @FocusState private var textFieldFocused: Bool

    private let feedService = FeedService()

    private var canPost: Bool {
        !contentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || photoData != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {

                    // ── Tekstfelt ──────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Hva røyker du? Del tanker, smaksnotater...", text: $contentText, axis: .vertical)
                            .lineLimit(4...12)
                            .font(.body)
                            .foregroundColor(Color("TextPrimary"))
                            .tint(Color("Accent"))
                            .focused($textFieldFocused)
                            .padding(14)
                            .background(Color("Card"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            textFieldFocused = true
                        }
                    }

                    // ── Valgt bilde ────────────────────────────
                    if let photoImage {
                        // Beholder bestemmer størrelsen; bildet som overlay hindrer at
                        // scaledToFill skyver skjermen til venstre (samme fiks som i feeden).
                        Color("Surface")
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .overlay(
                                photoImage
                                    .resizable()
                                    .scaledToFill()
                            )
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    self.photoImage = nil
                                    self.photoData = nil
                                    self.photoItem = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.white)
                                        .shadow(radius: 4)
                                }
                                .padding(.top, 20)
                                .padding(.trailing, 22)
                            }
                    }

                    // ── Legg til bilde ─────────────────────────
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                            Text(photoData != nil ? "Bytt bilde" : "Legg til bilde")
                                .font(.subheadline)
                        }
                        .foregroundColor(Color("Accent"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .onChange(of: photoItem) { _, newItem in
                        Task {
                            guard let newItem,
                                  let data = try? await newItem.loadTransferable(type: Data.self),
                                  let uiImg = UIImage(data: data) else { return }
                            cropRequest = CropRequest(image: uiImg, ratio: 1.7)  // bredt feed-bilde
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

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 16)
                    }

                    Spacer(minLength: 40)
                }
            }
            .background(Color("Background"))
            .navigationTitle("Nytt innlegg")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: post) {
                        if isPosting {
                            ProgressView().tint(Color("Accent"))
                        } else {
                            Text("Del")
                                .fontWeight(.semibold)
                                .foregroundColor(canPost ? Color("Accent") : Color("TextSecondary"))
                        }
                    }
                    .disabled(!canPost || isPosting)
                }
            }
        }
    }

    private func post() {
        guard let userId = authService.userId, canPost, !isPosting else { return }
        isPosting = true
        errorMessage = nil

        Task {
            do {
                // Last opp bilde hvis valgt
                var imageUrl: String? = nil
                if let data = photoData {
                    let tempPostId = UUID()
                    imageUrl = try await feedService.uploadPostImage(userId: userId, postId: tempPostId, imageData: data)
                }

                let newPost = try await feedService.createPost(
                    userId: userId,
                    content: contentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : contentText.trimmingCharacters(in: .whitespacesAndNewlines),
                    imageUrl: imageUrl
                )

                onCreated(newPost)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isPosting = false
        }
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: PostDetailView — kommentarer
// ═══════════════════════════════════════════════════════════

struct PostDetailView: View {

    @EnvironmentObject var authService: AuthService
    var post: FeedPost

    @State private var comments: [FeedComment] = []
    @State private var isLoading = true
    @State private var commentText = ""
    @State private var isSending = false
    @State private var errorMessage: String?

    private let feedService = FeedService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // ── Selve innlegget (forenklet) ────────────────
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        AvatarView(url: post.authorAvatarUrl, name: post.authorName, size: 36)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(post.authorName).font(.subheadline.weight(.semibold))
                            Text(post.relativeTime).font(.caption).foregroundColor(Color("TextSecondary"))
                        }
                    }

                    if let name = post.cigarDisplayName {
                        HStack(spacing: 5) {
                            Image(systemName: "flame.fill").font(.system(size: 11))
                            Text(name).font(.caption.weight(.semibold))
                            if let label = post.cigarScoreLabel, let rating = post.cigarRating {
                                Spacer()
                                Text("\(rating) · \(label)").font(.caption.weight(.medium))
                                    .padding(.horizontal, 7).padding(.vertical, 3)
                                    .background(Color("Accent").opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                        .foregroundColor(Color("Accent"))
                        .padding(8).background(Color("Accent").opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    if let urlStr = post.imageUrl ?? post.tastingPhotoUrl, let url = URL(string: urlStr) {
                        // Full kortbredde, naturlig format (ingen crop) — som i feeden.
                        // Negativ horisontal padding kansellerer kortets .padding(16)
                        // så bildet når kortkantene.
                        KFImage(url)
                            .resizable()
                            .placeholder {
                                Color("Surface").frame(height: 220).overlay(ProgressView())
                            }
                            .fade(duration: 0.15)
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, -16)
                    }

                    if let text = post.content, !text.isEmpty {
                        // Samme tekststørrelse som feed-kortet (15), ikke .body.
                        Text(text).font(.system(size: 15)).foregroundColor(Color("TextPrimary"))
                    }
                }
                .padding(16)
                // Lås kortet til container-bredden. Uten dette lar scaledToFill-bildet
                // kortet vokse forbi skjermkanten, og VStack(alignment: .leading) i
                // ScrollView-en pinner det til venstre — det var «skjøvet til venstre»-feilen.
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color("Card"))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 16)
                .padding(.top, 12)

                // ── Kommentarer ────────────────────────────────
                Text("Kommentarer")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color("TextSecondary"))
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                if isLoading {
                    ProgressView().padding()
                } else if comments.isEmpty {
                    Text("Ingen kommentarer ennå. Vær den første!")
                        .font(.subheadline)
                        .foregroundColor(Color("TextSecondary"))
                        .padding(.horizontal, 16)
                } else {
                    VStack(spacing: 8) {
                        ForEach(comments) { comment in
                            CommentRow(comment: comment)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                Spacer(minLength: 100)
            }
        }
        .background(Color("Background"))
        .navigationTitle("Innlegg")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("Background"), for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            if authService.userId != nil {
                commentInput
            }
        }
        .onAppear { Task { await loadComments() } }
        .alert("Feil", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }

    private var commentInput: some View {
        HStack(spacing: 10) {
            TextField("Skriv en kommentar...", text: $commentText)
                .font(.body)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color("Card"))
                .clipShape(RoundedRectangle(cornerRadius: 20))

            Button(action: sendComment) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(commentText.isEmpty ? Color("TextSecondary") : Color("Accent"))
            }
            .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color("Background").shadow(.drop(color: .black.opacity(0.06), radius: 4, y: -2)))
    }

    private func loadComments() async {
        isLoading = true
        do {
            comments = try await feedService.fetchComments(postId: post.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func sendComment() {
        guard let userId = authService.userId,
              !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !isSending else { return }

        let text = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        isSending = true
        commentText = ""

        Task {
            do {
                try await feedService.addComment(postId: post.id, userId: userId, content: text)
                comments = try await feedService.fetchComments(postId: post.id)
            } catch {
                errorMessage = error.localizedDescription
            }
            isSending = false
        }
    }
}

// MARK: - CommentRow

struct CommentRow: View {
    let comment: FeedComment

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            AvatarView(url: comment.authorAvatarUrl, name: comment.authorName, size: 30)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(comment.authorName)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color("TextPrimary"))
                    Text(comment.relativeTime)
                        .font(.caption2)
                        .foregroundColor(Color("TextSecondary"))
                }
                Text(comment.content)
                    .font(.subheadline)
                    .foregroundColor(Color("TextPrimary"))
                    .multilineTextAlignment(.leading)
            }
            Spacer()
        }
        .padding(10)
        .background(Color("Card"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: SEDERSharingSheet — del innlegg
// ═══════════════════════════════════════════════════════════
// Viser en branded SEDER-kort som bilde, og lar brukeren dele
// via iOS share sheet (Facebook, Instagram, Messages osv.)

struct SEDERSharingSheet: View {

    let post: FeedPost
    @Environment(\.dismiss) private var dismiss
    @State private var showIOSShareSheet = false
    @State private var shareImage: UIImage?
    @State private var loadedPostImage: UIImage?   // pre-fetchet bilde
    @State private var isPreloading = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                Text("Del innlegg")
                    .font(.title3.bold())
                    .padding(.top, 8)

                // Branded kort-forhåndsvisning
                SEDERBrandedCard(post: post, loadedImage: loadedPostImage)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
                    .padding(.horizontal, 24)

                Text("Del dette kortet som bilde på Facebook, Instagram eller andre plattformer")
                    .font(.subheadline)
                    .foregroundColor(Color("TextSecondary"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                // Hoved del-knapp
                Button {
                    shareImage = renderCardAsImage()
                    showIOSShareSheet = true
                } label: {
                    HStack(spacing: 10) {
                        if isPreloading {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Text("Del via...")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color("Accent"))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isPreloading)
                .padding(.horizontal, 24)

                Spacer()
            }
            .background(Color("Background"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Lukk") { dismiss() }
                }
            }
            .task { await preloadImage() }
            .sheet(isPresented: $showIOSShareSheet) {
                if let img = shareImage {
                    IOSShareSheet(items: [img, vitolaShareURL])
                }
            }
        }
    }

    /// Last ned postbildet på forhånd slik at ImageRenderer får det med
    private func preloadImage() async {
        let urlStr = post.imageUrl ?? post.tastingPhotoUrl
        guard let str = urlStr, let url = URL(string: str) else {
            isPreloading = false
            return
        }
        if let (data, _) = try? await URLSession.shared.data(from: url),
           let img = UIImage(data: data) {
            loadedPostImage = img
        }
        isPreloading = false
    }

    /// Rendrer det branded kortet til en UIImage via ImageRenderer (iOS 16+)
    @MainActor
    private func renderCardAsImage() -> UIImage {
        let card = SEDERBrandedCard(post: post, loadedImage: loadedPostImage)
            .frame(width: 375, height: 260)

        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0 // retina
        return renderer.uiImage ?? UIImage()
    }
}

// MARK: - SEDERBrandedCard
// Det branded kortet som deles. Viser sigar, score, tekst og SEDER-logo.

struct SEDERBrandedCard: View {

    let post: FeedPost
    var loadedImage: UIImage? = nil

    var body: some View {
        ZStack(alignment: .bottomLeading) {

            // Bakgrunn — varmt mørkt treverk-utseende
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.10, blue: 0.06),
                    Color(red: 0.22, green: 0.15, blue: 0.09)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Post-bilde — bruker pre-fetchet UIImage for synkron rendering
            if let uiImg = loadedImage {
                Image(uiImage: uiImg)
                    .resizable()
                    .scaledToFill()
                    .overlay(
                        LinearGradient(
                            colors: [.clear, Color.black.opacity(0.75)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 0) {

                // ── SEDER-logo + forfatter ────────────────────
                HStack {
                    Text("SEDER")
                        .font(.system(size: 15, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(.white)
                    Spacer()
                    Text(post.authorName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Spacer()

                // ── Sigar-info ────────────────────────────────
                if let name = post.cigarDisplayName {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)

                        if let label = post.cigarScoreLabel, let rating = post.cigarRating {
                            HStack(spacing: 6) {
                                Text("\(rating)")
                                    .font(.system(size: 22, weight: .black))
                                    .foregroundColor(Color(red: 0.95, green: 0.78, blue: 0.3))
                                Text("·")
                                    .foregroundColor(.white.opacity(0.5))
                                Text(label)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // ── Tekst-snippet ─────────────────────────────
                if let text = post.content, !text.isEmpty {
                    Text(text)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(2)
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                }

                // ── CTA-banner ────────────────────────────────
                HStack {
                    Text("Sjekk ut SEDER — sigar-appen")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text("vitola.app")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(red: 0.95, green: 0.78, blue: 0.3))
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 16)
            }
        }
        .frame(width: 375, height: 260)
    }
}

// MARK: - IOSShareSheet
// Wrapper for UIActivityViewController

struct IOSShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        // Bytt ut rå URL-er med en kilde som leverer ferdig LPLinkMetadata.
        // Uten dette henter iOS lenke-forhåndsvisningen over nett FØR arket
        // tegnes ferdig → merkbart lag. Med ferdig metadata åpner arket umiddelbart.
        let title = items.compactMap { $0 as? String }.first ?? "SEDER"
        let prepared: [Any] = items.map { item in
            if let url = item as? URL {
                return ShareLinkSource(url: url, title: title)
            }
            return item
        }
        return UIActivityViewController(activityItems: prepared, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Leverer lenke-metadata lokalt slik at UIActivityViewController slipper
// nettverkshentingen som ellers forsinker at delings-arket vises.
final class ShareLinkSource: NSObject, UIActivityItemSource {
    let url: URL
    let title: String

    init(url: URL, title: String) {
        self.url = url
        self.title = title
    }

    func activityViewControllerPlaceholderItem(_ controller: UIActivityViewController) -> Any { url }

    func activityViewController(_ controller: UIActivityViewController,
                                itemForActivityType activityType: UIActivity.ActivityType?) -> Any? { url }

    func activityViewControllerLinkMetadata(_ controller: UIActivityViewController) -> LPLinkMetadata? {
        let md = LPLinkMetadata()
        md.originalURL = url
        md.url = url
        md.title = title
        return md
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: ActivityView — hoved-tab (erstatter Feed)
// Scrollbar strøm av delte journal-hendelser. Ikke innlegg, ingen kommentarer.
// Hele raden → sigarens detaljside. «＋ ønskeliste» legger rett i ønskelisten.
// ═══════════════════════════════════════════════════════════

struct ActivityView: View {

    @EnvironmentObject var authService: AuthService
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var activityService = ActivityService()
    private let wishlistService = WishlistService()
    private let tastingService = TastingService()
    private let shareService = ShareService()
    private let friendService = FriendService()

    @State private var items: [ActivityItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var wishlisted: Set<UUID> = []
    @State private var selectedItem: ActivityItem?
    @State private var selectedAuthor: AuthorRef?
    @State private var showCompose = false
    @State private var pendingDelete: ActivityItem?   // eget innlegg som skal slettes
    @State private var externalShare: ExternalShareItem?   // «Del» fra «...»-menyen
    @State private var toast: String?   // kort bekreftelse (f.eks. venneforespørsel)

    var body: some View {
        NavigationStack {
            Group {
                if authService.userId == nil {
                    ActivityLoggedOutView()
                } else if isLoading && items.isEmpty {
                    ProgressView("Laster aktivitet…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color("Background"))
                } else if items.isEmpty {
                    ActivityEmptyView()
                } else {
                    list
                }
            }
            .background(Color("Background"))
            .navigationTitle("Aktivitet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("Background"), for: .navigationBar)
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { ProfileAvatarButton() }
                if authService.userId != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showCompose = true
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .foregroundColor(Color("TextPrimary"))
                        }
                        .accessibilityLabel("Nytt innlegg")
                    }
                }
            }
            .sheet(isPresented: $showCompose) {
                ComposePostView(onPosted: { await load() })
                    .environmentObject(authService)
            }
            .task { if items.isEmpty { await load() } }
            .refreshable { await load() }
            .overlay(alignment: .bottom) {
                if let toast {
                    Text(toast)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Capsule().fill(Color.black.opacity(0.85)))
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: toast)
        }
    }

    private var list: some View {
        List {
            ForEach(items) { item in
                Button {
                    selectedItem = item
                } label: {
                    ActivityRow(
                        item: item,
                        isWishlisted: wishlisted.contains(item.cigarId),
                        onWishlist: { addToWishlist(item) },
                        onAuthor: { selectedAuthor = AuthorRef(id: item.userId) },
                        onShare: { sharePost(item) },
                        onAddFriend: item.userId == authService.userId ? nil : { addFriend(item) },
                        onDelete: item.userId == authService.userId ? { pendingDelete = item } : nil
                    )
                    .frame(maxWidth: .infinity)   // tving label til full radbredde
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)       // tving selve Button-en til full bredde
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color("Background"))
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color("Background"))
        .alert("Slette innlegget?", isPresented: Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )) {
            Button("Slett", role: .destructive) {
                if let item = pendingDelete { deletePost(item) }
            }
            Button("Avbryt", role: .cancel) { pendingDelete = nil }
        } message: {
            Text("Innlegget fjernes fra Aktivitet og journalen din. Dette kan ikke angres.")
        }
        .sheet(item: $externalShare) { item in
            // Del tekst + lenke → FB-kort (bilde + «Navn · Vitola · rating» i tittelen).
            IOSShareSheet(items: [item.caption, item.url])
        }
        .navigationDestination(item: $selectedItem) { item in
            CigarDetailLoader(cigarId: item.cigarId)
        }
        .navigationDestination(item: $selectedAuthor) { ref in
            UserProfileView(userId: ref.id, isOwnProfile: false)
        }
    }

    private func load() async {
        guard authService.userId != nil else { isLoading = false; return }
        isLoading = true
        do {
            items = try await activityService.fetchActivity(limit: 40)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func addToWishlist(_ item: ActivityItem) {
        guard let userId = authService.userId, !wishlisted.contains(item.cigarId) else { return }
        wishlisted.insert(item.cigarId)   // optimistisk
        Task {
            do { try await wishlistService.addToWishlist(userId: userId, cigarId: item.cigarId) }
            catch { await MainActor.run { wishlisted.remove(item.cigarId) } }
        }
    }

    /// «Del» fra «...»-menyen: sørg for at oppføringen er delt eksternt (får slug),
    /// varm opp FB-cachen, og åpne delings-arket med tekst + lenke.
    private func sharePost(_ item: ActivityItem) {
        let name = [item.cigarBrand, item.cigarSeries].compactMap { $0 }.joined(separator: " ")
        let parts = [name, item.cigarVitola, item.cigarRating.map { "\($0)/100" }].compactMap { $0 }
        let caption = parts.joined(separator: " · ") + " på SEDER"

        // Rask vei: innlegget har allerede en offentlig slug → vis delings-arket
        // umiddelbart. Sørg for at ekstern-flagget er satt i bakgrunnen slik at
        // vi ikke blokkerer arket på et nettverkskall.
        if let slug = item.publicSlug, let url = shareService.publicURL(slug: slug) {
            shareService.primeFacebook(slug: slug)
            externalShare = ExternalShareItem(url: url, image: nil, caption: caption)
            Task { _ = try? await shareService.setSharing(entryId: item.entryId, community: true, external: true) }
            return
        }

        // Ingen slug ennå → må hente en fra serveren først.
        Task {
            do {
                let res = try await shareService.setSharing(entryId: item.entryId, community: true, external: true)
                guard let slug = res.publicSlug, let url = shareService.publicURL(slug: slug) else { return }
                shareService.primeFacebook(slug: slug)
                await MainActor.run {
                    externalShare = ExternalShareItem(url: url, image: nil, caption: caption)
                }
            } catch {
                print("Del innlegg feilet: \(error)")
            }
        }
    }

    /// «Legg til som venn» fra «...»-menyen: sender venneforespørsel til
    /// forfatteren (request_friendship-RPC), som på Facebook.
    private func addFriend(_ item: ActivityItem) {
        Task {
            do {
                try await friendService.requestFriendship(userId: item.userId)
                await MainActor.run { showToast("Venneforespørsel sendt til \(item.authorName)") }
            } catch {
                await MainActor.run { showToast("Kunne ikke sende forespørsel") }
            }
        }
    }

    private func showToast(_ text: String) {
        toast = text
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run { if toast == text { toast = nil } }
        }
    }

    /// Sletter forfatterens eget innlegg (tasting_log). RLS sikrer at kun eier
    /// kan slette. Fjernes optimistisk fra lista.
    private func deletePost(_ item: ActivityItem) {
        pendingDelete = nil
        Task {
            do {
                try await tastingService.deleteLog(id: item.entryId)
                await MainActor.run { items.removeAll { $0.entryId == item.entryId } }
            } catch {
                print("Slett innlegg feilet: \(error)")
                await MainActor.run { errorMessage = error.localizedDescription }
            }
        }
    }
}

// MARK: - ComposePostView
// «+» fra Aktivitet: søk opp en sigar → samme logg-ark (0–100 + notat + bilde)
// → post til journal + tilbud om deling. Gjenbruker searchCigars, SmokingLogSheet,
// logTastingForCigar og ShareAfterSaveSheet — ingen ny backend.
struct ComposePostView: View {

    var onPosted: () async -> Void = {}

    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    private let cigarService = CigarService()
    private let humidorService = HumidorService()

    @State private var searchQuery = ""
    @State private var searchResults: [Cigar] = []
    @State private var isSearching = false
    @State private var hasSearched = false

    // Valgt sigar → logg-ark
    @State private var logCigar: Cigar?
    // Del-etter-lagring
    @State private var sharePrompt: SharePrompt?
    @State private var externalShare: ExternalShareItem?
    @State private var pendingShareImageData: Data?
    @State private var pendingShareCaption: String = ""

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Søk opp en sigar å skrive om")) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color("TextSecondary"))
                        TextField("F.eks. Liga Privada, Padron…", text: $searchQuery)
                            .textInputAutocapitalization(.words)
                            .submitLabel(.search)
                            .onSubmit { Task { await runSearch() } }
                        if isSearching { ProgressView() }
                    }
                    .padding(.vertical, 4)

                    if hasSearched && searchResults.isEmpty && !isSearching {
                        Text("Ingen sigarer matchet «\(searchQuery)».")
                            .font(.caption).foregroundColor(Color("TextSecondary"))
                    }

                    ForEach(searchResults) { cigar in
                        Button { logCigar = cigar } label: {
                            CigarRow(cigar: cigar)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Nytt innlegg")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
            }
            // Steg 2: samme logg-ark som ellers i appen
            .sheet(item: $logCigar) { cigar in
                SmokingLogSheet(cigar: cigar, userId: authService.userId) { smokedAt, rating, smokeAgain, draw, burn, flavor, notes, photoData, cutType, store in
                    guard let userId = authService.userId else { return }
                    Task {
                        do {
                            let logId = try await humidorService.logTastingForCigar(
                                cigarId: cigar.id, userId: userId, smokedAt: smokedAt,
                                rating: rating, smokeAgain: smokeAgain, drawRating: draw,
                                burnRating: burn, flavorRating: flavor, notes: notes,
                                cutType: cutType, store: store)
                            if let data = photoData {
                                let ts = TastingService()
                                let url = try await ts.uploadLogPhoto(logId: logId, userId: userId, imageData: data)
                                try await ts.updateLog(
                                    id: logId, smokedAt: smokedAt, rating: rating,
                                    smokeAgain: smokeAgain, drawRating: draw, burnRating: burn,
                                    flavorRating: flavor, personalNotes: notes, photoUrl: url)
                            }
                            await onPosted()
                            await MainActor.run {
                                pendingShareImageData = photoData
                                pendingShareCaption = "\(cigar.fullName)" + (rating.map { " · \($0)/100" } ?? "") + " på SEDER"
                                sharePrompt = SharePrompt(entryId: logId)
                            }
                        } catch { print("Compose-logg feil: \(error)") }
                    }
                }
            }
            .sheet(item: $sharePrompt) { prompt in
                ShareAfterSaveSheet(entryId: prompt.entryId) { url in
                    let img = pendingShareImageData.flatMap { UIImage(data: $0) }
                    externalShare = ExternalShareItem(url: url, image: img, caption: pendingShareCaption)
                }
            }
            .sheet(item: $externalShare) { item in
                // Del tekst + lenke (ikke bildefila) → Facebook lager rikt kort fra
                // lenken (bilde + «Navn · Vitola · rating» i tittelen).
                IOSShareSheet(items: [item.caption, item.url])
            }
        }
    }

    private func runSearch() async {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { searchResults = []; hasSearched = false; return }
        isSearching = true; hasSearched = true
        do { searchResults = try await cigarService.searchCigars(query: query) }
        catch { searchResults = [] }
        isSearching = false
    }
}

// MARK: - ActivityRow
struct ActivityRow: View {

    let item: ActivityItem
    var isWishlisted: Bool
    var onWishlist: () -> Void
    var onAuthor: () -> Void = {}
    var onShare: () -> Void = {}
    var onAddFriend: (() -> Void)? = nil   // nil = eget innlegg (skjul «Legg til som venn»)
    var onDelete: (() -> Void)? = nil      // nil = ikke eget innlegg (skjul Slett)

    private var verbText: String {
        item.verb == "wishlist" ? "vil prøve" : "delte en sigar"
    }
    /// 0–100 → 0–5 (avrundet), til «Min vurdering (X/5)».
    private var stars: Int { Int((Double(item.cigarRating ?? 0) / 20.0).rounded()) }
    private var initials: String {
        let s = item.authorName.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined()
        return s.isEmpty ? "?" : s.uppercased()
    }

    var body: some View {
        VStack(spacing: 0) {
            // 1. Hvem + verb — avatar+navn er trykkbart inn til posterens profil
            HStack(spacing: 6) {
                Button(action: onAuthor) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle().fill(Color("Accent"))
                            Text(initials).font(.system(size: 12, weight: .medium)).foregroundColor(.white)
                        }
                        .frame(width: 28, height: 28)
                        Text(item.authorName).font(.system(size: 13, weight: .semibold)).foregroundColor(Color("TextPrimary"))
                    }
                }
                .buttonStyle(.borderless)
                Text(verbText).font(.system(size: 13, weight: .medium)).foregroundColor(Color("TextSecondary"))
                Spacer(minLength: 0)
                // «...»-meny øverst til høyre
                Menu {
                    if let onAddFriend {
                        Button { onAddFriend() } label: {
                            Label("Legg til som venn", systemImage: "person.badge.plus")
                        }
                    }
                    Button { onShare() } label: {
                        Label("Del", systemImage: "square.and.arrow.up")
                    }
                    if let onDelete {
                        Button(role: .destructive) { onDelete() } label: {
                            Label("Slett", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color("TextSecondary"))
                        .frame(width: 34, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .overlay(alignment: .bottom) { Rectangle().fill(Color("Background")).frame(height: 1) }

            // 2. Sigar + «Lagre i liste»
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.cigarBrand)
                        .font(.system(size: 16, weight: .semibold)).foregroundColor(Color("TextPrimary"))
                    if !item.cigarMetaLine.isEmpty {
                        Text(item.cigarMetaLine)
                            .font(.system(size: 12, weight: .medium)).foregroundColor(Color("TextSecondary"))
                    }
                }
                Spacer(minLength: 8)
                Button(action: onWishlist) {
                    HStack(spacing: 5) {
                        Text(isWishlisted ? "Lagret" : "Lagre i liste").font(.system(size: 13, weight: .medium))
                        Image(systemName: isWishlisted ? "bookmark.fill" : "bookmark").font(.system(size: 18))
                    }
                    .foregroundColor(Color("TextPrimary"))
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)

            // 3. Bilde — kant-til-kant. Fast full-bredde-boks (Color.clear) som
            // bildet fyller via overlay + clipped, så bildet ALDRI dytter kortet
            // bredere enn raden (ellers ble bilde-kort bredere enn tekst-kort).
            if let photo = item.tastingPhotoUrl, let url = URL(string: photo) {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 240)
                    .overlay {
                        KFImage(url).resizable().scaledToFill()
                    }
                    .clipped()
            }

            // 4. Min vurdering
            if item.verb != "wishlist", let r = item.cigarRating, r > 0 {
                HStack {
                    Text("Min vurdering (\(stars)/5)")
                        .font(.system(size: 14, weight: .semibold)).foregroundColor(Color("TextPrimary"))
                    Spacer(minLength: 0)
                    StarRow(filled: stars)
                }
                .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 10)
            }

            // 5. Notat
            if let note = item.personalNotes, !note.isEmpty {
                HStack {
                    Text(note)
                        .font(.system(size: 13)).lineSpacing(2).foregroundColor(Color("TextPrimary"))
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14).padding(.top, 2).padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("Card"))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
    }
}

/// Identifiable-wrapper for navigasjon til en forfatters profil (bli venner).
struct AuthorRef: Identifiable, Hashable { let id: UUID }

// MARK: - Stjerne-rad for Aktivitet (X av 5)
private struct StarRow: View {
    let filled: Int   // 0...5
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { i in
                Image(systemName: i < filled ? "star.fill" : "star")
                    .font(.system(size: 15))
                    .foregroundColor(i < filled ? Color("Accent") : Color("TextSecondary").opacity(0.35))
            }
        }
    }
}

// Laster en sigar via id og viser detaljsiden (Aktivitet har bare cigar_id).
struct CigarDetailLoader: View {
    let cigarId: UUID
    private let cigarService = CigarService()
    @State private var cigar: Cigar?
    @State private var failed = false
    var body: some View {
        Group {
            if let cigar {
                CigarDetailViewDesign(cigar: cigar)
            } else if failed {
                Text("Kunne ikke laste sigaren.")
                    .foregroundColor(Color("TextSecondary"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color("Background"))
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color("Background"))
            }
        }
        .task {
            do { cigar = try await cigarService.fetchCigar(id: cigarId) }
            catch { failed = true }
        }
    }
}

private struct ActivityEmptyView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 54)).foregroundColor(Color("TextSecondary").opacity(0.5))
            Text("Ingen aktivitet ennå").font(.title3.bold())
            Text("Del et journalinnlegg, eller finn nye sigarer i Utforsk.")
                .font(.subheadline).foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity).padding(32).background(Color("Background"))
    }
}

private struct ActivityLoggedOutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2")
                .font(.system(size: 48)).foregroundColor(Color("TextSecondary").opacity(0.5))
            Text("Logg inn for å se aktivitet")
                .font(.title3.bold()).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity).padding(32).background(Color("Background"))
    }
}
