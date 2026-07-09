import SwiftUI
import UIKit

// MARK: - Oppstartssekvens
//
// Tidslinje (totalt ca. 6,5 s):
//   0,0 → 1,0 s   fotoet alene, uten overlay
//   1,0 → 2,0 s   det sorte laget fader inn til 10 % dekning
//   2,0 → 3,0 s   hold   ← splash uten logo er nå 3 sekunder
//   3,0 → 4,0 s   logoen fader inn
//   4,0 → 6,5 s   hold   ← splash med logo er nå 3,5 sekunder
//   6,5 s         splash glir ut til venstre (0,3 s)
//
// Hvorfor eget UIWindow (se SplashOverlayWindow nederst):
// SwiftUI driver .offset-animasjoner frame for frame på hovedtråden. Når appen
// bak monterer TabView-en og henter data fra Supabase, blokkeres hovedtråden
// og sliden mister frames. Ved å legge splashen i et eget vindu og animere
// vinduets transform med UIView.animate, sendes animasjonen til render-serveren
// og går flytende uansett hva hovedtråden holder på med.

struct SplashCanvas: View {
    let onFinish: () -> Void

    @State private var dimmed = false
    @State private var logoVisible = false

    /// Dekning på det sorte laget. 0,10 = 90 % gjennomsiktig.
    private let dimOpacity: Double = 0.10

    var body: some View {
        ZStack {
            Color("LaunchBackground")
                .ignoresSafeArea()

            Image("SplashBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Color.black
                .opacity(dimmed ? dimOpacity : 0)
                .ignoresSafeArea()

            Image("VitolaLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 200)
                .opacity(logoVisible ? 1 : 0)
        }
        .task {
            // 1. Fotoet står alene i 1 sekund.
            try? await Task.sleep(for: .seconds(1.0))

            // 2. Sort lag fader inn over 1 sekund.
            withAnimation(.easeInOut(duration: 1.0)) { dimmed = true }
            try? await Task.sleep(for: .seconds(1.0))

            // 3. Hold i 1 sekund — splash uten logo er nå 3 sekunder totalt.
            try? await Task.sleep(for: .seconds(1.0))

            // 4. Logoen fader inn over 1 sekund, så 2,5 sekunders hold.
            withAnimation(.easeInOut(duration: 1.0)) { logoVisible = true }
            try? await Task.sleep(for: .seconds(3.5))

            onFinish()
        }
    }
}

// MARK: - SplashOverlayWindow
// Splashen bor i sitt eget UIWindow over app-vinduet. Sliden animeres med
// UIView.animate på vinduets transform — altså ren Core Animation, som kjører
// på render-serveren og derfor ikke kan hakke selv om hovedtråden er opptatt.

final class SplashOverlayWindow {
    static let shared = SplashOverlayWindow()
    private init() {}

    private var window: UIWindow?
    private var hasPresented = false

    private let slideDuration: TimeInterval = 0.3

    func present() {
        guard !hasPresented else { return }

        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
        else { return }

        hasPresented = true

        let overlay = UIWindow(windowScene: scene)
        overlay.windowLevel = .normal + 1
        overlay.isUserInteractionEnabled = false   // ingen touch går tapt bak splashen

        let host = UIHostingController(rootView: SplashCanvas(onFinish: { [weak self] in
            self?.slideOut()
        }))
        host.view.backgroundColor = .clear
        overlay.rootViewController = host
        overlay.isHidden = false                   // ikke makeKey — app-vinduet beholder fokus

        window = overlay
    }

    private func slideOut() {
        guard let overlay = window else { return }
        let width = overlay.bounds.width

        UIView.animate(withDuration: slideDuration, delay: 0, options: [.curveEaseInOut]) {
            overlay.transform = CGAffineTransform(translationX: -width, y: 0)
        } completion: { _ in
            overlay.isHidden = true
            overlay.rootViewController = nil
            self.window = nil
        }
    }
}
