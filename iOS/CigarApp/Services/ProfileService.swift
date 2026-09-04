import Foundation
import Supabase

// MARK: - ProfileService
// Henter profil-data for innlogget bruker og venner.

@MainActor
class ProfileService: ObservableObject {

    // MARK: - Hent egen profil med stats

    struct OwnStats {
        let cigarCount: Int
        let humidorCount: Int
        let friendCount: Int
    }

    func fetchOwnProfile(userId: UUID) async throws -> Profile {
        let profile: Profile = try await supabase
            .from("profiles")
            .select("id, display_name, friend_code, avatar_url, city, country, created_at, is_founding_member")
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
        return profile
    }

    func fetchOwnStats(userId: UUID) async throws -> OwnStats {
        async let cigars: [TastingLogCount] = supabase
            .from("tasting_logs")
            .select("id", head: false)
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        async let humidors: [HumidorCount] = supabase
            .from("humidor")
            .select("id", head: false)
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        async let friends: [FriendCount] = supabase
            .from("friendships")
            .select("id", head: false)
            .eq("status", value: "accepted")
            .or("requester_id.eq.\(userId.uuidString),recipient_id.eq.\(userId.uuidString)")
            .execute()
            .value

        let (c, h, f) = try await (cigars, humidors, friends)
        return OwnStats(cigarCount: c.count, humidorCount: h.count, friendCount: f.count)
    }

    // MARK: - Aggregert statistikk (innsikt-side)

    func fetchUserStats() async throws -> UserStats {
        try await supabase
            .rpc("get_user_stats")
            .execute()
            .value
    }

    /// Tildel/hent founding-medlemsnummer. nil = tidlig tester (utenfor de 100).
    /// Kaster ved nettverks-/serverfeil (så kalleren kan prøve igjen senere).
    func claimFoundingNumber() async throws -> Int? {
        try await supabase.rpc("claim_founding_number").execute().value
    }

    // MARK: - Hent venn sin profil via RPC

    func fetchFriendProfile(userId: UUID) async throws -> FriendProfile {
        let result: FriendProfile = try await supabase
            .rpc("get_friend_profile", params: ["p_user_id": userId.uuidString])
            .execute()
            .value
        return result
    }

    // MARK: - Hent offentlige humidorer for en venn

    func fetchPublicHumidorEntries(userId: UUID) async throws -> [HumidorEntry] {
        let entries: [HumidorEntry] = try await supabase
            .from("humidor")
            .select("*, cigars(*)")
            .eq("user_id", value: userId.uuidString)
            .eq("is_public", value: true)
            .order("created_at", ascending: false)
            .execute()
            .value
        return entries
    }

    // MARK: - Hent siste journal-innlegg

    /// Kun for innlogget bruker. RLS på `tasting_logs` tillater bare `auth.uid() = user_id`,
    /// så et kall med en annen brukers ID returnerer alltid en tom liste.
    func fetchRecentLogs(userId: UUID, limit: Int = 5) async throws -> [TastingLog] {
        let logs: [TastingLog] = try await supabase
            .from("tasting_logs")
            .select("*, cigars(*)")
            .eq("user_id", value: userId.uuidString)
            .order("smoked_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        return logs
    }

    // MARK: - Oppdater egen profil

    func saveBio(userId: UUID, bio: String) async throws {
        try await supabase
            .from("profiles")
            .update(["bio": bio])
            .eq("id", value: userId.uuidString)
            .execute()
    }

    func updateProfile(userId: UUID, displayName: String?, city: String?, country: String? = nil) async throws {
        var updates: [String: String] = [:]
        if let name = displayName { updates["display_name"] = name }
        if let c = city { updates["city"] = c }
        if let co = country { updates["country"] = co }
        guard !updates.isEmpty else { return }

        try await supabase
            .from("profiles")
            .update(updates)
            .eq("id", value: userId.uuidString)
            .execute()
    }

    // MARK: - Smaksprofil (aggregerte favoritter)

    func fetchOwnFavorites() async throws -> ProfileFavorites? {
        let rows: [ProfileFavorites] = try await supabase
            .rpc("get_own_profile_favorites")
            .execute()
            .value
        return rows.first
    }

    // MARK: - Last opp profilbilde

    func uploadAvatar(userId: UUID, imageData: Data) async throws -> String {
        // VIKTIG: auth.uid()::text i Postgres er små bokstaver — path MÅ
        // være lowercase, ellers feiler RLS-policyen.
        let path = "\(userId.uuidString.lowercased())/avatar.jpg"
        let data = downscaledJPEG(imageData, maxDim: 800)
        try await supabase.storage
            .from("avatars")
            .upload(path, data: data, options: FileOptions(
                cacheControl: "3600",
                contentType: "image/jpeg",
                upsert: true
            ))
        let publicURL = try supabase.storage
            .from("avatars")
            .getPublicURL(path: path)

        // Cache-buster så AsyncImage ikke bruker gammelt bilde etter endring
        var urlString = publicURL.absoluteString
        if var components = URLComponents(url: publicURL, resolvingAgainstBaseURL: false) {
            components.queryItems = [URLQueryItem(name: "v", value: "\(Int(Date().timeIntervalSince1970))")]
            if let url = components.url { urlString = url.absoluteString }
        }

        try await supabase
            .from("profiles")
            .update(["avatar_url": urlString])
            .eq("id", value: userId.uuidString)
            .execute()
        return urlString
    }

    // MARK: - Last opp toppbilde (cover)

    func uploadCover(userId: UUID, imageData: Data) async throws -> String {
        let path = "\(userId.uuidString.lowercased())/cover.jpg"
        let data = downscaledJPEG(imageData, maxDim: 1200, quality: 0.7)
        try await supabase.storage
            .from("avatars")
            .upload(path, data: data, options: FileOptions(
                cacheControl: "3600",
                contentType: "image/jpeg",
                upsert: true
            ))
        let publicURL = try supabase.storage
            .from("avatars")
            .getPublicURL(path: path)

        var urlString = publicURL.absoluteString
        if var components = URLComponents(url: publicURL, resolvingAgainstBaseURL: false) {
            components.queryItems = [URLQueryItem(name: "v", value: "\(Int(Date().timeIntervalSince1970))")]
            if let url = components.url { urlString = url.absoluteString }
        }

        try await supabase
            .from("profiles")
            .update(["cover_url": urlString])
            .eq("id", value: userId.uuidString)
            .execute()
        return urlString
    }
}

// Hjelpere for telling (trenger bare id-feltet)
private struct TastingLogCount: Decodable { let id: UUID }
private struct HumidorCount:    Decodable { let id: UUID }
private struct FriendCount:     Decodable { let id: UUID }
