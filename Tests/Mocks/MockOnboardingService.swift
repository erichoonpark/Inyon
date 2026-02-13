import Foundation
@testable import Inyon

final class MockOnboardingService: OnboardingServiceProtocol {
    // Call recording
    var savedData: [(data: OnboardingData, userId: String?)] = []
    var loadedUserIds: [String] = []
    var updatedData: [(userId: String, data: [String: Any])] = []

    // In-memory storage
    var storedPayloads: [String: [String: Any]] = [:]

    // Controllable results
    var saveResult: Result<Void, Error> = .success(())
    var loadResult: Result<[String: Any]?, Error>?
    var updateResult: Result<Void, Error> = .success(())

    func saveOnboardingData(_ data: OnboardingData, userId: String?) async throws {
        savedData.append((data, userId))
        switch saveResult {
        case .success:
            let key = userId ?? "anonymous"
            storedPayloads[key] = data.toFirestoreData()
        case .failure(let error):
            throw error
        }
    }

    func loadOnboardingData(userId: String) async throws -> [String: Any]? {
        loadedUserIds.append(userId)
        if let loadResult {
            switch loadResult {
            case .success(let data):
                return data
            case .failure(let error):
                throw error
            }
        }
        return storedPayloads[userId]
    }

    func updateOnboardingData(userId: String, data: [String: Any]) async throws {
        updatedData.append((userId, data))
        switch updateResult {
        case .success:
            storedPayloads[userId] = data
        case .failure(let error):
            throw error
        }
    }
}
