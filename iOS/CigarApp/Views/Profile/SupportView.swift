import SwiftUI
import StoreKit

// MARK: - SupportView
// Bidra/Pro-skjermen. Én skjerm, to modus (samme som SupportPromptManager.Mode):
//   .soft   – «bidra-modus»: kommer av seg selv etter litt tid. Tips i fokus, Pro som alternativ.
//   .unlock – «lås opp-modus»: kommer når man treffer humidor-grensen. Pro i fokus.
//
// Koblet til StoreManager (StoreKit 2). Priser og navn hentes fra Apple, så teksten
// «Gi 49 kr» / «599 kr» kommer fra selve produktet – ikke hardkodet.

struct SupportView: View {

    enum Mode { case soft, unlock }

    let mode: Mode
    var usedHumidors: Int = 2
    var freeHumidorLimit: Int = 2
    var unlockTitle: String? = nil        // egendefinert tittel i lås opp-modus
    var unlockSubtitle: String? = nil     // egendefinert undertekst i lås opp-modus
    var showQuota: Bool = true            // vis «du bruker X av Y humidorer»

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @ObservedObject private var store = StoreManager.shared

    @State private var selectedTip: Product?
    @State private var showTipsInUnlock = false
    @State private var working = false

    private let proBenefits = ["Ubegrensede humidorer", "Statistikk og innsikt", "Eksport av samling og journal"]
    private let tipLabels = ["En takk", "En kaffe", "Raust bidrag"]

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        header

                        if mode == .soft {
                            tipsSection
                            orDivider
                            proCard(highlighted: false)
                        } else {
                            if showQuota { quotaPill }
                            proCard(highlighted: true)
                            unlockTipArea
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, mode == .soft ? 34 : 26)
                    .padding(.bottom, 24)
                }

                footer
            }
        }
        .onAppear {
            if selectedTip == nil {
                selectedTip = store.tips.count > 1 ? store.tips[1] : store.tips.first
            }
        }
        .onChange(of: store.isPro) { _, isPro in
            if isPro { dismiss() }   // Pro låst opp → lukk skjermen
        }
    }

    // MARK: Header
    private var header: some View {
        VStack(spacing: 10) {
            if mode == .unlock {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color("Surface"))
                        .frame(width: 66, height: 66)
                    Image(systemName: "archivebox")
                        .font(.system(size: 28, weight: .regular))
                        .foregroundColor(Color("Accent"))
                }
                .padding(.bottom, 4)
            }

            Text(mode == .soft
                 ? "Kunne du tenke deg å hjelpe oss i utvikling av appen?"
                 : (unlockTitle ?? "Vil du ha flere humidorer?"))
                .font(.title3.bold())
                .foregroundColor(Color("TextPrimary"))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(mode == .soft
                 ? "SEDER er gratis. Vil du bidra, hjelper et engangsbeløp oss å drifte og utvikle appen videre."
                 : (unlockSubtitle ?? "Gratis inkluderer \(freeHumidorLimit) humidorer. Med SEDER Pro får du ubegrenset – én betaling, for alltid."))
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: 320)
    }

    // MARK: Tips (bidra-modus)
    private var tipsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                ForEach(Array(store.tips.enumerated()), id: \.element.id) { i, tip in
                    tipChip(tip, label: i < tipLabels.count ? tipLabels[i] : "")
                }
            }
            Button {
                if let tip = selectedTip { buy(tip) }
            } label: {
                VStack(spacing: 2) {
                    Text(selectedTip.map { "Gi \($0.displayPrice)" } ?? "Gi et bidrag")
                        .fontWeight(.semibold)
                    Text("Engangsbeløp · ingen abonnement")
                        .font(.caption2)
                        .opacity(0.85)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color("Accent"))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(selectedTip == nil || working)
        }
        .padding(.top, 22)
    }

    private func tipChip(_ tip: Product, label: String) -> some View {
        let isSel = selectedTip?.id == tip.id
        return Button {
            selectedTip = tip
        } label: {
            VStack(spacing: 3) {
                Text(tip.displayPrice)
                    .font(.headline)
                    .foregroundColor(isSel ? Color("Accent") : Color("TextPrimary"))
                Text(label)
                    .font(.caption2)
                    .foregroundColor(Color("TextSecondary"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSel ? Color("Card") : Color("Card"))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSel ? Color("Accent") : Color("Surface"), lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var orDivider: some View {
        HStack(spacing: 12) {
            Rectangle().fill(Color("Surface")).frame(height: 1)
            Text("eller").font(.caption).foregroundColor(Color("TextSecondary"))
            Rectangle().fill(Color("Surface")).frame(height: 1)
        }
        .padding(.vertical, 18)
    }

    // MARK: Quota-pille (lås opp-modus)
    private var quotaPill: some View {
        HStack(spacing: 8) {
            Circle().fill(Color("Accent")).frame(width: 9, height: 9)
            Text("Du bruker \(usedHumidors) av \(freeHumidorLimit) humidorer")
                .font(.footnote.weight(.semibold))
                .foregroundColor(Color("Accent"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Capsule().fill(Color("Surface")))
        .padding(.top, 18)
        .padding(.bottom, 22)
    }

    // MARK: Pro-kort
    private func proCard(highlighted: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("SEDER Pro").font(.headline).foregroundColor(Color("TextPrimary"))
                    Text("Én betaling · for alltid").font(.caption).foregroundColor(Color("TextSecondary"))
                }
                Spacer()
                Text(store.pro?.displayPrice ?? "")
                    .font(.headline).foregroundColor(Color("Accent"))
            }

            VStack(alignment: .leading, spacing: 7) {
                ForEach(proBenefits, id: \.self) { b in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundColor(Color("Accent"))
                        Text(b).font(.subheadline).foregroundColor(Color("TextPrimary"))
                    }
                }
            }
            .padding(.top, 12)

            Button {
                buyPro()
            } label: {
                Text("Lås opp Pro")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(highlighted ? Color("Accent") : Color.clear)
                    .foregroundColor(highlighted ? .white : Color("Accent"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color("Accent"), lineWidth: highlighted ? 0 : 1.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(working)
            .padding(.top, 14)
        }
        .padding(16)
        .background(Color("Card"))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(highlighted ? Color("Accent") : Color("Surface"), lineWidth: highlighted ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.top, mode == .soft ? 14 : 0)
    }

    // MARK: Tips nedtonet i lås opp-modus
    private var unlockTipArea: some View {
        VStack(spacing: 12) {
            if showTipsInUnlock {
                HStack(spacing: 10) {
                    ForEach(Array(store.tips.enumerated()), id: \.element.id) { i, tip in
                        tipChip(tip, label: i < tipLabels.count ? tipLabels[i] : "")
                    }
                }
                Button {
                    if let tip = selectedTip { buy(tip) }
                } label: {
                    Text(selectedTip.map { "Gi \($0.displayPrice)" } ?? "Gi et bidrag")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color("Accent"), lineWidth: 1.5))
                        .foregroundColor(Color("Accent"))
                }
                .disabled(selectedTip == nil || working)
            } else {
                Button {
                    withAnimation { showTipsInUnlock = true }
                } label: {
                    Text("Vil du heller gi et lite bidrag?")
                        .font(.footnote)
                        .foregroundColor(Color("TextSecondary"))
                        .underline()
                }
            }
        }
        .padding(.top, 16)
    }

    // MARK: Footer (utvei + juridisk)
    private var footer: some View {
        VStack(spacing: 16) {
            Button { dismiss() } label: {
                Text(mode == .soft ? "Jeg ønsker ikke å bidra nå" : "Behold \(freeHumidorLimit) humidorer")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color("TextSecondary"))
            }

            HStack(spacing: 6) {
                Button("Gjenopprett kjøp") { restore() }
                dot
                Button("Vilkår") { open("https://sederappen.no/terms.html") }
                dot
                Button("Personvern") { open("https://sederappen.no/privacy.html") }
            }
            .font(.caption2)
            .foregroundColor(Color("TextSecondary"))
        }
        .padding(.top, 12)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity)
        .background(Color("Background"))
    }

    private var dot: some View {
        Text("·").foregroundColor(Color("TextSecondary"))
    }

    // MARK: Handlinger
    private func buy(_ tip: Product) {
        working = true
        Task {
            await store.buyTip(tip)
            working = false
            dismiss()
        }
    }
    private func buyPro() {
        working = true
        Task {
            await store.buyPro()
            working = false
            // dismiss skjer via .onChange(of: store.isPro)
        }
    }
    private func restore() {
        Task { await store.restore() }
    }
    private func open(_ s: String) {
        if let url = URL(string: s) { openURL(url) }
    }
}
