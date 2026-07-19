import SwiftUI
import MessageUI

// MARK: - MailComposeView
// Wrapper rundt MFMailComposeViewController slik at vi kan åpne
// den innebygde e-post-komponisten direkte fra appen (f.eks. for
// "Gi tilbakemelding på appen" i Profil).

struct MailComposeView: UIViewControllerRepresentable {

    let recipients: [String]
    let subject: String
    let messageBody: String
    var onFinish: (() -> Void)?

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(recipients)
        vc.setSubject(subject)
        vc.setMessageBody(messageBody, isHTML: false)
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onFinish: (() -> Void)?

        init(onFinish: (() -> Void)?) {
            self.onFinish = onFinish
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            controller.dismiss(animated: true) { self.onFinish?() }
        }
    }
}

// MARK: - Feedback helper

enum AppFeedback {

    static let recipient = "theggedal@gmail.com"

    static var subject: String { "Tilbakemelding på SEDER" }

    static var bodyTemplate: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        let systemVersion = UIDevice.current.systemVersion
        let model = UIDevice.current.model

        return """


        ---
        App-versjon: \(version) (\(build))
        iOS: \(systemVersion)
        Enhet: \(model)
        """
    }

    static var mailtoURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = recipient
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: bodyTemplate)
        ]
        return components.url
    }
}
