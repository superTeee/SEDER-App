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
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color("Surface"))
                            .frame(width: 300, height: 200)
                            .shadow(color: .black.opacity(0.08), radius: 12)

                        if let image = capturedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 300, height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 24))
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
                            .clipShape(RoundedRectangle(cornerRadius: 14))
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
                            .clipShape(RoundedRectangle(cornerRadius: 14))
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
            .navigationTitle("Vitola")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCameraPicker) {
                ImagePicker(image: $capturedImage, sourceType: .camera) {
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
                ResultsView(results: scanService.scanResults, ocrText: scanService.extractedText)
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
                        .clipShape(RoundedRectangle(cornerRadius: 14))
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
        .sheet(isPresented: $showCamera) {
            ImagePicker(image: $shapeImage, sourceType: .camera) {
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
                        .clipShape(RoundedRectangle(cornerRadius: 14))
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
        .sheet(isPresented: $showCamera) {
            ImagePicker(image: $wrapperImage, sourceType: .camera) {
                if let wrapperImage {
                    Task { await scanService.resolveWrapperAmbiguity(with: wrapperImage) }
                }
            }
        }
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
            .clipShape(RoundedRectangle(cornerRadius: 20))
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
