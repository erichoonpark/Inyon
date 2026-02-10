import SwiftUI

struct HomeView: View {
    // Placeholder: will be provided by server
    private let highlightedElement = "Wood"

    private var todayFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Date
            Text(todayFormatted)
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer().frame(height: 24)

            // Five Elements strip
            FiveElementsStrip(highlighted: highlightedElement)

            Spacer().frame(height: 8)

            // Elements caption
            Text("Today's elemental condition")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Spacer().frame(height: 48)

            // Section label
            Text("Your day at a glance")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer().frame(height: 16)

            // Primary reflection
            Text("This period may carry a slower rhythm than usual. There's nothing to fix about that.")
                .font(.title3)
                .fontWeight(.regular)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer().frame(height: 16)

            // Secondary paragraph (optional)
            Text("Stillness has its own momentum.")
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Five Elements Strip

struct FiveElementsStrip: View {
    let highlighted: String

    private let elements = ["Wood", "Fire", "Earth", "Metal", "Water"]

    var body: some View {
        HStack(spacing: 16) {
            ForEach(elements, id: \.self) { element in
                Text(element)
                    .font(.footnote)
                    .fontWeight(element == highlighted ? .semibold : .regular)
                    .foregroundStyle(element == highlighted ? .primary : .tertiary)
            }
        }
    }
}

#Preview {
    HomeView()
}
