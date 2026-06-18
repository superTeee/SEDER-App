import SwiftUI

// MARK: - PINSetupView
// Lar brukeren velge en 4-sifret kode for raskere pålogging.
// Koden tastes inn to ganger (for å bekrefte) før den lagres i Keychain.

struct PINSetupView: View {

    @EnvironmentObject var pinService: PINService
    @Environment(\.dismiss) private var dismiss

    @State private var step = 1 // 1 = velg kode, 2 = bekreft kode
    @State private var firstEntry = ""
    @State private var pin = ""
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "lock.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Color("TextPrimary"))

                Text(step == 1 ? "Velg en 4-sifret kode" : "Bekreft koden")
                    .font(.title3.bold())

                Text(step == 1
                     ? "Bruk koden for raskere pålogging neste gang du åpner appen"
                     : "Skriv koden én gang til")
                    .font(.subheadline)
                    .foregroundColor(Color("TextSecondary"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                PINDotsView(filled: pin.count)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Spacer()

                PINKeypad(pin: $pin, onComplete: handleEntry)

                Button("Avbryt") { dismiss() }
                    .font(.subheadline)
                    .foregroundColor(Color("TextSecondary"))
                    .padding(.bottom, 16)
            }
        }
    }

    private func handleEntry() {
        if step == 1 {
            firstEntry = pin
            pin = ""
            step = 2
        } else {
            if pin == firstEntry {
                pinService.setPIN(pin)
                dismiss()
            } else {
                errorMessage = "Kodene var ikke like. Prøv igjen."
                pin = ""
                firstEntry = ""
                step = 1
            }
        }
    }
}
