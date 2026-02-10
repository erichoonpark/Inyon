import SwiftUI

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Home")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)

                Text("Calm, reflective insight about timing and balance.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(20)
        }
        .background(AppTheme.earth)
    }
}

#Preview {
    HomeView()
}
