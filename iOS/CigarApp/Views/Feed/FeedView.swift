import SwiftUI
import PhotosUI
import Kingfisher

// MARK: - FeedView
// Sosial feed — poster fra deg selv og venner.
// Inneholder: FeedView, FeedPostCard, CreatePostView, PostDetailView, VitolaSharingCard

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
            .navigationBarTitleDisplayMode(.large)
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
            LazyVStack(spacing: 12) {
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
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
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
                AvatarView(url: post.authorAvatarUrl, name: post.authorName, size: 36)
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

            // ── Bilde ────────────────────────────────────────
            let photoUrl = post.imageUrl ?? post.tastingPhotoUrl
            if let urlStr = photoUrl, let url = URL(string: urlStr) {
                Group {
                    KFImage(url)
                        .resizable()
                        .placeholder {
                            Rectangle().fill(Color("Surface")).frame(height: 220)
                                .overlay(ProgressView())
                        }
                        .fade(duration: 0.15)
                        .scaledToFill()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipped()
                .padding(.bottom, 8)
            }

            // ── Tekst ─────────────────────────────────────────
            if let text = post.content, !text.isEmpty {
                Text(text)
                    .font(.system(size: 15))
                    .foregroundColor(Color("TextPrimary"))
                    .lineLimit(5)
                    .padding(.horizontal, 14)
                    .padding(.top, 4)
                    .padding(.bottom, 14)
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
                    VitolaSharingSheet(post: post)
                }
            }
            .padding(.horizontal, 6)
        }
        .background(Color("Card"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
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
                        photoImage
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
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
                        Group {
                            KFImage(url)
                                .resizable()
                                .fade(duration: 0.15)
                                .scaledToFill()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 240)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    if let text = post.content, !text.isEmpty {
                        Text(text).font(.body).foregroundColor(Color("TextPrimary"))
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
// MARK: VitolaSharingSheet — del innlegg
// ═══════════════════════════════════════════════════════════
// Viser en branded Vitola-kort som bilde, og lar brukeren dele
// via iOS share sheet (Facebook, Instagram, Messages osv.)

struct VitolaSharingSheet: View {

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
                VitolaBrandedCard(post: post, loadedImage: loadedPostImage)
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
        let card = VitolaBrandedCard(post: post, loadedImage: loadedPostImage)
            .frame(width: 375, height: 260)

        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0 // retina
        return renderer.uiImage ?? UIImage()
    }
}

// MARK: - VitolaBrandedCard
// Det branded kortet som deles. Viser sigar, score, tekst og Vitola-logo.

struct VitolaBrandedCard: View {

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

                // ── Vitola-logo + forfatter ────────────────────
                HStack {
                    HStack(spacing: 6) {
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                        Text("Vitola")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
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
                    Text("Sjekk ut Vitola — sigar-appen")
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
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
