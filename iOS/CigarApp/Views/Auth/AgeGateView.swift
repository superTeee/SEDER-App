import SwiftUI

// MARK: - AgeGateView
// Aldersbekreftelse — vises kun én gang (lagres i UserDefaults via @AppStorage
// i CigarAppApp). Helt uavhengig av innlogging, siden appen nå kan brukes
// uten konto (scan + søk) helt til man vil lagre i humidoren.

struct AgeGateView: View {

    var onVerified: () -> Void

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 8) {
                    Image("VitolaLogo")   // Ny SEDER-lockup
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 190, maxHeight: 150)
                    Text("Din digitale humidor")
                        .font(.subheadline)
                        .foregroundColor(Color("TextSecondary"))
                }

                Spacer()

                AgeVerificationView(onVerify: onVerified)

                Spacer()

                Text("Appen er kun for personer over 18 år.\nKjøp og promotering av tobakk er ikke en del av appen.")
                    .font(.caption2)
                    .foregroundColor(Color("TextSecondary"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
        }
    }
}

// MARK: - Aldersbekreftelse (én-trykks egenerklæring)
struct AgeVerificationView: View {
    var onVerify: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Bekreft alder")
                .font(.title3.bold())
            Text("Du må være 18 år eller eldre for å bruke SEDER")
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)

            Button(action: onVerify) {
                Text("Jeg er over 18 år")
                    .fontWeight(.semibold)
                    .frame(width: 240)
                    .padding()
                    .background(Color("Accent"))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(.horizontal, 24)
    }
}
