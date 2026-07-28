import SwiftUI

// MARK: - PrivacyConsentView
// Vises én gang etter aldersbekreftelse.
// Bruker må huke av + trykke "Godta" før de får tilgang til appen.

struct PrivacyConsentView: View {

    var onAccepted: () -> Void

    @State private var hasRead   = false
    @State private var accepted  = false
    @State private var showPolicy = false

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: Header
                VStack(spacing: 8) {
                    Image("VitolaLogo")   // Ny SEDER-lockup
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 140, maxHeight: 104)
                        .padding(.top, 56)

                    Text("Før du fortsetter")
                        .font(.title2.bold())
                        .foregroundColor(Color("TextPrimary"))
                        .padding(.top, 12)

                    Text("Les personvernerklæringen vår og godta vilkårene for å bruke SEDER.")
                        .font(.subheadline)
                        .foregroundColor(Color("TextSecondary"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 4)
                }

                Spacer()

                // MARK: Privacy Policy preview card
                Button(action: { showPolicy = true }) {
                    HStack(spacing: 14) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color("Accent"))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Personvernerklæring")
                                .font(.subheadline.bold())
                                .foregroundColor(Color("TextPrimary"))
                            Text("Trykk for å lese")
                                .font(.caption)
                                .foregroundColor(Color("TextSecondary"))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundColor(Color("TextSecondary"))
                    }
                    .padding(16)
                    .background(Color("Background"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color("TextSecondary").opacity(0.2), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .padding(.horizontal, 24)

                // MARK: Avkrysningsboks
                Button(action: { accepted.toggle() }) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: accepted ? "checkmark.square.fill" : "square")
                            .font(.system(size: 22))
                            .foregroundColor(accepted ? Color("Accent") : Color("TextSecondary"))

                        Text("Jeg har lest og godtar personvernerklæringen til SEDER")
                            .font(.subheadline)
                            .foregroundColor(Color("TextPrimary"))
                            .multilineTextAlignment(.leading)

                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
                .buttonStyle(.plain)

                Spacer()

                // MARK: Godta-knapp
                VStack(spacing: 12) {
                    Button(action: {
                        if accepted { onAccepted() }
                    }) {
                        Text("Godta og fortsett")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(accepted ? Color("Accent") : Color("TextSecondary").opacity(0.2))
                            .foregroundColor(accepted ? .white : Color("TextSecondary"))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .disabled(!accepted)
                    .animation(.easeInOut(duration: 0.15), value: accepted)

                    Text("Appen er kun for personer over 18 år.")
                        .font(.caption2)
                        .foregroundColor(Color("TextSecondary"))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showPolicy) {
            PrivacyPolicySheet()
        }
    }
}

// MARK: - Personvernerklæring (inline sheet)
struct PrivacyPolicySheet: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    policySection(
                        title: "Hva vi samler inn",
                        body: "E-postadresse (for innlogging), navn/kallenavn (valgfritt), sigarnotater og vurderinger du selv legger inn, og by/sted (valgfritt)."
                    )

                    policySection(
                        title: "Hva vi ikke samler inn",
                        body: "Helseopplysninger, betalingsinformasjon, lokasjonsdata eller data fra tredjepart uten din godkjenning."
                    )

                    policySection(
                        title: "Hvordan vi bruker dataene",
                        body: "Dataene brukes utelukkende for å drive SEDER-appen: lagre og vise sigarjournalen din, identifisere kontoen din og la deg logge inn. Vi selger ikke dataene dine til tredjepart, og de brukes ikke til reklame."
                    )

                    policySection(
                        title: "Hvem ser dataene dine",
                        body: "Dataene lagres i Supabase (USA). Vi deler ikke data med andre aktører. Innlogging via Apple eller Google håndteres av henholdsvis Apple og Google etter deres egne personvernregler."
                    )

                    policySection(
                        title: "Dine rettigheter",
                        body: "Du kan se, korrigere eller slette dataene dine når som helst. Slett kontoen direkte i appen under Innstillinger → Slett konto."
                    )

                    policySection(
                        title: "Aldersgrense",
                        body: "SEDER er kun beregnet for brukere over 18 år."
                    )

                    policySection(
                        title: "Kontakt",
                        body: "Spørsmål om personvern? Send e-post til theggedal@gmail.com"
                    )

                    Text("Sist oppdatert: juli 2026")
                        .font(.caption)
                        .foregroundColor(Color("TextSecondary"))
                        .padding(.top, 8)
                }
                .padding(24)
            }
            .background(Color("Background"))
            .navigationTitle("Personvernerklæring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lukk") { dismiss() }
                }
            }
        }
    }

    private func policySection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(Color("TextPrimary"))
            Text(body)
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
