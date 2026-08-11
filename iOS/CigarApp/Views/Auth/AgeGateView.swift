import SwiftUI

// MARK: - AgeGateView
// Aldersbekreftelse — vises kun én gang (lagres i UserDefaults via @AppStorage
// i CigarAppApp). Helt uavhengig av innlogging, siden appen nå kan brukes
// uten konto (scan + søk) helt til man vil lagre i humidoren.

struct AgeGateView: View {

    @State private var blocked = false
    var onVerified: () -> Void

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            if blocked {
                AgeBlockedView(onBack: { blocked = false })
            } else {
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

                    AgeVerificationView(onVerify: onVerified, onUnder18: { blocked = true })

                    Spacer()

                    Text("Tobakk innebærer helserisiko. SEDER gir ingen helseråd og oppfordrer ikke til bruk.\nAppen er kun for personer over 18 år – kjøp og promotering av tobakk er ikke en del av appen.")
                        .font(.caption2)
                        .foregroundColor(Color("TextSecondary"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                }
            }
        }
    }
}

// MARK: - Aldersbekreftelse (egenerklæring med ja/nei)
struct AgeVerificationView: View {
    var onVerify: () -> Void
    var onUnder18: () -> Void

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

            Button(action: onUnder18) {
                Text("Jeg er under 18 år")
                    .font(.subheadline)
                    .foregroundColor(Color("TextSecondary"))
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Blokkeringsskjerm for under 18
struct AgeBlockedView: View {
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "hand.raised.fill")
                .font(.system(size: 46))
                .foregroundColor(Color("Accent"))

            Text("Vi ses om noen år")
                .font(.title2.bold())
                .foregroundColor(Color("TextPrimary"))

            Text("SEDER er en digital humidor og smaksjournal laget for voksne sigarentusiaster. Innholdet er kun ment for personer over 18 år, så vi kan dessverre ikke gi deg tilgang ennå.\n\nDu er hjertelig velkommen tilbake når du fyller 18.")
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 32)

            Spacer()

            Button(action: onBack) {
                Text("Tilbake")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color("Accent"))
            }
            .padding(.bottom, 32)
        }
    }
}
