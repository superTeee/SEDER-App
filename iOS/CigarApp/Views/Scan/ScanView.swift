import SwiftUI
import AVFoundation

// MARK: - ScanView
// Kameravisning for å scanne sigarbandet

struct ScanView: View {

    @StateObject private var scanService = ScanService()
    @State private var showImagePicker = false
    @State private var capturedImage: UIImage?
    @State private var navigateToResults = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera

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
                                    .foregroundColor(Color("Accent"))
                                Text("Hold bandet innenfor rammen")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // Instruksjon
                    VStack(spacing: 8) {
                        Text("Scan sigarband")
                            .font(.title2.bold())
                        Text("Ta bilde av etiketten på sigaren\nfor å identifisere den")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
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
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $capturedImage, sourceType: sourceType) {
                    if let image = capturedImage {
                        Task { await scanService.scanBandImage(image) }
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToResults) {
                ResultsView(results: scanService.scanResults, ocrText: scanService.extractedText)
            }
            .onChange(of: scanService.scanResults) { results in
                if !results.isEmpty { navigateToResults = true }
            }
            .alert("Feil", isPresented: .constant(scanService.errorMessage != nil)) {
                Button("OK") { scanService.errorMessage = nil }
            } message: {
                Text(scanService.errorMessage ?? "")
            }
        }
    }

    private func openCamera() {
        sourceType = .camera
        showImagePicker = true
    }

    private func openPhotoLibrary() {
        sourceType = .photoLibrary
        showImagePicker = true
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
