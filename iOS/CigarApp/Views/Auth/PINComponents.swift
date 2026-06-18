import SwiftUI

// MARK: - PINDotsView
// Viser 4 prikker som fylles etter hvert som brukeren taster siffer

struct PINDotsView: View {
    let filled: Int
    let total: Int = 4

    var body: some View {
        HStack(spacing: 16) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index < filled ? Color("Accent") : Color("Surface"))
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle().strokeBorder(Color("TextSecondary").opacity(0.3))
                    )
            }
        }
    }
}

// MARK: - PINKeypad
// Enkelt numerisk tastatur (0–9 + slett) for PIN-inntasting

struct PINKeypad: View {
    @Binding var pin: String
    var onComplete: () -> Void

    private let rows: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["", "0", "⌫"]
    ]

    var body: some View {
        VStack(spacing: 20) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 28) {
                    ForEach(row, id: \.self) { key in
                        keyButton(key)
                    }
                }
            }
        }
        .padding(.bottom, 24)
    }

    @ViewBuilder
    private func keyButton(_ key: String) -> some View {
        if key.isEmpty {
            Color.clear.frame(width: 70, height: 70)
        } else {
            Button(action: { tap(key) }) {
                Group {
                    if key == "⌫" {
                        Image(systemName: "delete.left")
                    } else {
                        Text(key)
                    }
                }
                .font(.title2.weight(.medium))
                .foregroundColor(Color("TextPrimary"))
                .frame(width: 70, height: 70)
                .background(Color("Surface"))
                .clipShape(Circle())
            }
        }
    }

    private func tap(_ key: String) {
        if key == "⌫" {
            if !pin.isEmpty { pin.removeLast() }
            return
        }
        guard pin.count < 4 else { return }
        pin.append(key)
        if pin.count == 4 {
            onComplete()
        }
    }
}
