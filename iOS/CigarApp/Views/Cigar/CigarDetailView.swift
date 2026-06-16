import SwiftUI

// MARK: - CigarDetailView
// Fullt informasjonskort for en sigar + lagre til humidor

struct CigarDetailView: View {

    let cigar: Cigar
    @EnvironmentObject var authService: AuthService
    @State private var isSaved = false
    @State private var showSaveConfirm = false
    @State private var isSaving = false
    private let humidorService = HumidorService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // MARK: Header
                CigarHeaderSection(cigar: cigar)

                Divider().padding(.horizontal)

                // MARK: Konstruksjon
                DetailSection(title: "Konstruksjon") {
                    if let wrapper = cigar.wrapperLeaf {
                        DetailRow(label: "Wrapper", value: "\(wrapper)\(cigar.wrapperCountry.map { " (\($0))" } ?? "")")
                    }
                    if let binder = cigar.binder {
                        DetailRow(label: "Binder", value: binder)
                    }
                    if let filler = cigar.filler, !filler.isEmpty {
                        DetailRow(label: "Filler", value: filler.joined(separator: ", "))
                    }
                    if let origin = cigar.countryOrigin {
                        DetailRow(label: "Opprinnelse", value: origin)
                    }
                    if let gauge = cigar.ringGauge, let length = cigar.lengthInches {
                        DetailRow(label: "Størrelse", value: "\(length)\" × \(gauge) RG")
                    }
                }

                Divider().padding(.horizontal)

                // MARK: Smaksprofil
                if let notes = cigar.flavorNotes, !notes.isEmpty {
                    DetailSection(title: "Smaksprofil") {
                        FlavorTagsView(notes: notes)
                    }
                    Divider().padding(.horizontal)
                }

                // MARK: Om sigaren
                if let desc = cigar.description {
                    DetailSection(title: "Om sigaren") {
                        Text(desc)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    Divider().padding(.horizontal)
                }

                // MARK: Pris
                if let price = cigar.priceRange {
                    DetailSection(title: "Prisnivå") {
                        Text(price)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                // MARK: Lagre-knapp
                Button(action: saveToHumidor) {
                    HStack {
                        Image(systemName: isSaved ? "checkmark.circle.fill" : "plus.circle.fill")
                        Text(isSaved ? "Lagret i humidor" : "Legg til humidor")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isSaved ? Color.green : Color("Accent"))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(24)
                .disabled(isSaved || isSaving)
            }
        }
        .navigationTitle(cigar.brand)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func saveToHumidor() {
        guard let userId = authService.userId else { return }
        isSaving = true

        Task {
            do {
                try await humidorService.addToHumidor(cigarId: cigar.id, userId: userId)
                isSaved = true
            } catch {
                print("Feil ved lagring: \(error)")
            }
            isSaving = false
        }
    }
}

// MARK: - Header Section
struct CigarHeaderSection: View {

    let cigar: Cigar

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Bilde-placeholder
            ZStack {
                Rectangle()
                    .fill(Color("Surface"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                VStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color("Accent").opacity(0.4))
                    Text("Bilde mangler")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(cigar.brand)
                    .font(.title2.bold())
                if let series = cigar.series {
                    Text(series)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 12) {
                    // Styrke-badge
                    if let strength = cigar.strength {
                        Label(cigar.strengthLabel, systemImage: "flame.fill")
                            .font(.caption.bold())
                            .foregroundColor(strengthColor(strength))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(strengthColor(strength).opacity(0.12))
                            .clipShape(Capsule())
                    }

                    // Vitola
                    if let vitola = cigar.vitola {
                        Text(vitola)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color("Surface"))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }

    func strengthColor(_ strength: Int) -> Color {
        switch strength {
        case 1, 2: return .green
        case 3: return .orange
        default: return .red
        }
    }
}

// MARK: - Detail Section
struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.top, 16)
            content
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(.subheadline)
        }
    }
}

// MARK: - Flavor Tags
struct FlavorTagsView: View {
    let notes: [String]

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(notes, id: \.self) { note in
                Text(note)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color("Accent").opacity(0.1))
                    .foregroundColor(Color("Accent"))
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Flow Layout (for tags)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: frame.minX + bounds.minX, y: frame.minY + bounds.minY), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
                x += size.width + spacing
                rowHeight = max(rowHeight, size.height)
            }
            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}
