import MapKit
import SwiftUI
import UserNotifications

private enum YouViewField: Hashable {
    case firstName, lastName, birthLocation
}

struct YouView: View {
    let onboardingService: OnboardingServiceProtocol
    @EnvironmentObject private var authService: AuthService
    @StateObject private var viewModel: YouViewModel
    @StateObject private var cityCompleter = CitySearchCompleter()
    @FocusState private var focusedField: YouViewField?
    @State private var cityQuery = ""
    @State private var verificationBannerDismissed = false
    @State private var verificationEmailSent = false

    init(onboardingService: OnboardingServiceProtocol) {
        self.onboardingService = onboardingService
        _viewModel = StateObject(wrappedValue: YouViewModel(onboardingService: onboardingService))
    }

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

                // Header
                Text("You")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)

                // Email verification banner
                if !authService.isEmailVerified && !verificationBannerDismissed {
                    emailVerificationBanner
                }

                if viewModel.isLoading {
                    ProgressView()
                        .tint(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                } else {
                    // Cultural Context (read-only)
                    derivedContextSection

                    // Notification Preferences
                    notificationSection

                    // Personal Info (editable)
                    personalInfoSection

                    // Birth Context (editable)
                    editableSection

                    // Save Button / Confirmation
                    Group {
                        if viewModel.hasUnsavedChanges {
                            saveButton
                        } else if viewModel.showSaveConfirmation {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Saved")
                                    .font(.system(size: 15, weight: .regular))
                            }
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .transition(.opacity)
                        }
                    }
                    .animation(.easeInOut(duration: 0.25), value: viewModel.hasUnsavedChanges)
                    .animation(.easeInOut(duration: 0.25), value: viewModel.showSaveConfirmation)

                    // Log Out
                    logoutSection
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppTheme.earth)
        .onAppear {
            viewModel.authService = authService
            Task { await viewModel.loadData() }
        }
        .alert("Log out of Inyon?", isPresented: $viewModel.showLogoutConfirmation) {
            Button("Log Out", role: .destructive) {
                viewModel.performLogout()
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Notifications Disabled", isPresented: $viewModel.showNotificationDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enable notifications in Settings to receive daily reflections.")
        }
        .alert("Unable to log out", isPresented: .init(
            get: { viewModel.logoutError != nil },
            set: { if !$0 { viewModel.logoutError = nil } }
        )) {
            Button("Try Again") {
                viewModel.performLogout()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(viewModel.logoutError ?? "")
        }
    }

    // MARK: - Personal Info Section

    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("PERSONAL INFO")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .tracking(1.2)
                .foregroundColor(AppTheme.textSecondary)

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("First name")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    TextField("—", text: $viewModel.firstName)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(AppTheme.textPrimary)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 180)
                        .focused($focusedField, equals: .firstName)
                        .onChange(of: viewModel.firstName) { _, _ in
                            viewModel.fieldChanged()
                        }
                }
                .contentShape(Rectangle())
                .onTapGesture { focusedField = .firstName }

                Rectangle()
                    .fill(AppTheme.divider)
                    .frame(height: 1)

                HStack {
                    Text("Last name")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    TextField("—", text: $viewModel.lastName)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(AppTheme.textPrimary)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 180)
                        .focused($focusedField, equals: .lastName)
                        .onChange(of: viewModel.lastName) { _, _ in
                            viewModel.fieldChanged()
                        }
                }
                .contentShape(Rectangle())
                .onTapGesture { focusedField = .lastName }

                Rectangle()
                    .fill(AppTheme.divider)
                    .frame(height: 1)

                // Birth location with MapKit autocomplete
                if viewModel.birthLocation.isEmpty {
                    HStack {
                        Text("Birth location")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(AppTheme.textSecondary)
                        Spacer()
                        TextField("City", text: $cityQuery)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(AppTheme.textPrimary)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 180)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .birthLocation)
                            .onChange(of: cityQuery) { _, newValue in
                                cityCompleter.search(newValue)
                            }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { focusedField = .birthLocation }
                } else {
                    HStack {
                        Text("Birth location")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(AppTheme.textSecondary)
                        Spacer()
                        HStack(spacing: 12) {
                            Text(viewModel.birthLocation)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(AppTheme.textPrimary)
                                .lineLimit(1)
                            Button {
                                viewModel.birthLocation = ""
                                cityQuery = ""
                                viewModel.fieldChanged()
                                focusedField = .birthLocation
                            } label: {
                                Text("Change")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(AppTheme.textSecondary)
                                    .underline()
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.birthLocation = ""
                        cityQuery = ""
                        viewModel.fieldChanged()
                        focusedField = .birthLocation
                    }
                }

                // Autocomplete suggestions (max 3)
                if viewModel.birthLocation.isEmpty && !cityCompleter.results.isEmpty {
                    ForEach(cityCompleter.results.prefix(3), id: \.self) { result in
                        let city = [result.title, result.subtitle]
                            .filter { !$0.isEmpty }
                            .joined(separator: ", ")
                        Button {
                            viewModel.birthLocation = city
                            cityQuery = ""
                            cityCompleter.results = []
                            viewModel.fieldChanged()
                        } label: {
                            Text(city)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(AppTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 6)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Editable Section

    private var editableSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("BIRTH CONTEXT")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .tracking(1.2)
                .foregroundColor(AppTheme.textSecondary)

            // Birth Date
            VStack(alignment: .leading, spacing: 8) {
                Text("Birth Date")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)

                ZStack(alignment: .leading) {
                    if !viewModel.hasSelectedDate {
                        Text("Not set")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    DatePicker(
                        "",
                        selection: $viewModel.selectedDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(AppTheme.textPrimary)
                    .colorScheme(.dark)
                    .opacity(viewModel.hasSelectedDate ? 1 : 0.011)
                    .onChange(of: viewModel.selectedDate) { _, newDate in
                        viewModel.birthDateChanged(newDate)
                    }
                }
            }

            Rectangle()
                .fill(AppTheme.divider)
                .frame(height: 1)

            // Birth Time
            VStack(alignment: .leading, spacing: 8) {
                Text("Birth Time")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)

                HStack(spacing: 16) {
                    ZStack(alignment: .leading) {
                        if !viewModel.hasSelectedTime {
                            Text("Not set")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        DatePicker(
                            "",
                            selection: $viewModel.selectedTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(AppTheme.textPrimary)
                        .colorScheme(.dark)
                        .opacity(viewModel.hasSelectedTime ? 1 : 0.011)
                        .onChange(of: viewModel.selectedTime) { _, newTime in
                            viewModel.birthTimeChanged(newTime)
                        }
                    }

                    if viewModel.hasSelectedTime {
                        Button {
                            viewModel.clearBirthTime()
                        } label: {
                            Text("Clear")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(AppTheme.textSecondary)
                                .underline()
                        }
                    }
                }
            }

            Rectangle()
                .fill(AppTheme.divider)
                .frame(height: 1)

            // Personal Anchors
            VStack(alignment: .leading, spacing: 12) {
                Text("Personal Anchors")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)

                FlowLayout(spacing: 10) {
                    ForEach(PersonalAnchor.allCases) { anchor in
                        Button {
                            viewModel.toggleAnchor(anchor)
                        } label: {
                            Text(anchor.rawValue)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(
                                    viewModel.personalAnchors.contains(anchor)
                                        ? AppTheme.textPrimary
                                        : AppTheme.textSecondary
                                )
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    viewModel.personalAnchors.contains(anchor)
                                        ? AppTheme.surface
                                        : Color.clear
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            viewModel.personalAnchors.contains(anchor)
                                                ? AppTheme.textPrimary.opacity(0.3)
                                                : AppTheme.divider,
                                            lineWidth: 1
                                        )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Notification Section

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("NOTIFICATIONS")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .tracking(1.2)
                .foregroundColor(AppTheme.textSecondary)

            VStack(alignment: .leading, spacing: 16) {
                Toggle(isOn: $viewModel.notificationsEnabled) {
                    Text("Daily reflection")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(AppTheme.textPrimary)
                }
                .tint(AppTheme.earthRed)
                .onChange(of: viewModel.notificationsEnabled) { _, newValue in
                    viewModel.notificationEnabledChanged(newValue)
                }

                if viewModel.notificationsEnabled {
                    Rectangle()
                        .fill(AppTheme.divider)
                        .frame(height: 1)

                    HStack {
                        Text("Preferred time")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(AppTheme.textSecondary)

                        Spacer()

                        DatePicker(
                            "",
                            selection: $viewModel.preferredNotificationTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(AppTheme.textPrimary)
                        .colorScheme(.dark)
                        .onChange(of: viewModel.preferredNotificationTime) { _, newTime in
                            viewModel.notificationTimeChanged(newTime)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Derived Context Section

    private var derivedContextSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("CULTURAL CONTEXT")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .tracking(1.2)
                    .foregroundColor(AppTheme.textSecondary)

                Text("Informational, not predictive")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary.opacity(0.7))
            }

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Lunar birthday")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)

                    Spacer()

                    Text(DerivedData.lunarBirthday(from: viewModel.birthDate))
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(AppTheme.textPrimary)
                }

                Rectangle()
                    .fill(AppTheme.divider)
                    .frame(height: 1)

                HStack {
                    Text("Zodiac year")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)

                    Spacer()

                    Text(DerivedData.zodiacAnimal(from: viewModel.birthDate))
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(AppTheme.textPrimary)
                }
            }
        }
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Save Button

    private var saveButton: some View {
        VStack(spacing: 8) {
            if let saveError = viewModel.saveError {
                Text(saveError)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(red: 0.9, green: 0.4, blue: 0.4))
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await viewModel.saveData() }
            } label: {
                Group {
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(AppTheme.earth)
                    } else {
                        Text(viewModel.saveError != nil ? "Retry Save" : "Save Changes")
                            .font(.system(size: 17, weight: .medium))
                    }
                }
                .foregroundColor(AppTheme.earth)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(AppTheme.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(viewModel.isSaving)
        }
        .padding(.top, 8)
    }

    // MARK: - Email Verification Banner

    private var emailVerificationBanner: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Please verify your email.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)

                if verificationEmailSent {
                    Text("Email sent")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                } else {
                    Button {
                        Task {
                            try? await authService.sendEmailVerification()
                            verificationEmailSent = true
                        }
                    } label: {
                        Text("Resend verification email")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(AppTheme.textSecondary)
                            .underline()
                    }
                }
            }

            Spacer()

            Button {
                verificationBannerDismissed = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
        }
        .padding(12)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppTheme.divider, lineWidth: 1)
        )
    }

    // MARK: - Log Out Section

    private var logoutSection: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(AppTheme.divider)
                .frame(height: 1)
                .padding(.bottom, 24)

            Button {
                viewModel.showLogoutConfirmation = true
            } label: {
                Text("Log Out")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(Color(red: 0.9, green: 0.4, blue: 0.4))
            }
            .accessibilityIdentifier("you.logoutButton")
        }
        .padding(.top, 8)
    }
}

// MARK: - Flow Layout (for anchor chips)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}

#Preview {
    YouView(onboardingService: OnboardingService())
        .environmentObject(AuthService())
}
