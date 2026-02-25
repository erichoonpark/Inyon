import Foundation
import UserNotifications

// MARK: - Protocol

protocol NotificationServiceProtocol: AnyObject {
    var authorizationStatus: UNAuthorizationStatus { get }
    func checkStatus() async
    func requestAuthorization() async throws -> Bool
    func scheduleDaily(at time: Date) async
    func cancelAll()
}

// MARK: - Implementation

@MainActor
final class NotificationService: ObservableObject, NotificationServiceProtocol {
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()
    private let notificationId = "inyon-daily-reflection"

    func checkStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func requestAuthorization() async throws -> Bool {
        let granted = try await center.requestAuthorization(options: [.alert, .sound])
        await checkStatus()
        return granted
    }

    func scheduleDaily(at time: Date) async {
        center.removePendingNotificationRequests(withIdentifiers: [notificationId])

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "Inyon"
        content.body = "Your daily reflection is ready."
        content.sound = .default

        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func cancelAll() {
        center.removePendingNotificationRequests(withIdentifiers: [notificationId])
    }
}
