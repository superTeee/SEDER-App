import SwiftUI

// MARK: - AgeGateView
// Aldersbekreftelse — vises kun én gang (lagres i UserDefaults via @AppStorage
// i CigarAppApp). Helt uavhengig av innlogging, siden appen nå kan brukes
// uten konto (scan + søk) helt til man vil lagre i humidoren.

struct AgeGateView: View {

    @State private var birthYear = ""
    @State private var showError = false
    var onVerified: () -> Void

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 8) {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    Text("Vitola")
                        .font(.largeTitle.bold())
                        .foregroundColor(Color("TextPrimary"))
                    Text("Din digitale humidor")
                        .font(.subheadline)
                        .foregroundColor(Color("TextSecondary"))
                }

                Spacer()

                AgeVerificationView(birthYear: $birthYear, showError: $showError, onVerify: verify)

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

    private func verify() {
        guard let year = Int(birthYear) else {
            showError = true
            return
        }
        let currentYear = Calendar.current.component(.year, from: Date())
        let age = currentYear - year

        if age >= 18 {
            onVerified()
        } else {
            showError = true
        }
    }
}

// MARK: - Aldersbekreftelse (skjema)
struct AgeVerificationView: View {
    @Binding var birthYear: String
    @Binding var showError: Bool
    var onVerify: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Bekreft alder")
                .font(.title3.bold())
            Text("Du må være 18 år eller eldre for å bruke Vitola")
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)

            TextField("Fødselsår (f.eks. 1990)", text: $birthYear)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)

            if showError {
                Text("Du må være over 18 år for å bruke appen.")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Button(action: onVerify) {
                Text("Bekreft")
                    .fontWeight(.semibold)
                    .frame(width: 200)
                    .padding()
                    .background(Color("Accent"))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(.horizontal, 24)
    }
}
