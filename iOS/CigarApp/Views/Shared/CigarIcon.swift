import SwiftUI

// MARK: - CigarIcon
// Enkelt, gjenkjennelig sigar-ikon brukt som thumbnail-placeholder
// der vi mangler et faktisk produktbilde. Erstatter de tidligere
// "leaf.fill" SF Symbol-plassholderne (SF Symbols har ikke noe
// sigar-symbol, så dette er et eget lettvekts vektor-ikon).

struct CigarIcon: View {

    var color: Color = .primary

    var body: some View {
        GeometryReader { geo in
            // Skalert ned (0.78×) for å kompensere for at en rotert form
            // får en større bounding box enn sin urotert bredde/høyde —
            // uten dette stikker sigaren ut av den kvadratiske rammen og
            // ser usentrert ut. width(|cosθ|+|sinθ|) ved -32° ≈ 1.376×w,
            // så vi krymper innholdet før rotasjon for å holde det innenfor.
            let w = geo.size.width * 0.78
            let h = geo.size.height * 0.78
            let bodyHeight = h * 0.40

            ZStack {
                // Sigarkroppen
                Capsule()
                    .fill(color)
                    .frame(width: w, height: bodyHeight)

                // Bandet
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color("Background"))
                    .frame(width: w * 0.16, height: bodyHeight)
                    .offset(x: w * 0.18)

                // Glo/ask i tuppen
                Circle()
                    .fill(color.opacity(0.55))
                    .frame(width: bodyHeight * 0.7, height: bodyHeight * 0.7)
                    .offset(x: -w * 0.46)
            }
            .rotationEffect(.degrees(-32))
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    HStack(spacing: 24) {
        CigarIcon(color: .brown)
            .frame(width: 60, height: 60)
        CigarIcon(color: .gray)
            .frame(width: 32, height: 32)
    }
    .padding()
}
