import SwiftUI
import AVFoundation

// MARK: - MacroCameraView
// Custom kameravisning med makrofokus for nærbilder av sigarbandet.
// Bruker builtInMacroCamera (iPhone 13 Pro+) der tilgjengelig,
// ellers wide angle med autoFocusRangeRestriction = .near.

struct MacroCameraView: UIViewControllerRepresentable {

    @Binding var image: UIImage?
    var onComplete: () -> Void

    func makeUIViewController(context: Context) -> MacroCameraViewController {
        let vc = MacroCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MacroCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, MacroCameraDelegate {
        let parent: MacroCameraView
        init(_ parent: MacroCameraView) { self.parent = parent }

        func didCapture(image: UIImage) {
            parent.image = image
            parent.onComplete()
        }
    }
}

// MARK: - Delegate

protocol MacroCameraDelegate: AnyObject {
    func didCapture(image: UIImage)
}

// MARK: - MacroCameraViewController

class MacroCameraViewController: UIViewController {

    weak var delegate: MacroCameraDelegate?

    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var photoOutput: AVCapturePhotoOutput!
    private var isCapturing = false

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }

    // MARK: Camera Setup

    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo

        guard let device = bestCameraDevice() else { return }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }

            // Makrofokus-konfigurasjon
            try device.lockForConfiguration()

            // Begrens autofokus til nærliggende objekter (makro)
            if device.isAutoFocusRangeRestrictionSupported {
                device.autoFocusRangeRestriction = .near
            }

            // Kontinuerlig autofokus — refokuserer løpende uten at bruker tapper
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }

            // Kontinuerlig eksponering
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }

            device.unlockForConfiguration()

        } catch {
            print("MacroCameraViewController: kamera-feil: \(error)")
            return
        }

        photoOutput = AVCapturePhotoOutput()
        photoOutput.isHighResolutionCaptureEnabled = true
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
    }

    /// Returnerer ultra-wide-kamera for makro (min. fokusavstand ~2 cm).
    /// Wide angle (1x) kan ikke fokusere nærmere enn ~12–15 cm.
    /// Ultra-wide (0.5x) er det eneste kameraet som støtter ekte makrofokus.
    private func bestCameraDevice() -> AVCaptureDevice? {
        // iPhone 11+ har ultra-wide — brukes for makro
        if let ultraWide = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) {
            return ultraWide
        }
        // Fallback for eldre enheter uten ultra-wide
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    }

    // MARK: UI

    private func setupUI() {
        // Avbryt-knapp
        let cancelBtn = makeTextButton(title: "Avbryt", selector: #selector(cancel))
        view.addSubview(cancelBtn)

        // Lukkerknapp (hvit sirkel)
        let shutterBtn = UIButton(type: .custom)
        shutterBtn.backgroundColor = .white
        shutterBtn.layer.cornerRadius = 36
        shutterBtn.layer.borderWidth = 4
        shutterBtn.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
        shutterBtn.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        shutterBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(shutterBtn)

        // Makroindikator
        let macroLabel = makePillLabel(text: "Makrofokus")
        view.addSubview(macroLabel)

        NSLayoutConstraint.activate([
            cancelBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            cancelBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            macroLabel.bottomAnchor.constraint(equalTo: shutterBtn.topAnchor, constant: -20),
            macroLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            shutterBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shutterBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            shutterBtn.widthAnchor.constraint(equalToConstant: 72),
            shutterBtn.heightAnchor.constraint(equalToConstant: 72),
        ])
    }

    private func makeTextButton(title: String, selector: Selector) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17)
        btn.addTarget(self, action: selector, for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }

    private func makePillLabel(text: String) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        container.layer.cornerRadius = 6
        container.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "🔍  \(text)"
        label.textColor = .white
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
        ])
        return container
    }

    // MARK: Actions

    @objc private func cancel() {
        dismiss(animated: true)
    }

    @objc private func capturePhoto() {
        guard !isCapturing else { return }
        isCapturing = true

        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension MacroCameraViewController: AVCapturePhotoCaptureDelegate {

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        isCapturing = false
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }

        DispatchQueue.main.async { [weak self] in
            self?.delegate?.didCapture(image: image)
            self?.dismiss(animated: true)
        }
    }
}
