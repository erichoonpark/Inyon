import SwiftUI

struct PostSignupView: View {
    var onContinue: () -> Void
    @State private var isVisible = false

    var body: some View {
        ZStack {
            AppTheme.earth
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    Image("InyonLogo")
                        .resizable()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text("Your first reflection is ready.")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("A new one appears each morning. It takes a moment to read—drawn from your birth timing, grounded in the day.")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 40)
                .opacity(isVisible ? 1 : 0)

                Spacer()

                Button {
                    onContinue()
                } label: {
                    Text("See Today's Reflection")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(AppTheme.earth)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(AppTheme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .opacity(isVisible ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.3).delay(0.1)) {
                isVisible = true
            }
        }
    }
}

#Preview {
    PostSignupView(onContinue: {})
}
