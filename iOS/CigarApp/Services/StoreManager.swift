import StoreKit
import Supabase

// MARK: - StoreManager (StoreKit 2)
//
// Ansvar: snakke med Apple om kjøp, og fortelle SupportPromptManager
// hva brukeren eier. To typer produkt:
//
//   • SEDER Pro  = Non-Consumable  → livstidslås. Ligger i currentEntitlements
//                                     for alltid → FASIT på hasPro.
//   • Tips       = Consumable      → forsvinner etter kjøp. Kommer ALDRI tilbake
//                                     i currentEntitlements, kan ikke "gjenopprettes".
//                                     Vi husker den bare lokalt (hasContributed).
//
// Analogi: Pro er en nøkkel du eier (Apple husker den). Et tips er en kaffe du
// spanderte – det er borte i det øyeblikket, og skal ikke "gjenopprettes".

@MainActor
final class StoreManager: ObservableObject {

    static let shared = StoreManager()

    // Produkt-ID-ene fra App Store Connect (bytt til dine faktiske ID-er)
    static let proID   = "no.sederappen.pro.lifetime"
    static let tipIDs  = ["no.sederappen.tip.small",   // 19 kr
                          "no.sederappen.tip.medium",  // 49 kr
                          "no.sederappen.tip.large"]   // 99 kr

    @Published var pro: Product?          // selve Pro-produktet (pris/navn fra Apple)
    @Published var tips: [Product] = []   // de tre tips-produktene
    @Published var isPro = false          // speiles til SupportPromptManager

    private var updatesTask: Task<Void, Never>?

    // MARK: Oppstart – kall én gang når appen starter
    func start() {
        updatesTask = listenForTransactions()      // fang kjøp gjort utenfor appen
        Task {
            await loadProducts()
            await refreshEntitlements()             // ← setter hasPro riktig ved oppstart
        }
    }

    // MARK: Last inn produktinfo (pris, navn) fra Apple
    private func loadProducts() async {
        do {
            let all = try await Product.products(for: [Self.proID] + Self.tipIDs)
            pro  = all.first { $0.id == Self.proID }
            tips = Self.tipIDs.compactMap { id in all.first { $0.id == id } }  // beholder rekkefølgen
        } catch {
            print("Kunne ikke laste produkter: \(error)")
        }
    }

    // MARK: FASIT – hvem eier Pro? (Non-Consumable ligger her for alltid)
    func refreshEntitlements() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let t) = result else { continue }   // hopp over usignerte
            if t.productID == Self.proID { owned = true }
        }
        isPro = owned
        ProManager.shared.storeOwnsPro = owned                       // speil til Pro-gate i appen
        if owned { SupportPromptManager.shared.didUnlockPro() }      // → hasPro = true
        await syncProStatus(owned)                                   // speil til profilen (admin-innsikt)
    }

    // MARK: Kjøp Pro (livstidslås)
    func buyPro() async {
        guard let pro else { return }
        await purchase(pro) { [weak self] in
            self?.isPro = true
            ProManager.shared.storeOwnsPro = true                    // speil til Pro-gate i appen
            SupportPromptManager.shared.didUnlockPro()               // lås opp humidorer m.m.
        }
        if isPro { await syncProStatus(true) }                       // speil til profilen (admin-innsikt)
    }

    // MARK: Gi tips (consumable)
    func buyTip(_ product: Product) async {
        await purchase(product) {
            SupportPromptManager.shared.didContribute()             // slutt å spørre om bidrag
        }
    }

    // Felles kjøps-flyt for begge
    private func purchase(_ product: Product, onSuccess: @escaping () -> Void) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else { return }
                onSuccess()
                await transaction.finish()          // ALLTID – ellers henger kjøpet
            case .userCancelled, .pending:
                break                               // brukeren ombestemte seg / venter (Ask to Buy)
            @unknown default:
                break
            }
        } catch {
            print("Kjøp feilet: \(error)")
        }
    }

    // MARK: Gjenopprett kjøp (kun Pro kan gjenopprettes – tips er borte)
    func restore() async {
        try? await AppStore.sync()      // ber Apple synkronisere
        await refreshEntitlements()     // leser Pro på nytt
    }

    // MARK: Speil Pro-status til brukerens profil (for admin-innsikt)
    // Skriver via set_pro_status-RPC, som kun oppdaterer auth.uid() sin egen rad.
    // StoreKit-kvitteringen er fortsatt den ekte kilden lokalt; dette er kun statistikk.
    private func syncProStatus(_ isPro: Bool) async {
        struct ProParams: Encodable { let p_is_pro: Bool }
        _ = try? await supabase
            .rpc("set_pro_status", params: ProParams(p_is_pro: isPro))
            .execute()
    }

    // MARK: Fang kjøp gjort utenfor appen (Ask to Buy, annen enhet, refusjon)
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await self.refreshEntitlements()    // hold isPro/hasPro i sync
                await transaction.finish()
            }
        }
    }

    deinit { updatesTask?.cancel() }
}
