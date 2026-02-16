import SwiftUI

struct HomeView: View {
    private let today = Date()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Logo header
                HStack(spacing: 8) {
                    Image("InyonLogo")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Text("INYON")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .tracking(1.5)
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()
                }

                // Date header
                VStack(alignment: .leading, spacing: 4) {
                    Text(today.formatted(.dateTime.weekday(.wide)))
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .tracking(1.2)
                        .foregroundColor(AppTheme.textSecondary)
                        .textCase(.uppercase)

                    Text(today.formatted(.dateTime.month(.wide).day()))
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                }

                // Day Master section
                VStack(alignment: .leading, spacing: 12) {
                    Text("DAY ELEMENT")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .tracking(1.5)
                        .foregroundColor(AppTheme.textSecondary)

                    HStack(spacing: 12) {
                        // Element icon
                        Image(systemName: "leaf")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.textPrimary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Wood")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)

                            Text("Growth, flexibility, vision")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }

                // Five Elements strip
                FiveElementsStrip()

                // Daily reflection
                VStack(alignment: .leading, spacing: 12) {
                    Text("TODAY")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .tracking(1.5)
                        .foregroundColor(AppTheme.textSecondary)

                    Text("This period may feel quieter than expected. Conditions tend to favor patience over action.")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(AppTheme.textPrimary)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppTheme.earth)
    }
}

// MARK: - Five Elements Strip

struct FiveElementsStrip: View {
    private let elements = [
        ("Wood", "leaf"),
        ("Fire", "flame"),
        ("Earth", "square.on.square"),
        ("Metal", "circle.hexagongrid"),
        ("Water", "drop")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ELEMENTS")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .tracking(1.5)
                .foregroundColor(AppTheme.textSecondary)

            HStack(spacing: 0) {
                ForEach(elements, id: \.0) { element in
                    VStack(spacing: 6) {
                        Image(systemName: element.1)
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.textPrimary)

                        Text(element.0)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 16)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.divider, lineWidth: 1)
            )
        }
    }
}

#Preview {
    HomeView()
}
