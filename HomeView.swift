import SwiftUI

struct HomeView: View {
    private var todayFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            Text(todayFormatted)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
                .frame(height: 24)

            Text("A placeholder for today's reflection.")
                .font(.title2)
                .fontWeight(.regular)
                .lineSpacing(6)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    HomeView()
}
