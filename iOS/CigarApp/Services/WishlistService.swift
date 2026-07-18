import Foundation
import Supabase

// MARK: - WishlistService
// Håndterer alle database-kall mot "wishlist"-tabellen

@MainActor
class WishlistService: ObservableObject {

    // MARK: - Hent alle ønskeliste-sigarer for innlogget bruker

    func fetchWishlist(userId: UUID) async throws -> [Cigar] {
        // Henter wishlist-rader med cigar-data embedded via foreign key
        struct WishlistRow: Decodable {
            let cigarId: UUID
            let createdAt: Date
            let cigars: Cigar

            enum CodingKeys: String, CodingKey {
                case cigarId   = "cigar_id"
                case createdAt = "created_at"
                case cigars
            }
        }

        let rows: [WishlistRow] = try await supabase
            .from("wishlist")
            .select("cigar_id, created_at, cigars(*)")
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return rows.map { $0.cigars }
    }

    // MARK: - Legg til sigar i ønskeliste

    func addToWishlist(userId: UUID, cigarId: UUID) async throws {
        struct NewWishlistItem: Encodable {
            let userId: UUID
            let cigarId: UUID

            enum CodingKeys: String, CodingKey {
                case userId  = "user_id"
                case cigarId = "cigar_id"
            }
        }

        try await supabase
            .from("wishlist")
            .insert(NewWishlistItem(userId: userId, cigarId: cigarId))
            .execute()
    }

    // MARK: - Fjern sigar fra ønskeliste

    func removeFromWishlist(userId: UUID, cigarId: UUID) async throws {
        try await supabase
            .from("wishlist")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .eq("cigar_id", value: cigarId.uuidString)
            .execute()
    }

    // MARK: - Sjekk om sigar er i ønskeliste

    func isInWishlist(userId: UUID, cigarId: UUID) async throws -> Bool {
        struct IdRow: Decodable { let id: UUID }
        let result: [IdRow] = try await supabase
            .from("wishlist")
            .select("id")
            .eq("user_id", value: userId.uuidString)
            .eq("cigar_id", value: cigarId.uuidString)
            .limit(1)
            .execute()
            .value

        return !result.isEmpty
    }
}

// MARK: - FavoriteListItem
// Én favoritt slik den vises på profilen (navn + vitola nå; rating/butikk kan legges på senere).

struct FavoriteListItem: Identifiable, Decodable {
    var id: UUID { cigarId }
    let cigarId: UUID
    let brand: String
    let series: String?
    let vitola: String?

    enum CodingKeys: String, CodingKey {
        case cigarId = "cigar_id"
        case brand, series, vitola
    }
}

// MARK: - FavoriteService
// Håndterer "favorites"-tabellen — stjernemerkede sigarer (flere tillatt).

@MainActor
class FavoriteService: ObservableObject {

    // Full liste med cigar-data (egen bruker) — brukes i Humidor-fanen.
    func fetchFavorites(userId: UUID) async throws -> [Cigar] {
        struct FavoriteRow: Decodable {
            let cigars: Cigar
        }
        let rows: [FavoriteRow] = try await supabase
            .from("favorites")
            .select("cigar_id, created_at, cigars(*)")
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        return rows.map { $0.cigars }
    }

    // Favorittliste for egen eller venns profil (navn + vitola) via RPC med vennskaps-sjekk.
    func fetchFavoriteList(userId: UUID) async throws -> [FavoriteListItem] {
        try await supabase
            .rpc("get_favorites", params: ["p_user_id": userId.uuidString])
            .execute()
            .value
    }

    func addFavorite(userId: UUID, cigarId: UUID) async throws {
        struct NewFavorite: Encodable {
            let userId: UUID
            let cigarId: UUID
            enum CodingKeys: String, CodingKey {
                case userId  = "user_id"
                case cigarId = "cigar_id"
            }
        }
        try await supabase
            .from("favorites")
            .insert(NewFavorite(userId: userId, cigarId: cigarId))
            .execute()
    }

    func removeFavorite(userId: UUID, cigarId: UUID) async throws {
        try await supabase
            .from("favorites")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .eq("cigar_id", value: cigarId.uuidString)
            .execute()
    }

    func isFavorite(userId: UUID, cigarId: UUID) async throws -> Bool {
        struct IdRow: Decodable { let id: UUID }
        let result: [IdRow] = try await supabase
            .from("favorites")
            .select("id")
            .eq("user_id", value: userId.uuidString)
            .eq("cigar_id", value: cigarId.uuidString)
            .limit(1)
            .execute()
            .value
        return !result.isEmpty
    }
}
