import SwiftUI
import AVFoundation

// MARK: - ScanView
// Kameravisning for å scanne sigarbandet

struct ScanView: View {

    @StateObject private var scanService = ScanService()
    @State private var showCameraPicker = false
    @State private var showLibraryPicker = false
    @State private var capturedImage: UIImage?
    @State private var navigateToResults = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background").ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    // Ikon/preview
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

                    // Scanningstips — vises kun før bilde er tatt
                    if capturedImage == nil {
                        VStack(spacing: 6) {
                            ScanTip(icon: "light.max", text: "God belysning — unngå skygger og reflekser")
                            ScanTip(icon: "arrow.up.left.and.arrow.down.right", text: "Kom nær nok til at teksten er leselig")
                            ScanTip(icon: "hand.raised", text: "Hold sigaren stille og bandet flatt mot deg")
                        }
                        .padding(.horizontal, 24)
                    }

                    // Instruksjon
                    VStack(spacing: 8) {
                        Text("Scan sigarband")
                            .font(.title2.bold())
                        Text("Ta bilde av etiketten på sigaren\nfor å identifisere den")
                            .font(.subheadline)
                            .foregroundColor(Color("TextSecondary"))
                            .multilineTextAlignment(.center)
                    }

                    Spacer()

                    // Kamera-knapp
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
                ResultsView(results: scanService.scanResults, ocrText: scanService.extractedText, bandImage: capturedImage)
            }
            // Alltid til ResultsView — aldri direkte til detaljskjermen.
            // Venter med navigasjon til eventuelle form-/wrapper-avklaringer er ferdige.
            .onChange(of: scanService.scanResults) { results in
                guard !results.isEmpty,
                      !scanService.needsShapePhoto,
                      !scanService.needsWrapperPhoto else { return }
                navigateToResults = true
            }
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
            .alert("Feil", isPresented: .constant(scanService.errorMessage != nil)) {
                Button("OK") { scanService.errorMessage = nil }
            } message: {
                Text(scanService.errorMessage ?? "")
            }
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
struct ScanningOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                Text("Analyserer bandet...")
                    .foregroundColor(.white)
                    .font(.headline)
            }
            .padding(32)
            .background(Color("Surface").opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
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
        return picker
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
    var onRetry: () -> Void
    var onManualAdd: () -> Void

    @Environment(\.dismiss) private var dismiss

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

                Spacer()

                ghostCigar
                    .frame(width: 84, height: 84)
                    .background(Circle().fill(Color("Accent").opacity(0.12)))
                    .padding(.bottom, 18)

                Text("Vi fant ikke denne sigaren")
                    .font(.title2.bold())
                    .foregroundColor(Color("TextPrimary"))
                Text("Ingen match i databasen – ennå.")
                    .font(.subheadline)
                    .foregroundColor(Color("TextSecondary"))
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Det kan skyldes:")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color("TextPrimary"))
                    cause("sun.max", "Gjenskinn eller refleks i sigarbeltet")
                    cause("textformat.size", "Lite eller ingen tekst på båndet")
                    cause("scribble.variable", "Utydelig, bøyd eller vinklet tekst")
                    cause("lightbulb", "For svakt lys")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color("Card"))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 24)
                .padding(.top, 22)

                Spacer()

                VStack(spacing: 10) {
                    Button(action: onManualAdd) {
                        Text("Legg den inn manuelt")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color("Accent"))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    Button(action: onRetry) {
                        Text("Prøv på nytt med nytt bilde")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color("Card"))
                            .foregroundColor(Color("Accent"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
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

    // Stiplet «spøkelses-sigar» — sier «finnes ikke i basen ennå».
    private var ghostCigar: some View {
        ZStack {
            Capsule()
                .strokeBorder(style: StrokeStyle(lineWidth: 2.4, dash: [5, 4]))
                .frame(width: 62, height: 18)
            Rectangle()
                .strokeBorder(style: StrokeStyle(lineWidth: 2.2, dash: [4, 3]))
                .frame(width: 11, height: 18)
                .offset(x: 15)
        }
        .rotationEffect(.degrees(-20))
        .foregroundColor(Color("Accent"))
    }
}

// MARK: - Manuell innlegging (bottom sheet, hvit bakgrunn)
// Kombinerer kort motiverende tekst + feltene i ett ark, med merke-autocomplete
// mot eksisterende merker så bidraget kobles riktig i stedet for å lage duplikat.
struct ManualAddSheet: View {
    let image: UIImage?
    let ocrText: String
    var onAdded: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var authService: AuthService

    private let cigarService = CigarService()
    private let humidorService = HumidorService()

    @State private var brand = ""
    @State private var series = ""
    @State private var vitola = ""
    @State private var brandSuggestions: [String] = []
    @State private var brandChosen = false
    @State private var isSaving = false
    @State private var errorText: String?

    private var sheetBackground: Color { colorScheme == .light ? .white : Color("Card") }
    private var fieldBackground: Color { colorScheme == .light ? Color(.systemGray6).opacity(0.5) : Color("Surface") }
    private var canSave: Bool { !brand.trimmingCharacters(in: .whitespaces).isEmpty && !isSaving }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Legg den inn – og hjelp fellesskapet")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color("TextPrimary"))
                    .padding(.top, 8)
                Text("Den havner rett i humidoren din. Vi verifiserer den og legger den i basen, så neste som skanner får treff – takket være deg.")
                    .font(.system(size: 13))
                    .foregroundColor(Color("TextSecondary"))
                    .padding(.top, 5)

                HStack(spacing: 8) {
                    Image(systemName: "rosette")
                        .foregroundColor(Color("Accent"))
                    Text("Teller mot Bidragsyter-merket på profilen din")
                        .font(.system(size: 12))
                        .foregroundColor(Color("Accent"))
                }
                .padding(.horizontal, 11).padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color("Accent").opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .padding(.top, 12)

                // Merke + autocomplete
                fieldLabel("Merke *")
                textField("F.eks. Padrón", text: $brand)
                    .onChange(of: brand) { value in
                        brandChosen = false
                        Task {
                            let s = await cigarService.searchBrands(query: value)
                            await MainActor.run { brandSuggestions = s }
                        }
                    }
                if !brandChosen && !brandSuggestions.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(brandSuggestions, id: \.self) { b in
                            Button {
                                brand = b; brandChosen = true; brandSuggestions = []
                            } label: {
                                HStack {
                                    Text(b).foregroundColor(Color("TextPrimary"))
                                    Spacer()
                                    Text("i basen")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(.systemGreen))
                                }
                                .padding(.horizontal, 12).padding(.vertical, 11)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            Divider().padding(.leading, 12)
                        }
                    }
                    .background(fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.top, 6)
                }

                fieldLabel("Serie / navn")
                textField("F.eks. 1926", text: $series)

                fieldLabel("Vitola / format")
                textField("F.eks. No. 9", text: $vitola)

                if let errorText {
                    Text(errorText).font(.system(size: 13)).foregroundColor(.red).padding(.top, 10)
                }

                Button(action: { Task { await save() } }) {
                    HStack {
                        if isSaving { ProgressView().tint(.white) }
                        Text(isSaving ? "Legger til…" : "Legg til i humidoren").fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color("Accent").opacity(canSave ? 1 : 0.5))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!canSave)
                .padding(.top, 28)
            }
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(sheetBackground.ignoresSafeArea())
    }

    private func fieldLabel(_ t: String) -> some View {
        Text(t).font(.system(size: 13)).foregroundColor(Color("TextSecondary"))
            .padding(.top, 20).padding(.bottom, 7)
    }

    private func textField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .padding(.horizontal, 14).padding(.vertical, 15)
            .background(fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color("TextSecondary").opacity(0.15), lineWidth: 1))
    }

    private func save() async {
        guard let userId = authService.userId else { errorText = "Du må være innlogget."; return }
        let b = brand.trimmingCharacters(in: .whitespaces)
        guard !b.isEmpty else { return }
        isSaving = true; errorText = nil
        do {
            let trimmedOcr = String(ocrText.prefix(200))
            let note = trimmedOcr.isEmpty ? "" : "Fra skann: \(trimmedOcr)"
            let cigar = try await cigarService.createOwnCigar(
                brand: b, series: series, vitola: vitola,
                country: "", wrapper: "", ringGauge: nil, lengthInches: nil,
                note: note, suggest: true
            )
            let humidors = (try? await humidorService.fetchHumidors(userId: userId)) ?? []
            if let h = humidors.first {
                _ = try? await humidorService.addToHumidor(cigarId: cigar.id, userId: userId, humidorId: h.id)
            }
            isSaving = false
            onAdded()
            dismiss()
        } catch {
            isSaving = false
            errorText = "Kunne ikke legge til: \(error.localizedDescription)"
        }
    }
}
