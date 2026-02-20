import SwiftUI
import FirebaseFirestore
import UserNotifications

struct YouView: View {
    let onboardingService: OnboardingServiceProtocol
    @EnvironmentObject private var authService: AuthService
    @StateObject private var notificationService = NotificationService()

    @State private var birthDate: Date?
    @State private var birthTime: Date?
    @State private var personalAnchors: Set<PersonalAnchor> = []
    @State private var notificationsEnabled = false
    @State private var preferredNotificationTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    @State private var showNotificationDeniedAlert = false

    @State private var hasSelectedDate = false
    @State private var hasSelectedTime = false
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var hasUnsavedChanges = false
    @State private var showLogoutConfirmation = false
    @State private var logoutError: String?

    // Temporary state for date pickers
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()

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

                if isLoading {
                    ProgressView()
                        .tint(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                } else {
                    // Cultural Context (read-only)
                    derivedContextSection

                    // Notification Preferences
                    notificationSection

                    // Birth Context (editable)
                    editableSection

                    // Save Button
                    if hasUnsavedChanges {
                        saveButton
                    }

                    // Log Out
                    logoutSection
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppTheme.earth)
        .onAppear {
            loadData()
        }
        .alert("Log out of Inyon?", isPresented: $showLogoutConfirmation) {
            Button("Log Out", role: .destructive) {
                performLogout()
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Notifications Disabled", isPresented: $showNotificationDeniedAlert) {
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
            get: { logoutError != nil },
            set: { if !$0 { logoutError = nil } }
        )) {
            Button("Try Again") {
                performLogout()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(logoutError ?? "")
        }
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
                    if !hasSelectedDate {
                        Text("Not set")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(AppTheme.textSecondary)
                    }
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
                    .opacity(hasSelectedDate ? 1 : 0.011)
                    .onChange(of: selectedDate) { _, _ in
                        hasSelectedDate = true
                        birthDate = selectedDate
                        hasUnsavedChanges = true
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
                        if !hasSelectedTime {
                            Text("Not set")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        DatePicker(
                            "",
                            selection: $selectedTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(AppTheme.textPrimary)
                        .colorScheme(.dark)
                        .opacity(hasSelectedTime ? 1 : 0.011)
                        .onChange(of: selectedTime) { _, _ in
                            hasSelectedTime = true
                            birthTime = selectedTime
                            hasUnsavedChanges = true
                        }
                    }

                    if hasSelectedTime {
                        Button {
                            hasSelectedTime = false
                            birthTime = nil
                            hasUnsavedChanges = true
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
                            if personalAnchors.contains(anchor) {
                                personalAnchors.remove(anchor)
                            } else {
                                personalAnchors.insert(anchor)
                            }
                            hasUnsavedChanges = true
                        } label: {
                            Text(anchor.rawValue)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(
                                    personalAnchors.contains(anchor)
                                        ? AppTheme.textPrimary
                                        : AppTheme.textSecondary
                                )
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    personalAnchors.contains(anchor)
                                        ? AppTheme.surface
                                        : Color.clear
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            personalAnchors.contains(anchor)
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
                Toggle(isOn: $notificationsEnabled) {
                    Text("Daily reflection")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(AppTheme.textPrimary)
                }
                .tint(AppTheme.earthRed)
                .onChange(of: notificationsEnabled) { _, newValue in
                    hasUnsavedChanges = true
                    Task {
                        if newValue {
                            await handleNotificationToggleOn()
                        } else {
                            notificationService.cancelAll()
                        }
                    }
                }

                if notificationsEnabled {
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
                            selection: $preferredNotificationTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(AppTheme.textPrimary)
                        .colorScheme(.dark)
                        .onChange(of: preferredNotificationTime) { _, newTime in
                            hasUnsavedChanges = true
                            Task {
                                await notificationService.scheduleDaily(at: newTime)
                            }
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
                // Lunar Birthday
                HStack {
                    Text("Lunar birthday")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)

                    Spacer()

                    Text(derivedLunarBirthday)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(AppTheme.textPrimary)
                }

                Rectangle()
                    .fill(AppTheme.divider)
                    .frame(height: 1)

                // Chinese Zodiac
                HStack {
                    Text("Zodiac year")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)

                    Spacer()

                    Text(derivedZodiac)
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
            if let saveError {
                Text(saveError)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(red: 0.9, green: 0.4, blue: 0.4))
                    .multilineTextAlignment(.center)
            }

            Button {
                saveData()
            } label: {
                Group {
                    if isSaving {
                        ProgressView()
                            .tint(AppTheme.earth)
                    } else {
                        Text(saveError != nil ? "Retry Save" : "Save Changes")
                            .font(.system(size: 17, weight: .medium))
                    }
                }
                .foregroundColor(AppTheme.earth)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(AppTheme.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isSaving)
        }
        .padding(.top, 8)
    }

    // MARK: - Log Out Section

    private var logoutSection: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(AppTheme.divider)
                .frame(height: 1)
                .padding(.bottom, 24)

            Button {
                showLogoutConfirmation = true
            } label: {
                Text("Log Out")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(Color(red: 0.9, green: 0.4, blue: 0.4))
            }
            .accessibilityIdentifier("you.logoutButton")
        }
        .padding(.top, 8)
    }

    // MARK: - Derived Data (Placeholder Logic)

    private var derivedLunarBirthday: String {
        DerivedData.lunarBirthday(from: birthDate)
    }

    private var derivedZodiac: String {
        DerivedData.zodiacAnimal(from: birthDate)
    }

    // MARK: - Data Operations

    private func performLogout() {
        do {
            try authService.signOut()
        } catch {
            logoutError = "Something went wrong. Please try again."
        }
    }

    private func handleNotificationToggleOn() async {
        await notificationService.checkStatus()
        switch notificationService.authorizationStatus {
        case .notDetermined:
            let granted = (try? await notificationService.requestAuthorization()) ?? false
            if granted {
                await notificationService.scheduleDaily(at: preferredNotificationTime)
            } else {
                notificationsEnabled = false
            }
        case .authorized, .provisional, .ephemeral:
            await notificationService.scheduleDaily(at: preferredNotificationTime)
        case .denied:
            notificationsEnabled = false
            showNotificationDeniedAlert = true
        @unknown default:
            break
        }
    }

    /// Loads onboarding data from Firestore: users/{uid}/onboarding/context
    private func loadData() {
        guard let uid = authService.currentUserId else {
            isLoading = false
            return
        }

        Task {
            do {
                guard let data = try await onboardingService.loadOnboardingData(userId: uid) else {
                    isLoading = false
                    return
                }

                // Load birth date
                if let timestamp = data["birthDate"] as? Timestamp {
                    birthDate = timestamp.dateValue()
                    selectedDate = timestamp.dateValue()
                    hasSelectedDate = true
                }

                // Load birth time
                if let timestamp = data["birthTime"] as? Timestamp {
                    birthTime = timestamp.dateValue()
                    selectedTime = timestamp.dateValue()
                    hasSelectedTime = true
                }

                // Load personal anchors
                if let anchorsArray = data["personalAnchors"] as? [String] {
                    personalAnchors = Set(anchorsArray.compactMap { PersonalAnchor(rawValue: $0) })
                }

                // Load notification preferences
                if let notifEnabled = data["notificationsEnabled"] as? Bool {
                    notificationsEnabled = notifEnabled
                }
                if let notifTimestamp = data["preferredNotificationTime"] as? Timestamp {
                    preferredNotificationTime = notifTimestamp.dateValue()
                }

                isLoading = false
            } catch {
                isLoading = false
            }
        }
    }

    /// Saves changes to Firestore: users/{uid}/onboarding/context
    private func saveData() {
        guard let uid = authService.currentUserId else { return }

        var updateData: [String: Any] = [
            "personalAnchors": personalAnchors.map { $0.rawValue },
            "notificationsEnabled": notificationsEnabled,
            "preferredNotificationTime": Timestamp(date: preferredNotificationTime),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        if let date = birthDate {
            updateData["birthDate"] = Timestamp(date: date)
        } else {
            updateData["birthDate"] = FieldValue.delete()
        }

        if let time = birthTime {
            updateData["birthTime"] = Timestamp(date: time)
        } else {
            updateData["birthTime"] = FieldValue.delete()
        }

        isSaving = true
        saveError = nil
        Task {
            do {
                try await onboardingService.updateOnboardingData(userId: uid, data: updateData)
                hasUnsavedChanges = false
            } catch {
                saveError = "Could not save changes. Please try again."
            }
            isSaving = false
        }
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
}
