import Foundation
import FirebaseFirestore

final class OnboardingService: OnboardingServiceProtocol {
    private lazy var db = Firestore.firestore()

    private static let anonymousIdKey = "inyon.anonymousSessionId"

    private var anonymousSessionId: String {
        if let existing = UserDefaults.standard.string(forKey: Self.anonymousIdKey) {
            return existing
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: Self.anonymousIdKey)
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
        let anonRef = db.collection("onboarding").document("anonymous")
            .collection("users").document(anonymousSessionId)

        let snapshot = try await anonRef.getDocument()
        guard let anonData = snapshot.data() else { return }

        let userRef = db.collection("users").document(userId)
            .collection("onboarding").document("context")

        let userSnapshot = try await userRef.getDocument()

        if userSnapshot.exists {
            // Merge: anonymous data fills in missing fields only
            var merged = anonData
            if let existingData = userSnapshot.data() {
                for (key, value) in existingData {
                    merged[key] = value
                }
            }
            try await userRef.setData(merged)
        } else {
            try await userRef.setData(anonData)
        }

        // Clean up anonymous record
        try await anonRef.delete()
        UserDefaults.standard.removeObject(forKey: Self.anonymousIdKey)
    }
}
