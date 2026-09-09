import SwiftUI

/// Review-safe cigar detail surface.
/// Shows factual catalog/reference data only. No ratings, favorites, wishlist,
/// recommendations, pairings or consumption-oriented actions.
struct ReviewCigarDetailView: View {
    let cigar: Cigar

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                referenceSection("Produkt") {
                    detailRow("Merke", cigar.brand)
                    detailRow("Serie", cigar.series)
                    detailRow("Vitola", cigar.vitola ?? cigar.commonFormat)
                    detailRow("Produsent", cigar.manufacturer)
                    detailRow("Opprinnelse", cigar.countryOrigin)
                }

                referenceSection("Format") {
                    detailRow("Mål", cigar.dimensionsLabel)
                    detailRow("Form", cigar.shape)
                    detailRow("Tverrsnitt", cigar.crossSection)
                    detailRow("Styrke", cigar.strengthLabel == "Ukjent" ? nil : cigar.strengthLabel)
                }

                referenceSection("Tobakk") {
                    detailRow("Dekkblad", cigar.wrapperLeaf)
                    detailRow("Dekkblad – land", cigar.wrapperCountry)
                    detailRow("Omblad", cigar.binder)
                    detailRow("Fyll", cigar.filler?.joined(separator: ", "))
                }

                referenceSection("Kildestatus") {
                    HStack(spacing: 8) {
                        Image(systemName: cigar.isVerified ? "checkmark.seal.fill" : "questionmark.circle")
                            .foregroundColor(cigar.isVerified ? Color("Accent") : Color("TextSecondary"))
                        Text(cigar.isVerified ? "Produktinformasjonen er kildekontrollert" : "Produktinformasjonen er ikke kildekontrollert")
                            .font(.subheadline)
                            .foregroundColor(Color("TextSecondary"))
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 32)
        }
        .background(Color("Background").ignoresSafeArea())
        .navigationTitle(cigar.brand)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(cigar.brand)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color("TextPrimary"))

            let subtitle = [cigar.series, cigar.vitola ?? cigar.commonFormat]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: " · ")

            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.title3)
                    .foregroundColor(Color("TextSecondary"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func referenceSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.6)
                .foregroundColor(Color("TextSecondary"))

            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, 14)
            .background(Color("Card"))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    @ViewBuilder
    private func detailRow(_ label: String, _ value: String?) -> some View {
        if let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            HStack(alignment: .top, spacing: 16) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(Color("TextSecondary"))
                    .frame(width: 112, alignment: .leading)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Color("TextPrimary"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 11)

            Divider().opacity(0.35)
        }
    }
}
