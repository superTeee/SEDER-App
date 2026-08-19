import SwiftUI
import AVFoundation
import Combine

// MARK: - ScanView
// Kameravisning for å scanne sigarbandet

struct ScanView: View {

    @StateObject private var scanService = ScanService()
    @State private var showCameraPicker = false
    @State private var showLibraryPicker = false
    @State private var capturedImage: UIImage?
    @State private var navigateToResults = false

    // Delt opp i mindre del-views: hele body ble ett så stort uttrykk at Swift-
    // kompilatoren ikke rakk å type-sjekke det. Mindre biter → rask kompilering.

    private var previewBox: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color("Surface"))
                .frame(width: 300, height: 200)
                .shadow(color: .black.opacity(0.08), radius: 12)

            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 300, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 48))
                        .foregroundColor(Color("TextPrimary"))
                    Text("Hold bandet innenfor rammen")
                        .font(.subheadline)
                        .foregroundColor(Color("TextSecondary"))
                }
            }
        }
    }

    private var captureButtons: some View {
        VStack(spacing: 12) {
            Button(action: { openCamera() }) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Ta bilde")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("Accent"))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            Button(action: { openPhotoLibrary() }) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                    Text("Velg fra bibliotek")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("Surface"))
                .foregroundColor(Color("Accent"))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }

    private var scanTips: some View {
        VStack(spacing: 6) {
            ScanTip(icon: "light.max", text: "God belysning — unngå skygger og reflekser")
            ScanTip(icon: "arrow.up.left.and.arrow.down.right", text: "Kom nær nok til at teksten er leselig")
            ScanTip(icon: "hand.raised", text: "Hold sigaren stille og bandet flatt mot deg")
        }
        .padding(.horizontal, 24)
    }

    private var instruction: some View {
        VStack(spacing: 8) {
            Text("Scan sigarband")
                .font(.title2.bold())
            Text("Ta bilde av etiketten på sigaren\nfor å identifisere den")
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)
        }
    }

    private var idleContent: some View {
        VStack(spacing: 32) {
            Spacer()
            previewBox
            if capturedImage == nil { scanTips }
            instruction
            Spacer()
            captureButtons
        }
    }

    var body: some View {
        NavigationStack {
            // «screen» dekker skjermen + kamera/bibliotek/resultat-presentasjonene.
            // Resten av presentasjonene (form/wrapper/ingen-treff/feil) legges på her.
            // Delt i to så den lange modifikator-kjeden type-sjekkes i mindre biter.
            screen
                .fullScreenCover(isPresented: $scanService.needsShapePhoto) {
                    ShapeConfirmView(scanService: scanService)
                }
                .onChange(of: scanService.needsShapePhoto) { needsPhoto in
                    // Form-avklaringen er ferdig (gikk fra true → false) — naviger nå.
                    guard !needsPhoto, !scanService.scanResults.isEmpty else { return }
                    navigateToResults = true
                }
                .fullScreenCover(isPresented: $scanService.needsWrapperPhoto) {
                    WrapperConfirmView(scanService: scanService)
                }
                .onChange(of: scanService.needsWrapperPhoto) { needsPhoto in
                    // Wrapper-avklaringen er ferdig (gikk fra true → false) — naviger nå.
                    guard !needsPhoto, !scanService.scanResults.isEmpty else { return }
                    navigateToResults = true
                }
                // Ingen treff → vennlig skjerm som forklarer HVORFOR og viser veien videre.
                .fullScreenCover(isPresented: $scanService.noMatch) {
                    NoMatchView(
                        image: capturedImage,
                        ocrText: scanService.extractedText,
                        outcome: scanService.bandTextOutcome,
                        readBrand: scanService.readBrand,
                        readSeries: scanService.readSeries,
                        onRetry: {
                            scanService.noMatch = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showCameraPicker = true }
                        },
                        onManualAdd: {
                            scanService.noMatch = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { navigateToResults = true }
                        }
                    )
                }
                .alert("Feil", isPresented: .constant(scanService.errorMessage != nil)) {
                    Button("OK") { scanService.errorMessage = nil }
                } message: {
                    Text(scanService.errorMessage ?? "")
                }
        }
    }

    // Selve skjermen + de primære presentasjonene (kamera, bibliotek, resultater).
    private var screen: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            // Hele tomskjerm-innholdet — utdelt så body forblir lite.
            idleContent

            // Loading overlay
            if scanService.isScanning {
                ScanningOverlay()
            }
        }
        .navigationTitle("SEDER")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCameraPicker) {
            MacroCameraView(image: $capturedImage) {
                if let image = capturedImage {
                    Task { await scanService.scanBandImage(image) }
                }
            }
        }
        .sheet(isPresented: $showLibraryPicker) {
            ImagePicker(image: $capturedImage, sourceType: .photoLibrary) {
                if let image = capturedImage {
                    Task { await scanService.scanBandImage(image) }
                }
            }
        }
        .navigationDestination(isPresented: $navigateToResults) {
            ResultsView(results: scanService.scanResults, ocrText: scanService.extractedText, bandImage: capturedImage, prefillBrand: scanService.readBrand)
        }
        // Alltid til ResultsView — aldri direkte til detaljskjermen.
        .onChange(of: scanService.scanResults) { results in
            guard !results.isEmpty,
                  !scanService.needsShapePhoto,
                  !scanService.needsWrapperPhoto else { return }
            navigateToResults = true
        }
    }

    private func openCamera() {
        showCameraPicker = true
    }

    private func openPhotoLibrary() {
        showLibraryPicker = true
    }
}

// MARK: - ScanSheet
// Global bottom sheet som åpnes fra skann-knappen. Ett ikon til venstre per
// valg, ren hvit bakgrunn i light mode. Hvert valg lukker arket og trigger
// riktig flyt (via closure) etter en kort forsinkelse, så arket rekker å lukke
// seg før neste kamera/velger/ark presenteres.
struct ScanSheet: View {

    var onBand: () -> Void = {}
    var onPhoto: () -> Void = {}
    var onReceipt: () -> Void = {}
    var onBarcode: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var sheetBackground: Color {
        colorScheme == .light ? .white : Color("Card")
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Skann")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color("TextPrimary"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)

            VStack(spacing: 0) {
                row(icon: "camera.viewfinder", title: "Sigarbånd",
                    subtitle: "Skann båndet på sigaren", action: onBand)
                divider
                row(icon: "photo.on.rectangle.angled", title: "Bilde fra kamerarull",
                    subtitle: "Velg et bilde du har tatt", action: onPhoto)
                divider
                row(icon: "doc.text.viewfinder", title: "Kvittering",
                    subtitle: "Legg kjøpet rett i humidoren", action: onReceipt)
            }
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(sheetBackground.ignoresSafeArea())
    }

    private var divider: some View {
        Rectangle()
            .fill(Color("TextSecondary").opacity(0.12))
            .frame(height: 0.5)
            .padding(.leading, 72)
    }

    private func row(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { action() }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(Color("Accent").opacity(0.14))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(Color("Accent"))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color("TextPrimary"))
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(Color("TextSecondary"))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color("TextSecondary").opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shape Confirm View
// Vises når samme bånd matchet flere størrelser/former i databasen.
// Funksjonell test-UI — visuell stil byttes ut når Toms eget design er klart.
struct ShapeConfirmView: View {

    @ObservedObject var scanService: ScanService
    @State private var showCamera = false
    @State private var shapeImage: UIImage?

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "questionmark.circle")
                    .font(.system(size: 48))
                    .foregroundColor(Color("TextPrimary"))

                VStack(spacing: 8) {
                    Text("Fant flere størrelser")
                        .font(.title2.bold())
                    Text("Samme bånd brukes på flere varianter av denne sigaren.\nTa ett bilde av HELE sigaren, så ser vi formen og velger riktig variant.")
                        .font(.subheadline)
                        .foregroundColor(Color("TextSecondary"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                VStack(spacing: 12) {
                    Button(action: { showCamera = true }) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Ta bilde av hele sigaren")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("Accent"))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    Button("Hopp over, vis alle treff") {
                        scanService.needsShapePhoto = false
                    }
                    .font(.subheadline)
                    .foregroundColor(Color("TextSecondary"))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }

            if scanService.isScanning {
                ScanningOverlay()
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            MacroCameraView(image: $shapeImage) {
                if let shapeImage {
                    Task { await scanService.resolveShapeAmbiguity(with: shapeImage) }
                }
            }
        }
    }
}

// MARK: - Wrapper Confirm View
// Vises når samme bånd/serie matchet flere wrapper-varianter i databasen
// (f.eks. samme "Vintage 1999" i Connecticut vs. Maduro). Båndet viser
// sjelden wrapper-fargen tydelig nok, så vi ber om ett bilde av hele
// sigaren — samme mønster som ShapeConfirmView, men for wrapper-typen.
// Funksjonell test-UI — visuell stil byttes ut når Toms eget design er klart.
struct WrapperConfirmView: View {

    @ObservedObject var scanService: ScanService
    @State private var showCamera = false
    @State private var wrapperImage: UIImage?

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "questionmark.circle")
                    .font(.system(size: 48))
                    .foregroundColor(Color("TextPrimary"))

                VStack(spacing: 8) {
                    Text("Fant flere varianter")
                        .font(.title2.bold())
                    Text("Denne serien finnes med flere wrapper-typer.\nTa ett bilde av HELE sigaren, så ser vi fargen på bladet og velger riktig variant.")
                        .font(.subheadline)
                        .foregroundColor(Color("TextSecondary"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                VStack(spacing: 12) {
                    Button(action: { showCamera = true }) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Ta bilde av hele sigaren")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("Accent"))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    Button("Hopp over, vis alle treff") {
                        scanService.needsWrapperPhoto = false
                    }
                    .font(.subheadline)
                    .foregroundColor(Color("TextSecondary"))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }

            if scanService.isScanning {
                ScanningOverlay()
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            MacroCameraView(image: $wrapperImage) {
                if let wrapperImage {
                    Task { await scanService.resolveWrapperAmbiguity(with: wrapperImage) }
                }
            }
        }
    }
}

// MARK: - Scan Tip
private struct ScanTip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color("Accent"))
                .frame(width: 20)
            Text(text)
                .font(.footnote)
                .foregroundColor(Color("TextSecondary"))
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color("Surface"))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Scanning Overlay
// Stilren skanne-loader: gull-hjørner rammer inn en sigar i kontur med et rundt
// sigarbelte, en gull-stråle glir opp og ned, og teksten veksler mykt mellom de
// tre stegene. Brukes overalt der skanning pågår.
struct ScanningOverlay: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var beamDown = false
    @State private var stepIndex = 0
    @State private var textVisible = true

    private let steps = ["Skanner sigarbeltet", "Skanner dekkblad", "Søker i basen"]
    private let cycle = Timer.publish(every: 4.6, on: .main, in: .common).autoconnect()

    private var cardBackground: Color { colorScheme == .light ? .white : Color("Card") }
    private var accent: Color { Color("Accent") }
    private var outline: Color { Color("TextPrimary").opacity(0.5) }

    private let fieldW: CGFloat = 158
    private let fieldH: CGFloat = 72

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 40) {
                scanField
                Text(steps[stepIndex])
                    .font(.system(size: 17, design: .serif))
                    .foregroundColor(Color("TextPrimary"))
                    .opacity(textVisible ? 1 : 0)
                    .frame(minHeight: 22)
            }
            .padding(.horizontal, 44)
            .padding(.vertical, 42)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                beamDown = true
            }
        }
        .onReceive(cycle) { _ in
            withAnimation(.easeInOut(duration: 0.7)) { textVisible = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.72) {
                stepIndex = (stepIndex + 1) % steps.count
                withAnimation(.easeInOut(duration: 0.7)) { textVisible = true }
            }
        }
    }

    private var scanField: some View {
        ZStack {
            ScanCorners(len: 12, inset: 6)
                .stroke(accent.opacity(0.7), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))

            // Sigar i kontur med rundt sigarbelte
            RoundedRectangle(cornerRadius: 9)
                .strokeBorder(outline, lineWidth: 1.5)
                .frame(width: 93, height: 17)
                .overlay(
                    ZStack {
                        Circle().fill(accent.opacity(0.15))
                        Circle().strokeBorder(accent, lineWidth: 1.5)
                        Circle().fill(accent).frame(width: 3, height: 3)
                    }
                    .frame(width: 14, height: 14)
                    // Beltet sitter på senterlinjen (ser ut som et belte rundt sigaren),
                    // men ~5px lenger NED langs sigaren (mot foten) så det blir mer rom
                    // for hodet. Sigaren er tiltet, så mindre x = ned mot foten.
                    .offset(x: 93 / 2 - 7 - 12)
                )
                .rotationEffect(.degrees(-9))

            // Skanner-stråle
            RoundedRectangle(cornerRadius: 1)
                .fill(LinearGradient(colors: [.clear, accent, accent, .clear],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(height: 2)
                .shadow(color: accent.opacity(0.5), radius: 6)
                .padding(.horizontal, 6)
                .offset(y: beamDown ? (fieldH / 2 - 8) : -(fieldH / 2 - 8))
        }
        .frame(width: fieldW, height: fieldH)
    }
}

// Fire hjørne-braketter som rammer inn skanne-området (uten bakgrunnsfelt).
struct ScanCorners: Shape {
    var len: CGFloat = 12
    var inset: CGFloat = 6

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let x0 = rect.minX + inset, x1 = rect.maxX - inset
        let y0 = rect.minY, y1 = rect.maxY
        let l = len
        // Topp venstre
        p.move(to: CGPoint(x: x0, y: y0 + l)); p.addLine(to: CGPoint(x: x0, y: y0)); p.addLine(to: CGPoint(x: x0 + l, y: y0))
        // Topp høyre
        p.move(to: CGPoint(x: x1 - l, y: y0)); p.addLine(to: CGPoint(x: x1, y: y0)); p.addLine(to: CGPoint(x: x1, y: y0 + l))
        // Bunn venstre
        p.move(to: CGPoint(x: x0, y: y1 - l)); p.addLine(to: CGPoint(x: x0, y: y1)); p.addLine(to: CGPoint(x: x0 + l, y: y1))
        // Bunn høyre
        p.move(to: CGPoint(x: x1 - l, y: y1)); p.addLine(to: CGPoint(x: x1, y: y1)); p.addLine(to: CGPoint(x: x1, y: y1 - l))
        return p
    }
}

// MARK: - ImagePicker wrapper
struct ImagePicker: UIViewControllerRepresentable {

    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType
    var onComplete: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        if sourceType == .camera {
            picker.cameraOverlayView = ImagePicker.makeHintOverlay()
        }
        return picker
    }

    /// Rolig hint-stripe nederst i kamera-søkeren. userInteractionEnabled = false
    /// slik at kamera-kontrollene under fortsatt tar imot trykk.
    private static func makeHintOverlay() -> UIView {
        let container = UIView(frame: UIScreen.main.bounds)
        container.isUserInteractionEnabled = false
        container.backgroundColor = .clear

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
        blur.layer.cornerRadius = 12
        blur.clipsToBounds = true
        blur.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "Godt lys · fyll rammen · rett forfra"
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        blur.contentView.addSubview(label)
        container.addSubview(blur)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: blur.contentView.leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: blur.contentView.trailingAnchor, constant: -14),
            label.topAnchor.constraint(equalTo: blur.contentView.topAnchor, constant: 9),
            label.bottomAnchor.constraint(equalTo: blur.contentView.bottomAnchor, constant: -9),
            blur.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            blur.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -170),
        ])
        return container
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            picker.dismiss(animated: true) { self.parent.onComplete() }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Ingen treff
// Vennlig skjerm når skannet ikke ga treff. Forklarer hvorfor + gir vei videre:
// prøv på nytt, eller legg den inn manuelt (og bygg katalogen sammen med oss).
struct NoMatchView: View {
    let image: UIImage?
    let ocrText: String
    // Hvorfor skanningen ikke ga treff — avgjør forklaringen og hvilken
    // handling som er den naturlige neste. Default .clear så eldre kall kompilerer.
    var outcome: ScanService.BandTextOutcome = .clear
    // Det GPT LESTE (rent merke/serie) — vises i «Vi leste: X»-chipen. Faller
    // tilbake til rå OCR-tekst hvis vi ikke fikk et rent navn.
    var readBrand: String? = nil
    var readSeries: String? = nil
    var onRetry: () -> Void
    var onManualAdd: () -> Void

    @Environment(\.dismiss) private var dismiss

    // Tilpasset forklaring per situasjon.
    private var reason: (icon: String, title: String, body: String) {
        switch outcome {
        case .none:
            return ("textformat",
                    "Vi klarte ikke å lese båndet",
                    "Båndet er enten rent grafisk, eller har bare noen få tegn (som en forkortelse) — for lite til å slå opp et merke. Sigaren kan likevel ligge i databasen; legger du den inn, kjenner appen igjen båndet neste gang.")
        case .unclear:
            return ("scribble.variable",
                    "Vi så tekst, men klarte ikke å lese den",
                    "Teksten kan være bøyd, vinklet eller ha gjenskinn. Et skarpere bilde med godt lys hjelper ofte — ellers kan du legge sigaren inn manuelt.")
        case .clear:
            return ("magnifyingglass",
                    "Vi leste båndet, men fant ingen match — ennå",
                    "Sigaren mangler kanskje i databasen. Søk eller legg den inn manuelt, så kobler vi deg til riktig oppføring.")
        }
    }

    // Et nytt bilde hjelper bare når teksten var utydelig — ikke når båndet er
    // helt uten tekst. Da er manuell innlegging den naturlige primærveien.
    private var retryIsPrimary: Bool { outcome == .unclear }

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color("TextSecondary"))
                    }
                }
                .padding(20)

                // Leste vi båndet, men mangler sigaren i basen? Da er dette en
                // OPPDAGELSE, ikke en feil — vennlig, motiverende variant som
                // gjør at brukeren vil legge den inn. Ellers: foto-tips.
                if outcome == .clear {
                    discoveryContent
                } else {
                    readingFailedContent
                }
            }
        }
    }

    /// Det chipen viser: det RENE navnet GPT leste (merke + evt. serie) hvis vi
    /// har det, ellers en renskrevet utgave av rå OCR-tekst.
    private var chipText: String? {
        if let b = readBrand, !b.isEmpty {
            if let s = readSeries, !s.isEmpty { return "\(b) \(s)" }
            return b
        }
        return readLabel
    }

    /// Kort, lesbar utgave av det appen leste — fallback til «Vi leste båndet:»-chipen.
    private var readLabel: String? {
        guard outcome == .clear else { return nil }
        let words = ocrText.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 2 }
            .prefix(4)
            .map { $0.prefix(1).uppercased() + String($0.dropFirst()) }
        let label = words.joined(separator: " ")
        return label.count >= 3 ? label : nil
    }

    // «Du fant en vi ikke har» — vennlig oppdagelses-variant (outcome == .clear).
    // Vi leste båndet, men sigaren mangler i basen. Ramme det som en oppdagelse,
    // ikke en feil, så brukeren vil legge den inn.
    @ViewBuilder private var discoveryContent: some View {
        Spacer()

        ZStack {
            Circle().fill(Color("Accent").opacity(0.12)).frame(width: 96, height: 96)
            Image(systemName: "sparkle.magnifyingglass")
                .font(.system(size: 34, weight: .regular))
                .foregroundColor(Color("Accent"))
        }
        .padding(.bottom, 20)

        Text("Du fant en vi ikke\nhar ennå")
            .font(.title2.bold())
            .foregroundColor(Color("TextPrimary"))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)

        if let chipText {
            HStack(spacing: 7) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.24, green: 0.55, blue: 0.35))
                Text("Vi leste båndet:")
                    .foregroundColor(Color("TextSecondary"))
                Text(chipText)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("TextPrimary"))
            }
            .font(.system(size: 13.5))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color(red: 0.91, green: 0.96, blue: 0.92)))
            .overlay(Capsule().stroke(Color(red: 0.80, green: 0.90, blue: 0.83), lineWidth: 1))
            .padding(.top, 14)
        }

        Text("Denne ligger ikke i katalogen ennå. Legg den inn, så er du den som setter den på kartet — og appen kjenner den igjen for alle neste gang.")
            .font(.subheadline)
            .foregroundColor(Color("TextSecondary"))
            .multilineTextAlignment(.center)
            .padding(.top, 14)
            .padding(.horizontal, 28)

        HStack(spacing: 12) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 16))
                .foregroundColor(Color("Accent"))
                .frame(width: 34, height: 34)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color("Background")))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color("TextSecondary").opacity(0.15), lineWidth: 1))
            Text("Du blir den første som legger inn denne. Sånn bygger vi katalogen — én oppdagelse om gangen.")
                .font(.system(size: 12.5))
                .foregroundColor(Color("TextPrimary").opacity(0.8))
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color("Card")))
        .padding(.horizontal, 24)
        .padding(.top, 20)

        Spacer()

        VStack(spacing: 10) {
            primaryButton("Legg den inn — tar 20 sekunder", action: onManualAdd)
            secondaryButton("Prøv på nytt med nytt bilde", action: onRetry)
            Text("Blir din med én gang — vi verifiserer mot produsenten etterpå.")
                .font(.system(size: 11.5))
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)
                .padding(.top, 2)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
    }

    // Klarte ikke å lese båndet (outcome == .none / .unclear) — foto-tips.
    @ViewBuilder private var readingFailedContent: some View {
        Spacer()

        Image(systemName: reason.icon)
            .font(.system(size: 32, weight: .regular))
            .foregroundColor(Color("Accent"))
            .frame(width: 84, height: 84)
            .background(Circle().fill(Color("Accent").opacity(0.12)))
            .padding(.bottom, 18)

        Text(reason.title)
            .font(.title2.bold())
            .foregroundColor(Color("TextPrimary"))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)

        Text(reason.body)
            .font(.subheadline)
            .foregroundColor(Color("TextSecondary"))
            .multilineTextAlignment(.center)
            .padding(.top, 8)
            .padding(.horizontal, 28)

        VStack(alignment: .leading, spacing: 10) {
            Text("Tips for best mulig resultat")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color("TextPrimary"))
            cause("sun.max", "Godt, jevnt lys — unngå skygge og motlys")
            cause("viewfinder", "Fyll rammen med båndet — kom nærmere")
            cause("rectangle.portrait", "Rett forfra — unngå refleks og blits")
            cause("hand.raised", "Hold stødig til bildet er skarpt")
            cause("leaf", "Ta med litt av sigarkroppen — så vi ser dekkbladets farge")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color("Card"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 24)
        .padding(.top, 22)

        Spacer()

        VStack(spacing: 10) {
            if retryIsPrimary {
                primaryButton("Prøv på nytt med nytt bilde", action: onRetry)
                secondaryButton("Legg den inn manuelt", action: onManualAdd)
            } else {
                primaryButton("Legg den inn manuelt", action: onManualAdd)
                secondaryButton("Prøv på nytt med nytt bilde", action: onRetry)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color("Accent"))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color("Card"))
                .foregroundColor(Color("Accent"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func cause(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(Color("Accent"))
                .frame(width: 20)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Color("TextPrimary").opacity(0.85))
        }
    }
}

// MARK: - Beskjær opplastet bilde
// Kun ved bibliotek-opplasting: et bibliotek-bilde er ofte tatt på avstand, så
// båndet blir lite. Her strammer brukeren rammen rundt båndet (og kan rotere
// bildet 90°), og utsnittet sendes videre til skanningen for bedre treff.
struct BandCropView: View {
    let image: UIImage
    var onCancel: () -> Void
    var onCrop: (UIImage) -> Void

    @State private var working: UIImage?          // bildet med gjeldende rotasjon
    @State private var crop = CGRect.zero          // ramme i visnings-koordinater
    @State private var imageFrame = CGRect.zero    // der bildet faktisk vises (aspect-fit)
    @State private var containerSize = CGSize.zero
    @State private var dragStart: CGRect? = nil

    private var shown: UIImage { working ?? image }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Avbryt", action: onCancel)
                Spacer()
                Text("Beskjær").font(.system(size: 16, weight: .semibold))
                Spacer()
                Button("Bruk", action: commit).fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)

            GeometryReader { geo in
                ZStack {
                    Image(uiImage: shown)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width, height: geo.size.height)

                    // Mørkt utenfor utsnittet.
                    Rectangle().fill(Color.black.opacity(0.55))
                        .mask(
                            ZStack {
                                Rectangle()
                                Rectangle()
                                    .frame(width: crop.width, height: crop.height)
                                    .position(x: crop.midX, y: crop.midY)
                                    .blendMode(.destinationOut)
                            }.compositingGroup()
                        )
                        .allowsHitTesting(false)

                    // Ramme (dra for å flytte).
                    Rectangle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: crop.width, height: crop.height)
                        .position(x: crop.midX, y: crop.midY)
                        .contentShape(Rectangle())
                        .gesture(moveGesture)

                    // Hjørne-håndtak (dra for å endre størrelse).
                    Circle()
                        .fill(Color.white)
                        .overlay(Circle().stroke(Color("Accent"), lineWidth: 2))
                        .frame(width: 28, height: 28)
                        .position(x: crop.maxX, y: crop.maxY)
                        .gesture(resizeGesture)
                }
                .onAppear {
                    if working == nil { working = image }
                    setup(container: geo.size)
                }
                .onChange(of: geo.size) { newSize in setup(container: newSize) }
            }
            .background(Color.black)

            HStack(spacing: 14) {
                Button { rotate90() } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "rotate.right")
                        Text("Roter")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Capsule().fill(Color.white.opacity(0.14)))
                }
                Spacer()
                Text("Stram rammen rundt båndet")
                    .font(.system(size: 12.5))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color.black.ignoresSafeArea())
    }

    // MARK: - Oppsett + gester

    private func setup(container: CGSize) {
        containerSize = container
        let img = shown.size
        guard img.width > 0, img.height > 0, container.width > 0, container.height > 0 else { return }
        let scale = min(container.width / img.width, container.height / img.height)
        let w = img.width * scale, h = img.height * scale
        let f = CGRect(x: (container.width - w) / 2, y: (container.height - h) / 2, width: w, height: h)
        imageFrame = f
        // Startramme: bred og lav rundt midten — bånd-form.
        let cw = f.width * 0.82
        let ch = min(f.height * 0.4, f.height)
        crop = CGRect(x: f.midX - cw / 2, y: f.midY - ch / 2, width: cw, height: ch)
    }

    private var moveGesture: some Gesture {
        DragGesture()
            .onChanged { g in
                if dragStart == nil { dragStart = crop }
                guard let s = dragStart else { return }
                var r = s
                r.origin.x = s.minX + g.translation.width
                r.origin.y = s.minY + g.translation.height
                crop = clamp(r)
            }
            .onEnded { _ in dragStart = nil }
    }

    private var resizeGesture: some Gesture {
        DragGesture()
            .onChanged { g in
                if dragStart == nil { dragStart = crop }
                guard let s = dragStart else { return }
                var r = s
                r.size.width = max(60, s.width + g.translation.width)
                r.size.height = max(60, s.height + g.translation.height)
                crop = clamp(r)
            }
            .onEnded { _ in dragStart = nil }
    }

    private func clamp(_ r: CGRect) -> CGRect {
        let f = imageFrame
        var out = r
        out.size.width = min(out.width, f.width)
        out.size.height = min(out.height, f.height)
        out.origin.x = min(max(out.minX, f.minX), f.maxX - out.width)
        out.origin.y = min(max(out.minY, f.minY), f.maxY - out.height)
        return out
    }

    // MARK: - Rotasjon + beskjæring

    private func rotate90() {
        working = rotatedCW(shown)
        setup(container: containerSize)
    }

    private func commit() {
        let base = shown
        let f = imageFrame
        guard f.width > 0, f.height > 0 else { onCrop(base); return }
        let nx = (crop.minX - f.minX) / f.width
        let ny = (crop.minY - f.minY) / f.height
        let nw = crop.width / f.width
        let nh = crop.height / f.height
        onCrop(cropNormalized(base, nx: nx, ny: ny, nw: nw, nh: nh))
    }

    private func normalizedUp(_ img: UIImage) -> UIImage {
        if img.imageOrientation == .up { return img }
        let r = UIGraphicsImageRenderer(size: img.size)
        return r.image { _ in img.draw(in: CGRect(origin: .zero, size: img.size)) }
    }

    private func rotatedCW(_ img: UIImage) -> UIImage {
        let up = normalizedUp(img)
        let newSize = CGSize(width: up.size.height, height: up.size.width)
        let r = UIGraphicsImageRenderer(size: newSize)
        return r.image { ctx in
            let c = ctx.cgContext
            c.translateBy(x: newSize.width, y: 0)
            c.rotate(by: .pi / 2)
            up.draw(at: .zero)
        }
    }

    private func cropNormalized(_ img: UIImage, nx: CGFloat, ny: CGFloat, nw: CGFloat, nh: CGFloat) -> UIImage {
        let up = normalizedUp(img)
        guard let cg = up.cgImage else { return img }
        let W = CGFloat(cg.width), H = CGFloat(cg.height)
        let rect = CGRect(x: nx * W, y: ny * H, width: nw * W, height: nh * H).integral
        let bounded = rect.intersection(CGRect(x: 0, y: 0, width: W, height: H))
        guard bounded.width > 1, bounded.height > 1, let out = cg.cropping(to: bounded) else { return img }
        return UIImage(cgImage: out, scale: up.scale, orientation: .up)
    }
}
