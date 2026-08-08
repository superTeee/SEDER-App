import SwiftUI
import UIKit
import LinkPresentation

// MARK: - Delings-ark (systemets share sheet)
//
// Det sosiale laget (feed, innlegg, aktivitetsstrøm, deling til fellesskap) er
// fjernet for App Store-samsvar (retningslinje 1.4.3). Det eneste som er beholdt
// her er den generelle delings-hjelperen som journal, sigar-detalj og
// hurtighandlinger bruker til å dele en LENKE via iOS sitt eget share sheet.

struct IOSShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        // Bytt ut rå URL-er med en kilde som leverer ferdig LPLinkMetadata.
        // Uten dette henter iOS lenke-forhåndsvisningen over nett FØR arket
        // tegnes ferdig → merkbart lag. Med ferdig metadata åpner arket umiddelbart.
        let title = items.compactMap { $0 as? String }.first ?? "SEDER"
        let prepared: [Any] = items.map { item in
            if let url = item as? URL {
                return ShareLinkSource(url: url, title: title)
            }
            return item
        }
        return UIActivityViewController(activityItems: prepared, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Leverer lenke-metadata lokalt slik at UIActivityViewController slipper
// nettverkshentingen som ellers forsinker at delings-arket vises.
final class ShareLinkSource: NSObject, UIActivityItemSource {
    let url: URL
    let title: String

    init(url: URL, title: String) {
        self.url = url
        self.title = title
    }

    func activityViewControllerPlaceholderItem(_ controller: UIActivityViewController) -> Any { url }

    func activityViewController(_ controller: UIActivityViewController,
                                itemForActivityType activityType: UIActivity.ActivityType?) -> Any? { url }

    func activityViewControllerLinkMetadata(_ controller: UIActivityViewController) -> LPLinkMetadata? {
        let md = LPLinkMetadata()
        md.originalURL = url
        md.url = url
        md.title = title
        return md
    }
}
