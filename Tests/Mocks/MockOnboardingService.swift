import Foundation
@testable import Inyon

final class MockOnboardingService: OnboardingServiceProtocol {
    // Call recording
    var savedData: [(data: OnboardingData, userId: String?)] = []
    var loadedUserIds: [String] = []
    var updatedData: [(userId: String, data: [String: Any])] = []
    var migrateCalls: [String] = []

    // In-memory storage
    var storedPayloads: [String: [String: Any]] = [:]

    // Controllable results
    var saveResult: Result<Void, Error> = .success(())
    var loadResult: Result<[String: Any]?, Error>?
    var updateResult: Result<Void, Error> = .success(())
    var migrateResult: Result<Void, Error> = .success(())

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

    func migrateAnonymousData(toUserId userId: String) async throws {
        migrateCalls.append(userId)
        switch migrateResult {
        case .success:
            // Move anonymous data to user key
            if let anonData = storedPayloads["anonymous"] {
                if let existing = storedPayloads[userId] {
                    // Merge: existing data wins over anonymous
                    var merged = anonData
                    for (key, value) in existing {
                        merged[key] = value
                    }
                    storedPayloads[userId] = merged
                } else {
                    storedPayloads[userId] = anonData
                }
                storedPayloads.removeValue(forKey: "anonymous")
            }
        case .failure(let error):
            throw error
        }
    }
}
