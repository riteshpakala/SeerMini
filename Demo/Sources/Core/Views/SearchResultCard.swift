import SwiftUI

// Deterministic palette for owner ID colouring
private let ownerPalette: [Color] = [
    Color(red: 0.84, green: 0.36, blue: 0.29),
    Color(red: 0.56, green: 0.49, blue: 0.32),
    Color(red: 0.38, green: 0.55, blue: 0.38),
    Color(red: 0.65, green: 0.40, blue: 0.55),
    Color(red: 0.22, green: 0.44, blue: 0.65),
]

private func ownerColor(for id: String) -> Color {
    var h: Int = 0
    for ch in id.unicodeScalars { h = 31 &* h &+ Int(ch.value) }
    return ownerPalette[abs(h) % ownerPalette.count]
}

struct SearchResultCard: View {
    let result: SearchResult
    let index: Int

    @State private var isHovered = false
    @State private var appeared = false

    private var distanceColor: Color {
        let d = result.distance
        if d < 0.35 { return Color(red: 0.30, green: 0.69, blue: 0.31) }
        if d < 0.65 { return Color.seerGold }
        return Color.seerInk.opacity(0.35)
    }

    private var shortOwnerId: String {
        let id = result.documentId
        return id.isEmpty ? "unknown" : String(id.prefix(8))
    }

    private var accentColor: Color { ownerColor(for: result.documentId) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .center) {
                Text("Result \(String(format: "%02d", index + 1))")
                    .font(.seerSans(10, weight: .medium))
                    .foregroundStyle(Color.seerInk.opacity(0.30))
                    .tracking(0.8)
                    .textCase(.uppercase)

                Spacer()

                // Distance badge
                HStack(spacing: 5) {
                    Circle()
                        .fill(distanceColor)
                        .frame(width: 6, height: 6)
                    Text(String(format: "%.4f", result.distance))
                        .font(.seerMono(9.5))
                        .foregroundStyle(Color.seerInk.opacity(0.40))
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Color.seerFill)
                .clipShape(Capsule())
            }
            .padding(.bottom, 14)

            // Text excerpt
            Text(result.text)
                .font(.seerSerif(16, weight: .light, italic: true))
                .foregroundStyle(Color.seerInk.opacity(0.80))
                .lineSpacing(5)
                .lineLimit(7)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Divider
            Rectangle()
                .fill(Color.seerInk.opacity(0.07))
                .frame(height: 1)
                .padding(.vertical, 14)

            // Footer
            HStack(spacing: 10) {
                // Owner chip
                HStack(spacing: 5) {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 6, height: 6)
                    Text(shortOwnerId)
                        .font(.seerSans(10, weight: .medium))
                        .foregroundStyle(accentColor)
                        .tracking(0.5)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(accentColor.opacity(0.07))
                .overlay(
                    Capsule().strokeBorder(accentColor.opacity(0.22), lineWidth: 1)
                )
                .clipShape(Capsule())

                Spacer()

                if !result.partitionId.isEmpty {
                    Text("p:\(result.partitionId.prefix(6))…")
                        .font(.seerMono(9))
                        .foregroundStyle(Color.seerInk.opacity(0.20))
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isHovered ? Color.white.opacity(0.88) : Color.white.opacity(0.62))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            isHovered ? Color.seerGold.opacity(0.30) : Color.seerBorder,
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: isHovered ? Color.seerInk.opacity(0.10) : Color.seerInk.opacity(0.05),
                    radius: isHovered ? 20 : 8, x: 0, y: isHovered ? 7 : 2
                )
        )
        .scaleEffect(appeared ? 1.0 : 0.97)
        .opacity(appeared ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82).delay(Double(index) * 0.06)) {
                appeared = true
            }
        }
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.18), value: isHovered)
    }
}
