import SwiftUI

// MARK: - StarRatingRow
// Én rad med label + 5 trykkbare stjerner (1–5).
// Trykk på samme stjerne igjen for å nullstille vurderingen.

struct StarRatingRow: View {
    let label: String
    @Binding var rating: Int?

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .frame(width: 100, alignment: .leading)

            Spacer()

            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= (rating ?? 0) ? "star.fill" : "star")
                        .font(.system(size: 26))
                        .foregroundColor(star <= (rating ?? 0) ? .orange : Color("TextSecondary").opacity(0.35))
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            rating = (rating == star) ? nil : star
                        }
                }
            }
        }
    }
}

#Preview {
    StarRatingPreviewContainer()
}

private struct StarRatingPreviewContainer: View {
    @State private var rating: Int? = 3

    var body: some View {
        StarRatingRow(label: "Konstruksjon", rating: $rating)
            .padding()
    }
}
