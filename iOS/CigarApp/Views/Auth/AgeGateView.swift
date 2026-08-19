import SwiftUI

// MARK: - LegalAge
// Aldersgrensen for tobakk er ikke lik overalt. Norge og det meste av Europa
// har 18 år, mens USA har 21 år føderalt siden desember 2019 — og den regelen
// gjelder eksplisitt også sigarer. Vi leser enhetens region og krever den
// grensen som faktisk gjelder der brukeren befinner seg, i stedet for å
// hardkode ett tall for hele verden.
//
// Legger du til nye markeder: sjekk landets faktiske regel FØR du legger det
// inn i listen under. Står landet ikke i listen, faller det tilbake på 18.
enum LegalAge {

    /// Jurisdiksjoner med 21-årsgrense: USA + amerikanske territorier.
    private static let age21Regions: Set<String> = [
        "US",   // USA – føderal Tobacco 21 (des. 2019), omfatter sigarer
        "PR",   // Puerto Rico
        "GU",   // Guam
        "VI",   // De amerikanske jomfruøyene
        "AS",   // Amerikansk Samoa
        "MP"    // Nord-Marianene
    ]

    /// Minstealder for brukerens region. 21 i USA, ellers 18.
    static var minimum: Int {
        let region = Locale.current.region?.identifier ?? ""
        return age21Regions.contains(region) ? 21 : 18
    }
}

// MARK: - AgeGateView
// Aldersbekreftelse — vises kun én gang (lagres i UserDefaults via @AppStorage
// i CigarAppApp). Helt uavhengig av innlogging, siden appen nå kan brukes
// uten konto (scan + søk) helt til man vil lagre i humidoren.

struct AgeGateView: View {

    @State private var blocked = false
    var onVerified: () -> Void

    private var minAge: Int { LegalAge.minimum }

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            if blocked {
                AgeBlockedView(minAge: minAge, onBack: { blocked = false })
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

                    AgeVerificationView(
                        minAge: minAge,
                        onVerify: onVerified,
                        onUnderAge: { blocked = true }
                    )

                    Spacer()

                    Text("Tobakk innebærer helserisiko. SEDER gir ingen helseråd og oppfordrer ikke til bruk.\nAppen er kun for personer over \(minAge) år – kjøp og promotering av tobakk er ikke en del av appen.")
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
    var minAge: Int = LegalAge.minimum
    var onVerify: () -> Void
    var onUnderAge: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Bekreft alder")
                .font(.title3.bold())
            Text("Du må være \(minAge) år eller eldre for å bruke SEDER")
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)

            Button(action: onVerify) {
                Text("Jeg er over \(minAge) år")
                    .fontWeight(.semibold)
                    .frame(width: 240)
                    .padding()
                    .background(Color("Accent"))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            Button(action: onUnderAge) {
                Text("Jeg er under \(minAge) år")
                    .font(.subheadline)
                    .foregroundColor(Color("TextSecondary"))
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Blokkeringsskjerm for under aldersgrensen
struct AgeBlockedView: View {
    var minAge: Int = LegalAge.minimum
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

            Text("SEDER er en digital humidor og smaksjournal laget for voksne sigarentusiaster. Innholdet er kun ment for personer over \(minAge) år, så vi kan dessverre ikke gi deg tilgang ennå.\n\nDu er hjertelig velkommen tilbake når du fyller \(minAge).")
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
