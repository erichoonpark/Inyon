import Foundation
import FirebaseFirestore

// MARK: - YouViewModel

@MainActor
final class YouViewModel: ObservableObject {

    // MARK: - Dependencies

    /// Set by YouView before calling loadData() (injected from EnvironmentObject)
    var authService: AuthServiceProtocol?
    private let onboardingService: OnboardingServiceProtocol
    private let notificationService: NotificationServiceProtocol

    // MARK: - Personal Info

    @Published var firstName = ""
    @Published var lastName = ""
    @Published var birthLocation = ""

    // MARK: - Birth Context

    @Published var birthDate: Date?
    @Published var birthTime: Date?
    @Published var selectedDate = Date()
    @Published var selectedTime = Date()
    @Published var hasSelectedDate = false
    @Published var hasSelectedTime = false
    @Published var personalAnchors: Set<PersonalAnchor> = []

    // MARK: - Notifications

    @Published var notificationsEnabled = false
    @Published var preferredNotificationTime: Date
    @Published var showNotificationDeniedAlert = false

    // MARK: - UI State

    @Published var isLoading = true
    @Published var isPerformingLoad = false
    @Published var isSaving = false
    @Published var saveError: String?
    @Published var hasUnsavedChanges = false
    @Published var showSaveConfirmation = false
    @Published var showLogoutConfirmation = false
    @Published var logoutError: String?

    // MARK: - Init

    init(
        onboardingService: OnboardingServiceProtocol = OnboardingService(),
        notificationService: NotificationServiceProtocol? = nil
    ) {
        self.onboardingService = onboardingService
        self.notificationService = notificationService ?? NotificationService()
        self.preferredNotificationTime = Calendar.current.date(
            bySettingHour: 8, minute: 0, second: 0, of: Date()
        ) ?? Date()
    }

    // MARK: - Load

    func loadData() async {
        guard let uid = authService?.currentUserId else {
            isLoading = false
            return
        }

        isPerformingLoad = true
        defer {
            isPerformingLoad = false
            hasUnsavedChanges = false
        }

        do {
            guard let data = try await onboardingService.loadOnboardingData(userId: uid) else {
                isLoading = false
                return
            }

            if let fn = data["firstName"] as? String { firstName = fn }
            if let ln = data["lastName"] as? String { lastName = ln }
            if let bl = data["birthLocation"] as? String { birthLocation = bl }

            if let timestamp = data["birthDate"] as? Timestamp {
                birthDate = timestamp.dateValue()
                selectedDate = timestamp.dateValue()
                hasSelectedDate = true
            }

            if let timestamp = data["birthTime"] as? Timestamp {
                birthTime = timestamp.dateValue()
                selectedTime = timestamp.dateValue()
                hasSelectedTime = true
            }

            if let anchorsArray = data["personalAnchors"] as? [String] {
                personalAnchors = Set(anchorsArray.compactMap { PersonalAnchor(rawValue: $0) })
            }

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

    // MARK: - Save

    func saveData() async {
        guard let uid = authService?.currentUserId else { return }

        var updateData: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "personalAnchors": personalAnchors.map { $0.rawValue },
            "notificationsEnabled": notificationsEnabled,
            "preferredNotificationTime": Timestamp(date: preferredNotificationTime),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        updateData["birthLocation"] = birthLocation.isEmpty
            ? FieldValue.delete()
            : birthLocation

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
        do {
            try await onboardingService.updateOnboardingData(userId: uid, data: updateData)
            hasUnsavedChanges = false
            showSaveConfirmation = true
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                showSaveConfirmation = false
            }
        } catch {
            saveError = "Could not save changes. Please try again."
        }
        isSaving = false
    }

    // MARK: - Notifications

    func handleNotificationToggleOn() async {
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

    func cancelNotifications() {
        notificationService.cancelAll()
    }

    func rescheduleNotifications(at time: Date) async {
        await notificationService.scheduleDaily(at: time)
    }

    // MARK: - Logout

    func performLogout() {
        do {
            try authService?.signOut()
        } catch {
            logoutError = "Something went wrong. Please try again."
        }
    }

    // MARK: - Change Tracking

    /// Called from view onChange handlers for text fields
    func fieldChanged() {
        guard !isPerformingLoad else { return }
        hasUnsavedChanges = true
    }

    /// Called from view when birth date picker changes
    func birthDateChanged(_ date: Date) {
        guard !isPerformingLoad else { return }
        guard birthDate != date else { return }
        hasSelectedDate = true
        birthDate = date
        hasUnsavedChanges = true
    }

    /// Called from view when birth time picker changes
    func birthTimeChanged(_ time: Date) {
        guard !isPerformingLoad else { return }
        guard birthTime != time else { return }
        hasSelectedTime = true
        birthTime = time
        hasUnsavedChanges = true
    }

    /// Called when the user taps "Clear" on birth time
    func clearBirthTime() {
        hasSelectedTime = false
        birthTime = nil
        hasUnsavedChanges = true
    }

    /// Called from view when notification toggle changes
    func notificationEnabledChanged(_ enabled: Bool) {
        hasUnsavedChanges = true
        if enabled {
            Task { await handleNotificationToggleOn() }
        } else {
            cancelNotifications()
        }
    }

    /// Called from view when notification time picker changes
    func notificationTimeChanged(_ time: Date) {
        hasUnsavedChanges = true
        Task { await rescheduleNotifications(at: time) }
    }

    /// Called when user taps an anchor chip
    func toggleAnchor(_ anchor: PersonalAnchor) {
        if personalAnchors.contains(anchor) {
            personalAnchors.remove(anchor)
        } else {
            personalAnchors.insert(anchor)
        }
        hasUnsavedChanges = true
    }
}
