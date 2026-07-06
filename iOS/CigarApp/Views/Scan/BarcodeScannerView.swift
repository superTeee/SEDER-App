import SwiftUI
import AVFoundation
import AudioToolbox

// MARK: - BarcodeScanView
// Full-screen live-scanner med AVFoundation.
// Vises som .fullScreenCover fra ExploreView.
// Callback onCigarFound(Cigar) kalles når bruker bekrefter et funn.

struct BarcodeScanView: View {

    var onCigarFound: (Cigar) -> Void
    @Environment(\.dismiss) private var dismiss

    @StateObject private var barcodeService = BarcodeService()

    // Kamera-VC eksponert for å starte/stoppe scanning
    @State private var cameraVC: BarcodeCameraVC?

    // Tilstandsmaskin
    @State private var scanState: ScanState = .scanning
    @State private var torchOn = false
    @State private var showUnknownBarcodeView = false

    // MARK: - Enum

    enum ScanState {
        case scanning
        case processing(barcode: String)
        case foundInDB(cigar: Cigar, count: Int)
        case foundViaSearch(cigar: Cigar, barcode: String, apiTitle: String)
        case notFound(barcode: String, apiTitle: String?)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Kamera-feed (svart mens tillatelse lastes)
            BarcodeCameraRepresentable(
                onBarcodeDetected: { barcode in
                    guard case .scanning = scanState else { return }
                    handleDetected(barcode)
                },
                torchOn: torchOn,
                onVCReady: { vc in cameraVC = vc }
            )
            .ignoresSafeArea()

            // Mørkt overlay med visuelt søkefelt
            ViewfinderOverlay(isProcessing: {
                if case .processing = scanState { return true }
                return false
            }())
            .ignoresSafeArea()

            // Kamera-tillatelse nektet
            if case .scanning = scanState {
                EmptyView()
            }

            // Kontroller (øverst)
            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Button { toggleTorch() } label: {
                        Image(systemName: torchOn ? "bolt.fill" : "bolt.slash.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(torchOn ? Color("Accent") : .white)
                            .frame(width: 44, height: 44)
                            .background(.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)
                Spacer()
            }
        }
        // Resultat-sheet (DB-match og API-match)
        .sheet(isPresented: resultSheetBinding) {
            BarcodeResultSheet(
                scanState: scanState,
                barcodeService: barcodeService,
                onConfirm: { cigar in
                    dismiss()
                    onCigarFound(cigar)
                },
                onSearchManually: {
                    withAnimation { scanState = stateAsNotFound() }
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .onDisappear {
                // Bruker avbrøt — gjenoppta scanning
                if case .scanning = scanState { cameraVC?.resumeScanning() }
            }
        }
        // Ukjent strekkode — manuelt søk
        .sheet(isPresented: unknownSheetBinding, onDismiss: {
            withAnimation { scanState = .scanning }
            cameraVC?.resumeScanning()
        }) {
            if case .notFound(let barcode, _) = scanState {
                UnknownBarcodeView(
                    barcode: barcode,
                    barcodeService: barcodeService,
                    onLinked: { cigar in
                        dismiss()
                        onCigarFound(cigar)
                    }
                )
            }
        }
    }

    // MARK: - Bindings

    private var resultSheetBinding: Binding<Bool> {
        Binding {
            if case .foundInDB = scanState { return true }
            if case .foundViaSearch = scanState { return true }
            return false
        } set: { showing in
            if !showing, case .foundInDB = scanState { scanState = .scanning }
            if !showing, case .foundViaSearch = scanState { scanState = .scanning }
        }
    }

    private var unknownSheetBinding: Binding<Bool> {
        Binding {
            if case .notFound = scanState { return true }
            return false
        } set: { showing in
            if !showing { scanState = .scanning }
        }
    }

    // MARK: - Logikk

    private func handleDetected(_ barcode: String) {
        // Haptisk bekreftelse
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

        withAnimation { scanState = .processing(barcode: barcode) }

        Task {
            let result = await barcodeService.lookupBarcode(barcode)
            await MainActor.run {
                switch result {
                case .foundInDB(let cigar, let count):
                    withAnimation { scanState = .foundInDB(cigar: cigar, count: count) }
                case .foundViaSearch(let cigar, let bcode, let title):
                    withAnimation { scanState = .foundViaSearch(cigar: cigar, barcode: bcode, apiTitle: title) }
                case .notFound(let bcode, let title):
                    withAnimation { scanState = .notFound(barcode: bcode, apiTitle: title) }
                }
            }
        }
    }

    private func toggleTorch() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        try? device.lockForConfiguration()
        torchOn.toggle()
        device.torchMode = torchOn ? .on : .off
        device.unlockForConfiguration()
    }

    private func stateAsNotFound() -> ScanState {
        switch scanState {
        case .foundViaSearch(_, let barcode, _):
            return .notFound(barcode: barcode, apiTitle: nil)
        case .notFound(let barcode, let title):
            return .notFound(barcode: barcode, apiTitle: title)
        default:
            return .scanning
        }
    }
}

// MARK: - BarcodeResultSheet

private struct BarcodeResultSheet: View {

    let scanState: BarcodeScanView.ScanState
    let barcodeService: BarcodeService
    var onConfirm: (Cigar) -> Void
    var onSearchManually: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isSaving = false

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color(.separator))
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 20)

            switch scanState {
            case .foundInDB(let cigar, let count):
                dbMatchContent(cigar: cigar, confirmedCount: count)

            case .foundViaSearch(let cigar, let barcode, _):
                apiMatchContent(cigar: cigar, barcode: barcode)

            default:
                EmptyView()
            }
        }
        .background(Color("Card"))
    }

    // DB-match: rett til sigar
    private func dbMatchContent(cigar: Cigar, confirmedCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 18))
                Text("Sigar funnet")
                    .font(.headline)
                Spacer()
                Text("\(confirmedCount) bekreftelse\(confirmedCount == 1 ? "" : "r")")
                    .font(.caption)
                    .foregroundColor(Color(.secondaryLabel))
            }

            cigarInfoCard(cigar: cigar)

            Button {
                onConfirm(cigar)
            } label: {
                Text("Vis sigar")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color("Accent"))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
    }

    // API-match: trenger brukerbekreftelse
    private func apiMatchContent(cigar: Cigar, barcode: String) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 8) {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(Color("Accent"))
                    .font(.system(size: 18))
                Text("Mulig treff")
                    .font(.headline)
                Spacer()
            }

            cigarInfoCard(cigar: cigar)

            VStack(spacing: 10) {
                Button {
                    guard !isSaving else { return }
                    isSaving = true
                    Task {
                        try? await barcodeService.saveBarcode(barcode, cigarID: cigar.id, source: "user")
                        onConfirm(cigar)
                    }
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView().tint(.white)
                        }
                        Text("Ja, dette er riktig sigar")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color("Accent"))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                Button {
                    dismiss()
                    onSearchManually()
                } label: {
                    Text("Nei, søk manuelt")
                        .font(.system(size: 15))
                        .foregroundColor(Color(.secondaryLabel))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
    }

    private func cigarInfoCard(cigar: Cigar) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "flame.fill")
                .font(.system(size: 28))
                .foregroundColor(Color("Accent").opacity(0.7))
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(cigar.brand)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(.label))
                if let series = cigar.series {
                    Text(series)
                        .font(.system(size: 14))
                        .foregroundColor(Color(.secondaryLabel))
                }
                if let vitola = cigar.vitola {
                    Text(vitola)
                        .font(.caption)
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }

            Spacer()

            if let rating = cigar.avgRating {
                VStack(spacing: 2) {
                    Text(String(format: "%.1f", rating))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color("Accent"))
                    Text("/ 10")
                        .font(.caption2)
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - ViewfinderOverlay

private struct ViewfinderOverlay: View {

    let isProcessing: Bool

    var body: some View {
        GeometryReader { geo in
            let rectW  = geo.size.width - 56
            let rectH  = rectW * 0.55
            let rectMidX = geo.size.width  / 2
            let rectMidY = geo.size.height / 2 - 40

            ZStack {
                // Halvtransparent bakgrunn med hull
                Rectangle()
                    .fill(.black.opacity(0.55))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .frame(width: rectW, height: rectH)
                            .position(x: rectMidX, y: rectMidY)
                            .blendMode(.destinationOut)
                    )
                    .compositingGroup()

                // Hjørnemarkeringer
                CornerMarkers(size: CGSize(width: rectW, height: rectH))
                    .position(x: rectMidX, y: rectMidY)
                    .foregroundColor(Color("Accent"))

                // Status-tekst
                VStack(spacing: 8) {
                    Spacer().frame(height: rectMidY + rectH / 2 + 24)

                    if isProcessing {
                        HStack(spacing: 8) {
                            ProgressView().tint(.white).scaleEffect(0.85)
                            Text("Søker…")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                        }
                    } else {
                        Text("Rett strekkoden mot kameraet")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

// MARK: - CornerMarkers

private struct CornerMarkers: View {
    let size: CGSize
    private let armLen: CGFloat = 24
    private let lineW:  CGFloat = 3

    var body: some View {
        Canvas { ctx, _ in
            let w = size.width
            let h = size.height
            let half = CGSize(width: w / 2, height: h / 2)
            let corners: [(CGPoint, [CGPoint])] = [
                (CGPoint(x: -half.width, y: -half.height),
                 [CGPoint(x: armLen, y: 0), CGPoint(x: 0, y: armLen)]),
                (CGPoint(x:  half.width, y: -half.height),
                 [CGPoint(x: -armLen, y: 0), CGPoint(x: 0, y: armLen)]),
                (CGPoint(x:  half.width, y:  half.height),
                 [CGPoint(x: -armLen, y: 0), CGPoint(x: 0, y: -armLen)]),
                (CGPoint(x: -half.width, y:  half.height),
                 [CGPoint(x: armLen, y: 0), CGPoint(x: 0, y: -armLen)]),
            ]
            for (corner, arms) in corners {
                for arm in arms {
                    var path = Path()
                    path.move(to: corner)
                    path.addLine(to: CGPoint(x: corner.x + arm.x, y: corner.y + arm.y))
                    ctx.stroke(path, with: .foreground,
                               style: StrokeStyle(lineWidth: lineW, lineCap: .round))
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - BarcodeCameraRepresentable

struct BarcodeCameraRepresentable: UIViewControllerRepresentable {

    var onBarcodeDetected: (String) -> Void
    var torchOn: Bool
    var onVCReady: (BarcodeCameraVC) -> Void

    func makeUIViewController(context: Context) -> BarcodeCameraVC {
        let vc = BarcodeCameraVC()
        vc.onBarcodeDetected = onBarcodeDetected
        DispatchQueue.main.async { onVCReady(vc) }
        return vc
    }

    func updateUIViewController(_ vc: BarcodeCameraVC, context: Context) {
        vc.onBarcodeDetected = onBarcodeDetected
        vc.setTorch(torchOn)
    }
}

// MARK: - BarcodeCameraVC

final class BarcodeCameraVC: UIViewController {

    var onBarcodeDetected: ((String) -> Void)?

    private var captureSession:  AVCaptureSession?
    private var previewLayer:    AVCaptureVideoPreviewLayer?
    private var captureDevice:   AVCaptureDevice?
    private var metadataOutput:  AVCaptureMetadataOutput?
    private var baseZoomFactor:  CGFloat = 1.0
    private var isProcessing = false
    private var focusResetTimer: Timer?

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        view.addGestureRecognizer(pinch)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tap)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        // Begrens metadata-deteksjon til søkefelt-boksen — hjelper AF å låse seg
        updateMetadataROI()
    }

    // MARK: Offentlig API

    func resumeScanning() {
        isProcessing = false
        startSession()
    }

    func setTorch(_ on: Bool) {
        guard let device = captureDevice,
              device.hasTorch,
              device.isTorchAvailable else { return }
        try? device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }

    // MARK: rectOfInterest — synk med ViewfinderOverlay-boks

    private func updateMetadataROI() {
        guard let preview = previewLayer,
              let output  = metadataOutput else { return }
        let bounds = view.bounds
        let rectW  = bounds.width - 56
        let rectH  = rectW * 0.55
        let rectX  = (bounds.width  - rectW) / 2
        let rectY  = bounds.height / 2 - 40 - rectH / 2
        let layerRect = CGRect(x: rectX, y: rectY, width: rectW, height: rectH)
        output.rectOfInterest = preview.metadataOutputRectConverted(fromLayerRect: layerRect)
    }

    // MARK: Zoom (klyp)

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let device = captureDevice else { return }
        if gesture.state == .began {
            baseZoomFactor = device.videoZoomFactor
        }
        let maxZoom = min(device.activeFormat.videoMaxZoomFactor, 6.0)
        let desired = max(1.0, min(maxZoom, baseZoomFactor * gesture.scale))
        try? device.lockForConfiguration()
        device.videoZoomFactor = desired
        device.unlockForConfiguration()
    }

    // MARK: Trykk-for-fokus

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let device = captureDevice,
              let preview = previewLayer else { return }
        let screenPoint = gesture.location(in: view)
        let devicePoint = preview.captureDevicePointConverted(fromLayerPoint: screenPoint)

        try? device.lockForConfiguration()
        if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
            device.focusPointOfInterest = devicePoint
            device.focusMode = .autoFocus
        }
        if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose) {
            device.exposurePointOfInterest = devicePoint
            device.exposureMode = .autoExpose
        }
        device.unlockForConfiguration()

        // Gå tilbake til kontinuerlig AF etter 2s
        focusResetTimer?.invalidate()
        focusResetTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.resetToContinuousFocus()
        }
    }

    private func resetToContinuousFocus() {
        guard let device = captureDevice else { return }
        try? device.lockForConfiguration()
        if device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
            device.focusMode = .continuousAutoFocus
        }
        if device.isExposureModeSupported(.continuousAutoExposure) {
            device.exposureMode = .continuousAutoExposure
        }
        device.unlockForConfiguration()
    }

    // Kalles av AVCaptureDevice.subjectAreaDidChangeNotification —
    // iOS sin innebygde måte å re-fokusere når scenen endrer seg.
    @objc private func subjectAreaDidChange() {
        resetToContinuousFocus()
    }

    // MARK: Privat oppsett

    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .high

        // Bruk ultra-wide (0.5x) som kan fokusere ned til ~2 cm —
        // samme kamera som MacroCameraView bruker for beltebilde.
        // Wide angle (1x) sliter med nærfokus på sigarbånd og strekkoder.
        // Fallback til wide angle på enheter uten ultra-wide (iPhone 10 og eldre).
        let device = AVCaptureDevice.default(.builtInUltraWideCamera,
                                             for: .video,
                                             position: .back)
                  ?? AVCaptureDevice.default(.builtInWideAngleCamera,
                                             for: .video,
                                             position: .back)
                  ?? AVCaptureDevice.default(for: .video)

        guard
            let device,
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else { return }

        // Fokus: nær-fokus + kontinuerlig AF, samme oppsett som MacroCameraView.
        // Start på 2x zoom slik at synsfeltet ligner wide-angle (ultra-wide er 0.5x).
        // .near-restriksjonen sørger for at AF låser seg på strekkoder tett inntil
        // uten å "jakte" på bakgrunnen.
        // isSubjectAreaChangeMonitoringEnabled sender en notifikasjon når motivet
        // endrer seg, og vi re-fokuserer da til midtpunktet.
        try? device.lockForConfiguration()
        device.videoZoomFactor = 2.0
        if device.isAutoFocusRangeRestrictionSupported {
            device.autoFocusRangeRestriction = .near
        }
        if device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
            device.focusMode = .continuousAutoFocus
        }
        if device.isExposureModeSupported(.continuousAutoExposure) {
            device.exposurePointOfInterest = CGPoint(x: 0.5, y: 0.5)
            device.exposureMode = .continuousAutoExposure
        }
        device.isSubjectAreaChangeMonitoringEnabled = true
        device.unlockForConfiguration()
        captureDevice = device

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(subjectAreaDidChange),
            name: AVCaptureDevice.subjectAreaDidChangeNotification,
            object: device
        )

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)

        // Støttede formater: EAN-13 (vanligst), UPC-A/E, Code128, QR
        output.metadataObjectTypes = [.ean13, .ean8, .upce, .code128, .qr]
        output.setMetadataObjectsDelegate(self, queue: .main)
        metadataOutput = output

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)

        captureSession = session
        previewLayer   = preview
    }

    private func startSession() {
        guard let session = captureSession, !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
    }

    private func stopSession() {
        focusResetTimer?.invalidate()
        focusResetTimer = nil
        captureSession?.stopRunning()
    }
}

// MARK: AVCaptureMetadataOutputObjectsDelegate

extension BarcodeCameraVC: AVCaptureMetadataOutputObjectsDelegate {

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard
            !isProcessing,
            let obj   = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
            let value = obj.stringValue
        else { return }

        isProcessing = true
        stopSession()
        onBarcodeDetected?(value)
    }
}
