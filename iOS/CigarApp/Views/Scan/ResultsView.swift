import SwiftUI

// MARK: - ResultsView
// Viser 3–5 mulige treff etter scanning

struct ResultsView: View {

    let results: [ScanResult]
    let ocrText: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            // OCR-tekst-header
            if !ocrText.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Lest fra bandet:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(ocrText)
                            .font(.subheadline.italic())
                    }
                    .padding(.vertical, 4)
                }
            }

            // Resultater
            Section(header: Text("\(results.count) mulige treff")) {
                ForEach(results) { result in
                    NavigationLink(destination: CigarDetailView(cigar: result.cigar)) {
                        ResultRow(result: result)
                    }
                }
            }

            // Ingen treff-hjelp
            Section {
                Button(action: { dismiss() }) {
                    Label("Scan på nytt", systemImage: "camera.fill")
                }
            }
        }
        .navigationTitle("Treff")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Result Row
struct ResultRow: View {

    let result: ScanResult

    var body: some View {
        HStack(spacing: 12) {
            // Sigar-bilde placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color("Surface"))
                    .frame(width: 60, height: 60)
                Image(systemName: "leaf.fill")
                    .foregroundColor(Color("Accent"))
                    .font(.title2)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(result.cigar.brand)
                    .font(.headline)
                if let series = result.cigar.series {
                    Text(series)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                if let vitola = result.cigar.vitola {
                    Text(vitola)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Konfidens-badge
            ConfidenceBadge(result: result)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Confidence Badge
struct ConfidenceBadge: View {

    let result: ScanResult

    var color: Color {
        switch result.confidence {
        case 0.8...: return .green
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }

    var body: some View {
        Text(result.confidenceLabel)
            .font(.caption.bold())
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}
