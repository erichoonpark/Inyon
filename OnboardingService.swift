import Foundation
import FirebaseFirestore

protocol OnboardingMigrationExecuting {
    /// Returns true when anonymous data existed and was migrated.
    func migrateAnonymousData(anonymousSessionId: String, toUserId userId: String) async throws -> Bool
}

func mergeOnboardingMigrationData(
    anonymousData: [String: Any],
    existingUserData: [String: Any]?
) -> [String: Any] {
    guard let existingUserData else { return anonymousData }

    // Existing authenticated fields win over anonymous fields.
    var merged = anonymousData
    for (key, value) in existingUserData {
        merged[key] = value
    }
    return merged
}

private final class FirestoreOnboardingMigrationExecutor: OnboardingMigrationExecuting {
    func migrateAnonymousData(anonymousSessionId: String, toUserId userId: String) async throws -> Bool {
        let db = Firestore.firestore()
        let anonymousRef = db.collection("onboarding").document("anonymous")
            .collection("users").document(anonymousSessionId)
        let userRef = db.collection("users").document(userId)
            .collection("onboarding").document("context")

        return try await withCheckedThrowingContinuation { continuation in
            db.runTransaction({ transaction, errorPointer -> Any? in
                do {
                    let anonymousSnapshot = try transaction.getDocument(anonymousRef)
                    guard let anonymousData = anonymousSnapshot.data() else {
                        return false
                    }

                    let userSnapshot = try transaction.getDocument(userRef)
                    let merged = mergeOnboardingMigrationData(
                        anonymousData: anonymousData,
                        existingUserData: userSnapshot.data()
                    )

                    transaction.setData(merged, forDocument: userRef)
                    transaction.deleteDocument(anonymousRef)
                    return true
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }, completion: { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (result as? Bool) ?? false)
            })
        }
    }
}

final class OnboardingService: OnboardingServiceProtocol {
    private lazy var db = Firestore.firestore()

    static let anonymousIdKey = "inyon.anonymousSessionId"

    private let userDefaults: UserDefaults
    private let migrationExecutor: OnboardingMigrationExecuting

    init(
        userDefaults: UserDefaults = .standard,
        migrationExecutor: OnboardingMigrationExecuting = FirestoreOnboardingMigrationExecutor()
    ) {
        self.userDefaults = userDefaults
        self.migrationExecutor = migrationExecutor
    }

    private var anonymousSessionId: String {
        if let existing = userDefaults.string(forKey: Self.anonymousIdKey) {
            return existing
        }
        let newId = UUID().uuidString
        userDefaults.set(newId, forKey: Self.anonymousIdKey)
        return newId
    }

    func saveOnboardingData(_ data: OnboardingData, userId: String?) async throws {
        let firestoreData = data.toFirestoreData()

        let documentRef: DocumentReference

        if let uid = userId {
            documentRef = db.collection("users").document(uid)
                .collection("onboarding").document("context")
        } else {
            documentRef = db.collection("onboarding").document("anonymous")
                .collection("users").document(anonymousSessionId)
        }

        try await documentRef.setData(firestoreData)
    }

    func loadOnboardingData(userId: String) async throws -> [String: Any]? {
        let docRef = db.collection("users").document(userId)
            .collection("onboarding").document("context")

        let snapshot = try await docRef.getDocument()
        return snapshot.data()
    }

    func updateOnboardingData(userId: String, data: [String: Any]) async throws {
        let docRef = db.collection("users").document(userId)
            .collection("onboarding").document("context")

        try await docRef.setData(data, merge: true)
    }

    func migrateAnonymousData(toUserId userId: String) async throws {
        let migrated = try await migrationExecutor.migrateAnonymousData(
            anonymousSessionId: anonymousSessionId,
            toUserId: userId
        )
        if migrated {
            userDefaults.removeObject(forKey: Self.anonymousIdKey)
        }
    }
}
