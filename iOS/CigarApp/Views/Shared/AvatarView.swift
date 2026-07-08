import SwiftUI
import Kingfisher

// MARK: - AvatarView
// Gjenbrukbar avatar-komponent med cachet bilde (Kingfisher) og fallback til
// initialer/ikon. Bruk: AvatarView(url: post.authorAvatarUrl, name: post.authorName, size: 36)

struct AvatarView: View {

    let url: String?
    let name: String
    var size: CGFloat = 36

    private var initials: String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private var fontSize: CGFloat { size * 0.38 }

    var body: some View {
        Group {
            if let urlString = url, let imageUrl = URL(string: urlString) {
                KFImage(imageUrl)
                    .resizable()
                    .placeholder { fallbackView }
                    .fade(duration: 0.15)
                    .scaledToFill()
            } else {
                fallbackView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var fallbackView: some View {
        ZStack {
            Circle()
                .fill(Color("Surface"))
            if name.isEmpty {
                Image(systemName: "person.fill")
                    .font(.system(size: fontSize * 1.2))
                    .foregroundColor(Color("TextSecondary"))
            } else {
                Text(initials)
                    .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                    .foregroundColor(Color("TextSecondary"))
            }
        }
    }
}
