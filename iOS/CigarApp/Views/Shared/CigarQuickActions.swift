import SwiftUI

// MARK: - CigarQuickActions
// Gjenbrukbar long-press-hurtigmeny for et listeelement som representerer en sigar.
// Handlinger: Legg i humidor · Loggfør sigar · Legg i ønskeliste · Del.
// Bruk: .cigarQuickActions(cigar) på en rad/kort (f.eks. en NavigationLink).

struct CigarQuickActions: ViewModifier {
    let cigar: Cigar
    @EnvironmentObject var authService: AuthService

    @State private var showAddHumidor = false
    @State private var showLogSmoked = false
    @State private var showLogin = false
    @State private var sharePrompt: SharePrompt?
    @State private var externalShare: ExternalShareItem?
    @State private var pendingShareCaption = ""

    private let humidorService = HumidorService()
    private let wishlistService = WishlistService()
    private let tastingService = TastingService()

    private var shareText: String {
        var parts = [cigar.brand]
        if let s = cigar.series, !s.isEmpty { parts.append(s) }
        if let v = cigar.vitola, !v.isEmpty { parts.append(v) }
        return parts.joined(separator: " ") + " — sjekk ut denne sigaren i SEDER"
    }

    func body(content: Content) -> some View {
        content
            // Gjør hele raden trykkbar for long-press, ikke bare tekst-pikslene.
            .contentShape(.contextMenuPreview, Rectangle())
            .contentShape(Rectangle())
            .contextMenu {
                Button { requireLogin { showAddHumidor = true } } label: {
                    Label("Legg i humidor", systemImage: "archivebox")
                }
                Button { requireLogin { showLogSmoked = true } } label: {
                    Label("Loggfør sigar", systemImage: "square.and.pencil")
                }
                Button { requireLogin { addToWishlist() } } label: {
                    Label("Legg i ønskeliste", systemImage: "bookmark")
                }
                ShareLink(item: shareText) {
                    Label("Del", systemImage: "square.and.arrow.up")
                }
            }
            .sheet(isPresented: $showAddHumidor) {
                AddToHumidorSheet(cigar: cigar, userId: authService.userId) { purchasedAt, addedAt, qty, humidorId, store, price in
                    guard let uid = authService.userId else { return }
                    Task {
                        await attempt("Legg i humidor") {
                            try await humidorService.addToHumidor(
                                cigarId: cigar.id, userId: uid, humidorId: humidorId,
                                quantity: qty, purchasedAt: purchasedAt, addedToHumidorAt: addedAt, store: store, purchasePrice: price)
                        }
                    }
                }
            }
            .sheet(isPresented: $showLogSmoked) {
                SmokingLogSheet(cigar: cigar, userId: authService.userId) { smokedAt, rating, smokeAgain, draw, burn, flavor, notes, photoData, cutType, store in
                    guard let uid = authService.userId else { return }
                    Task {
                        let logId = await attempt("Loggfør sigar") {
                            try await humidorService.logTastingForCigar(
                                cigarId: cigar.id, userId: uid, smokedAt: smokedAt, rating: rating,
                                smokeAgain: smokeAgain, drawRating: draw, burnRating: burn,
                                flavorRating: flavor, notes: notes, cutType: cutType, store: store)
                        }
                        if let logId, let data = photoData {
                            await attempt("Last opp loggbilde") {
                                // Persistér photo_url — uploadLogPhoto lagrer den ikke selv.
                                let url = try await tastingService.uploadLogPhoto(logId: logId, userId: uid, imageData: data)
                                try await tastingService.updateLog(
                                    id: logId, smokedAt: smokedAt, rating: rating,
                                    smokeAgain: smokeAgain, drawRating: draw, burnRating: burn,
                                    flavorRating: flavor, personalNotes: notes, photoUrl: url)
                            }
                        }
                        // Tilby deling etter logging — som på detaljsiden.
                        if let logId {
                            await MainActor.run {
                                pendingShareCaption = cigar.fullName
                                    + (rating.map { " · \($0)/100" } ?? "") + " på SEDER"
                                sharePrompt = SharePrompt(entryId: logId)
                            }
                        }
                    }
                }
            }
            .sheet(item: $sharePrompt) { prompt in
                ShareAfterSaveSheet(entryId: prompt.entryId) { url in
                    externalShare = ExternalShareItem(url: url, image: nil, caption: pendingShareCaption)
                }
            }
            .sheet(item: $externalShare) { item in
                IOSShareSheet(items: [item.caption, item.url])
            }
            .sheet(isPresented: $showLogin) { AuthView() }
    }

    private func requireLogin(_ action: @escaping () -> Void) {
        if authService.userId == nil { showLogin = true } else { action() }
    }

    private func addToWishlist() {
        guard let uid = authService.userId else { return }
        Task {
            await attempt("Legg i ønskeliste") {
                try await wishlistService.addToWishlist(userId: uid, cigarId: cigar.id)
            }
            await MainActor.run {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
}

extension View {
    /// Legger til long-press-hurtigmeny med sigar-handlinger på et listeelement.
    func cigarQuickActions(_ cigar: Cigar) -> some View {
        modifier(CigarQuickActions(cigar: cigar))
    }
}
