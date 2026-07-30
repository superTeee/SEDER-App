import SwiftUI
import UIKit

// MARK: - Oppstartssekvens
//
// Tidslinje (totalt ca. 3,5 s):
//   0,0 s         foto + overlay (#403E3B, 40 %) er til stede fra første frame
//   0,3 → 1,3 s   logoen fader inn
//   1,3 → 3,5 s   hold
//   3,5 s         splash glir ut til venstre (0,3 s)
//
// (Vi starter bevisst med bilde + overlay — den gamle «foto alene»-fasen så ut
//  som en glitch og tok lengre tid.)
//
// Hvorfor eget UIWindow (se SplashOverlayWindow nederst):
// SwiftUI driver .offset-animasjoner frame for frame på hovedtråden. Når appen
// bak monterer TabView-en og henter data fra Supabase, blokkeres hovedtråden
// og sliden mister frames. Ved å legge splashen i et eget vindu og animere
// vinduets transform med UIView.animate, sendes animasjonen til render-serveren
// og går flytende uansett hva hovedtråden holder på med.

struct SplashCanvas: View {
    let onFinish: () -> Void

    @State private var logoVisible = false

    /// Dekning på overlay-laget: #403E3B ved 40 %.
    private let dimOpacity: Double = 0.40
    private let dimColor = Color(red: 64.0 / 255, green: 62.0 / 255, blue: 59.0 / 255)

    var body: some View {
        ZStack {
            Color("LaunchBackground")
                .ignoresSafeArea()

            Image("SplashBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // Overlay-laget er til stede fra første frame (ingen inn-fade).
            dimColor
                .opacity(dimOpacity)
                .ignoresSafeArea()

            Image("VitolaLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 180)          // 10% mindre (var 200)
                .offset(y: -32)             // 32px høyere opp
                .opacity(logoVisible ? 1 : 0)
        }
        .task {
            // Bilde + overlay vises umiddelbart; logoen fader inn nesten med en gang.
            try? await Task.sleep(for: .seconds(0.3))
            withAnimation(.easeInOut(duration: 1.0)) { logoVisible = true }
            try? await Task.sleep(for: .seconds(2.2))

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
