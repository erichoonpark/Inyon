import SwiftUI

// MARK: - Onboarding Data Model

struct OnboardingData {
    var birthDate: Date?
    var birthTime: Date?
    var personalAnchors: Set<PersonalAnchor> = []
}

enum PersonalAnchor: String, CaseIterable, Identifiable {
    case direction = "Direction"
    case energy = "Energy"
    case love = "Love"
    case work = "Work"
    case rest = "Rest"

    var id: String { rawValue }
}

enum OnboardingStep: Int, CaseIterable {
    case arrival
    case birthContext
    case personalAnchor
    case accountCreation
}

// MARK: - Onboarding Flow Coordinator

struct OnboardingFlow: View {
    @State private var currentStep: OnboardingStep = .arrival
    @State private var data = OnboardingData()
    @State private var isVisible = false

    var onComplete: () -> Void

    var body: some View {
        ZStack {
            AppTheme.earth
                .ignoresSafeArea()

            Group {
                switch currentStep {
                case .arrival:
                    ArrivalView(onContinue: advanceToNext)
                case .birthContext:
                    BirthContextView(data: $data, onContinue: advanceToNext)
                case .personalAnchor:
                    PersonalAnchorView(data: $data, onContinue: advanceToNext, onSkip: advanceToNext)
                case .accountCreation:
                    AccountCreationView(data: data, onComplete: onComplete)
                }
            }
            .opacity(isVisible ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.25)) {
                isVisible = true
            }
        }
    }

    private func advanceToNext() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isVisible = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if let nextIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
               nextIndex + 1 < OnboardingStep.allCases.count {
                currentStep = OnboardingStep.allCases[nextIndex + 1]
            }

            withAnimation(.easeInOut(duration: 0.25)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Screen 1: Arrival / Orientation

struct ArrivalView: View {
    var onContinue: () -> Void
    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Text("Inyon offers insight about timing & balance.")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)

                Text("You’ll get a short daily view of timing and context.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            .opacity(isVisible ? 1 : 0)

            Spacer()

            Button {
                onContinue()
            } label: {
                Text("Begin")
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
        .onAppear {
            withAnimation(.easeIn(duration: 0.3).delay(0.1)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Screen 2: Birth Context

struct BirthContextView: View {
    @Binding var data: OnboardingData
    var onContinue: () -> Void

    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @State private var knowsBirthTime = true
    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 80)

            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Saju looks at the moment you entered the world.")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("This helps Inyon determine timing patterns")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 24) {
                    // Birth Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("BIRTH DATE")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .tracking(1.2)
                            .foregroundColor(AppTheme.textSecondary)

                        DatePicker(
                            "",
                            selection: $selectedDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(AppTheme.textPrimary)
                        .colorScheme(.dark)
                    }

                    // Birth Time
                    VStack(alignment: .leading, spacing: 12) {
                        Text("BIRTH TIME")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .tracking(1.2)
                            .foregroundColor(AppTheme.textSecondary)

                        if knowsBirthTime {
                            HStack(spacing: 16) {
                                DatePicker(
                                    "",
                                    selection: $selectedTime,
                                    displayedComponents: .hourAndMinute
                                )
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .tint(AppTheme.textPrimary)
                                .colorScheme(.dark)

                                Button {
                                    knowsBirthTime = false
                                } label: {
                                    Text("Not sure")
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(AppTheme.textSecondary)
                                        .underline()
                                }
                            }
                        } else {
                            HStack(spacing: 16) {
                                Text("Unknown")
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundColor(AppTheme.textSecondary)

                                Button {
                                    knowsBirthTime = true
                                } label: {
                                    Text("Add time")
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(AppTheme.textSecondary)
                                        .underline()
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .opacity(isVisible ? 1 : 0)

            Spacer()

            Button {
                data.birthDate = selectedDate
                data.birthTime = knowsBirthTime ? selectedTime : nil
                onContinue()
            } label: {
                Text("Continue")
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
        .onAppear {
            withAnimation(.easeIn(duration: 0.3).delay(0.1)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Screen 3: Personal Anchor

struct PersonalAnchorView: View {
    @Binding var data: OnboardingData
    var onContinue: () -> Void
    var onSkip: () -> Void

    @State private var selectedAnchors: Set<PersonalAnchor> = []
    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 80)

            VStack(alignment: .leading, spacing: 40) {
                Text("What feels most present in your life right now?")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 0) {
                    ForEach(PersonalAnchor.allCases) { anchor in
                        Button {
                            if selectedAnchors.contains(anchor) {
                                selectedAnchors.remove(anchor)
                            } else {
                                selectedAnchors.insert(anchor)
                            }
                        } label: {
                            HStack {
                                Text(anchor.rawValue)
                                    .font(.system(size: 19, weight: .regular))
                                    .foregroundColor(
                                        selectedAnchors.contains(anchor)
                                            ? AppTheme.textPrimary
                                            : AppTheme.textSecondary
                                    )

                                Spacer()

                                if selectedAnchors.contains(anchor) {
                                    Rectangle()
                                        .fill(AppTheme.textPrimary)
                                        .frame(width: 20, height: 2)
                                }
                            }
                            .padding(.vertical, 18)
                            .contentShape(Rectangle())
                        }

                        if anchor != PersonalAnchor.allCases.last {
                            Rectangle()
                                .fill(AppTheme.divider)
                                .frame(height: 1)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .opacity(isVisible ? 1 : 0)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    data.personalAnchors = selectedAnchors
                    onContinue()
                } label: {
                    Text("Continue")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(AppTheme.earth)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(AppTheme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    onSkip()
                } label: {
                    Text("Skip")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            .opacity(isVisible ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.3).delay(0.1)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Screen 4: Account Creation

struct AccountCreationView: View {
    var data: OnboardingData
    var onComplete: () -> Void

    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Text("Keep your timing context over time.")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            .opacity(isVisible ? 1 : 0)

            Spacer()

            VStack(spacing: 12) {
                // Apple Sign In
                Button {
                    // TODO: Implement Apple Sign In
                    onComplete()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 18))
                        Text("Continue with Apple")
                            .font(.system(size: 17, weight: .medium))
                    }
                    .foregroundColor(AppTheme.earth)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(AppTheme.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Email Sign In
                Button {
                    // TODO: Implement Email Sign In
                    onComplete()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "envelope")
                            .font(.system(size: 16))
                        Text("Continue with Email")
                            .font(.system(size: 17, weight: .medium))
                    }
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(AppTheme.textPrimary.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            .opacity(isVisible ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.3).delay(0.1)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingFlow(onComplete: {})
}
