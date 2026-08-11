import SwiftUI

// MARK: - SupportPromptManager
//
// Én sentral hjerne for NÅR bidra-/Pro-skjermen skal poppe opp.
// To innganger, samme skjerm:
//
//   1) MYK  (bidra-modus)   – kommer av seg selv etter litt tid i appen,
//                             på et "godt øyeblikk" (etter en journalføring o.l.)
//   2) HARD (lås opp-modus) – kommer når brukeren treffer humidor-grensen (3. humidor)
//
// Alt av tellere/flagg ligger i UserDefaults via @AppStorage, så det
// overlever app-restart. hasPro speiles fra StoreKit (se note nederst).

@MainActor
final class SupportPromptManager: ObservableObject {

    static let shared = SupportPromptManager()

    // MARK: Lagrede flagg (overlever restart)
    @AppStorage("hasPro")            private var hasPro: Bool = false          // eier livstidslåsen
    @AppStorage("hasContributed")    private var hasContributed: Bool = false  // har gitt tips
    @AppStorage("sessionCount")      private var sessionCount: Int = 0         // antall øktstarter
    @AppStorage("softPromptCount")   private var softPromptCount: Int = 0      // myke prompts vist (livstid)
    @AppStorage("lastSoftPrompt")    private var lastSoftPrompt: Double = 0    // tidspunkt sist myk prompt

    // MARK: Justerbare regler (én plass å skru på)
    private let minSessionsBeforeSoft = 3      // ikke mas før 3. økt
    private let softCooldownDays: Double = 24    // minst ~3–4 uker mellom myke prompts
    private let maxSoftPromptsLifetime = 3     // aldri mer enn 3 myke prompts totalt
    private let freeHumidorLimit       = 2     // gratis = 2 humidorer

    // Hva slags skjerm skal vises (eller ingen)
    enum Mode { case soft, unlock, none }

    // Hva som skjer i denne økten (så vi ikke maser to ganger samme økt)
    private var shownThisSession = false


    // MARK: 1) Kall denne når appen åpnes / kommer i forgrunn
    func appDidBecomeActive() {
        sessionCount += 1
        shownThisSession = false
    }

    // MARK: 2) MYK inngang – kall på et "godt øyeblikk"
    // f.eks. rett etter at en journalføring er lagret, eller en sigar lagt i humidor.
    // Returnerer .soft hvis skjermen bør vises nå, ellers .none.
    func softMomentReached() -> Mode {
        guard !hasPro, !hasContributed else { return .none }        // eier Pro / har bidratt → aldri
        guard !shownThisSession else { return .none }               // maks én gang per økt
        guard sessionCount >= minSessionsBeforeSoft else { return .none }
        guard softPromptCount < maxSoftPromptsLifetime else { return .none }
        guard daysSince(lastSoftPrompt) >= softCooldownDays else { return .none }

        return .soft
    }

    // MARK: 3) HARD inngang – kall når brukeren trykker "Ny humidor"
    // currentCount = hvor mange humidorer brukeren allerede har.
    // Returnerer .unlock (blokker + vis Pro) eller .none (slipp gjennom).
    func humidorCreationAttempt(currentCount: Int) -> Mode {
        if hasPro { return .none }                                  // Pro → ubegrenset
        return currentCount >= freeHumidorLimit ? .unlock : .none   // 2 fra før → gate
    }


    // MARK: Registrer at en skjerm faktisk ble vist
    func markShown(_ mode: Mode) {
        shownThisSession = true
        if mode == .soft {
            softPromptCount += 1
            lastSoftPrompt = now()
        }
        // .unlock teller vi ikke ned på – den skal komme hver gang man står ved grensen
    }

    // Kall disse når kjøp/tips fullføres (fra StoreKit-laget)
    func didUnlockPro()   { hasPro = true }
    func didContribute()  { hasContributed = true }

    // MARK: Småhjelpere (tid)
    private func now() -> Double { Date().timeIntervalSince1970 }
    private func daysSince(_ t: Double) -> Double {
        guard t > 0 else { return .greatestFiniteMagnitude }        // aldri vist → "uendelig lenge siden"
        return (now() - t) / 86_400
    }
}
