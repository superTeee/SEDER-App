import SwiftUI

// MARK: - Delte bilde-knapper
// Én kilde til sannhet for "Endre bilde"- og "Last opp bilde"-knappene, slik at
// de ser helt like ut overalt (fasit: toppbildet på profilen).

// "Endre"-pille — plasseres typisk øverst til høyre over et bilde.
struct EditPhotoPill: View {
    var isBusy: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            if isBusy {
                ProgressView().tint(.white).scaleEffect(0.7)
            } else {
                Image(systemName: "camera.fill").font(.system(size: 11))
            }
            Text("Endre").font(.caption)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Color.black.opacity(0.4))
        .clipShape(Capsule())
        .padding(10)
    }
}

// Midtstilt "Last opp bilde"-plassholder når det ikke finnes et bilde ennå.
struct UploadPhotoPlaceholder: View {
    var isBusy: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            if isBusy {
                ProgressView().tint(Color("Accent"))
            } else {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(Color("Accent"))
                Text("Last opp bilde")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("Accent"))
            }
        }
    }
}
