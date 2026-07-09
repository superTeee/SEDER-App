import Foundation

// MARK: - attempt
//
// `try?` kaster feilen rett i søpla. Det er nettopp derfor ingen oppdaget at
// tabellen `cigar_barcodes` aldri hadde blitt opprettet: appen sendte lydig
// hvert eneste kall, Supabase svarte «denne tabellen finnes ikke», og `try?`
// kastet svaret. Fra utsiden så alt riktig ut.
//
// `attempt` gjør det samme som `try?` — kallet feiler stille for brukeren, og
// flyten går videre — men årsaken havner i konsollen i stedet for ingensteds.
//
// Bruk:
//     await attempt("Legg i humidor") {
//         try await humidorService.addToHumidor(...)
//     }
//
// Returnerer nil ved feil, akkurat som `try?`, så kallstedet kan fortsatt
// skrive `if let entry = await attempt(...) { … }`.

@discardableResult
func attempt<T>(_ label: String, _ operation: () async throws -> T) async -> T? {
    do {
        return try await operation()
    } catch {
        print("⚠️ \(label) feilet: \(error)")
        return nil
    }
}
