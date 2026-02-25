import Foundation
import UserNotifications
@testable import Inyon

final class MockNotificationService: NotificationServiceProtocol {
    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    // Call recording
    var scheduleCalls: [Date] = []
    var cancelCallCount = 0
    var checkStatusCallCount = 0
    var requestAuthorizationCallCount = 0

    // Controllable results
    var requestResult: Result<Bool, Error> = .success(true)

    func checkStatus() async {
        checkStatusCallCount += 1
    }

    func requestAuthorization() async throws -> Bool {
        requestAuthorizationCallCount += 1
        switch requestResult {
        case .success(let granted):
            if granted {
                authorizationStatus = .authorized
            } else {
                authorizationStatus = .denied
            }
            return granted
        case .failure(let error):
            throw error
        }
    }

    func scheduleDaily(at time: Date) async {
        scheduleCalls.append(time)
    }

    func cancelAll() {
        cancelCallCount += 1
    }
}
