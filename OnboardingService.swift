import Foundation
import FirebaseFirestore

final class OnboardingService: OnboardingServiceProtocol {
    private lazy var db = Firestore.firestore()

    func saveOnboardingData(_ data: OnboardingData, userId: String?) async throws {
        let firestoreData = data.toFirestoreData()

        let documentRef: DocumentReference

        if let uid = userId {
            documentRef = db.collection("users").document(uid)
                .collection("onboarding").document("context")
        } else {
            let anonymousId = UUID().uuidString
            documentRef = db.collection("onboarding").document("anonymous")
                .collection("users").document(anonymousId)
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
}
