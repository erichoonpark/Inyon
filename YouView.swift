import SwiftUI

struct YouView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("You")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)

                Text("Your profile and preferences.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppTheme.earth)
    }
}

#Preview {
    YouView()
}
