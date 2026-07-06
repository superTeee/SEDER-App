import Foundation
import Supabase

// MARK: - FriendService
// Håndterer venner og venneforespørsler.
//
// Selve oppslag/innsending går via RPC-funksjoner i Supabase
// (se migrations/003_friends.sql) — de kjører med utvidede rettigheter
// (security definer) kun for de spesifikke formålene (finne bruker via
// kode, sende forespørsel, liste venner+forespørsler med navn), uten å
// åpne opp profiles-tabellen generelt. Godta/avslå/fjern går derimot
// rett mot friendships-tabellen, fordi RLS-policyene der allerede gir
// nøyaktig riktig tilgang (kun de to involverte partene).

@MainActor
class FriendService: ObservableObject {

    // Hent egen profil (for å vise/dele venne-koden)
    func fetchMyProfile(userId: UUID) async throws -> Profile {
        let result: Profile = try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value

        return result
    }

    // Hent venner + innkommende/utgående forespørsler i ett kall
    func fetchFriendsAndRequests() async throws -> [FriendEntry] {
        let results: [FriendEntry] = try await supabase
            .rpc("get_friends_and_requests")
            .execute()
            .value

        return results
    }

    // Send venneforespørsel via kode. Kaster en feil med norsk
    // beskrivelse (fra Postgres-funksjonen) hvis koden er ugyldig,
    // tilhører deg selv, eller dere allerede er venner/har en
    // forespørsel liggende.
    func sendFriendRequest(code: String) async throws {
        try await supabase
            .rpc("send_friend_request", params: FriendCodeParam(pCode: code))
            .execute()
    }

    // Godta eller avslå en innkommende forespørsel
    func respondToRequest(friendshipId: UUID, accept: Bool) async throws {
        try await supabase
            .from("friendships")
            .update(["status": accept ? "accepted" : "declined"])
            .eq("id", value: friendshipId.uuidString)
            .execute()
    }

    // Søk etter brukere via display_name (ILIKE) eller eksakt kode-treff
    func searchUsers(query: String) async throws -> [UserSearchResult] {
        let results: [UserSearchResult] = try await supabase
            .rpc("search_users", params: SearchQueryParam(pQuery: query))
            .execute()
            .value
        return results
    }

    // Fjern en venn, eller avbryt en forespørsel du selv har sendt
    func removeFriendship(friendshipId: UUID) async throws {
        try await supabase
            .from("friendships")
            .delete()
            .eq("id", value: friendshipId.uuidString)
            .execute()
    }
}
