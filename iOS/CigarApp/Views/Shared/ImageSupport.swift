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

// MARK: - ImageCropper (vår egen BandCropView – ikke Mantis)
// SwiftUI-innpakning rundt Mantis sin crop-skjerm. Presenteres i en
// fullScreenCover. `ratio` = bredde/høyde (1 = kvadrat), nil = fritt utsnitt.
struct ImageCropper: View {
    let image: UIImage
    var ratio: Double? = nil          // beholdt for kompatibilitet – crop er fri-form nå
    var onCrop: (UIImage) -> Void
    var onCancel: () -> Void = {}

    var body: some View {
        BandCropView(image: image, onCancel: onCancel, onCrop: onCrop)
    }
}

// Innkommende bilde + ønsket forhold, brukt for å presentere crop-arket.
struct CropRequest: Identifiable {
    let id = UUID()
    let image: UIImage
    let ratio: Double?
}

// MARK: - ScoreBadge
// ÉN samkjørt scoring-badge for hele appen: firkantet med 2px radius og lys
// latte bakgrunn. Brukes overalt en poengsum vises (Utforsk, profil, journal,
// humidor, skann osv.) så de aldri ser forskjellige ut igjen.
struct ScoreBadge: View {
    let text: String
    var size: CGFloat = 14

    // Lys latte bakgrunn + mørk kaffebrun tekst (fast, uavhengig av tema).
    static let latte = Color(hex: "#EADFC9")
    static let ink   = Color(hex: "#5C4A2C")

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .semibold))
            .foregroundColor(Color("TextPrimary"))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color("Accent"), lineWidth: 1.2))
    }
}
