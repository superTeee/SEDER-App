import SwiftUI
import UIKit
import Mantis

// MARK: - Bilde-nedskalering
// Skalerer ned og komprimerer et bilde før opplasting. Et 5 MB-foto blir
// typisk 150–300 KB, som gjør både opplasting og nedlasting mye raskere.
func downscaledJPEG(_ data: Data, maxDim: CGFloat = 1400, quality: CGFloat = 0.75) -> Data {
    guard let img = UIImage(data: data) else { return data }
    let longest = max(img.size.width, img.size.height)
    let scale = min(1, maxDim / longest)
    guard scale < 1 else {
        return img.jpegData(compressionQuality: quality) ?? data
    }
    let newSize = CGSize(width: img.size.width * scale, height: img.size.height * scale)
    let resized = UIGraphicsImageRenderer(size: newSize).image { _ in
        img.draw(in: CGRect(origin: .zero, size: newSize))
    }
    return resized.jpegData(compressionQuality: quality) ?? data
}

extension UIImage {
    /// Nedskalert JPEG-data fra et UIImage (f.eks. etter crop).
    func downscaledJPEGData(maxDim: CGFloat = 1400, quality: CGFloat = 0.75) -> Data? {
        downscaledJPEG(jpegData(compressionQuality: 1.0) ?? Data(), maxDim: maxDim, quality: quality)
    }
}

// MARK: - ImageCropper (Mantis)
// SwiftUI-innpakning rundt Mantis sin crop-skjerm. Presenteres i en
// fullScreenCover. `ratio` = bredde/høyde (1 = kvadrat), nil = fritt utsnitt.
struct ImageCropper: UIViewControllerRepresentable {
    let image: UIImage
    var ratio: Double? = nil
    var onCrop: (UIImage) -> Void
    var onCancel: () -> Void = {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> Mantis.CropViewController {
        var config = Mantis.Config()
        if let ratio {
            config.presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: ratio)
        }
        let cropVC = Mantis.cropViewController(image: image, config: config)
        cropVC.delegate = context.coordinator
        return cropVC
    }

    func updateUIViewController(_ uiViewController: Mantis.CropViewController, context: Context) {}

    class Coordinator: NSObject, CropViewControllerDelegate {
        let parent: ImageCropper
        init(_ parent: ImageCropper) { self.parent = parent }

        func cropViewControllerDidCrop(_ cropViewController: Mantis.CropViewController,
                                       cropped: UIImage,
                                       transformation: Transformation,
                                       cropInfo: CropInfo) {
            parent.onCrop(cropped)
        }

        func cropViewControllerDidCancel(_ cropViewController: Mantis.CropViewController,
                                         original: UIImage) {
            parent.onCancel()
        }

        func cropViewControllerDidFailToCrop(_ cropViewController: Mantis.CropViewController,
                                             original: UIImage) {}
        func cropViewControllerDidBeginResize(_ cropViewController: Mantis.CropViewController) {}
        func cropViewControllerDidEndResize(_ cropViewController: Mantis.CropViewController,
                                            original: UIImage, cropInfo: CropInfo) {}
    }
}

// Innkommende bilde + ønsket forhold, brukt for å presentere crop-arket.
struct CropRequest: Identifiable {
    let id = UUID()
    let image: UIImage
    let ratio: Double?
}
