import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

enum SocialAuthError: LocalizedError {
    case missingClientID
    case missingToken
    case missingPresenter
    case accountExistsWithDifferentCredential

    var errorDescription: String? {
        switch self {
        case .missingClientID: return "Google Sign-In is not configured."
        case .missingToken: return "Sign-in failed. Please try again."
        case .missingPresenter: return "Unable to present sign-in. Please try again."
        case .accountExistsWithDifferentCredential:
            return "An account already exists with this email. Try a different sign-in method."
        }
    }
}

enum AuthServiceError: LocalizedError {
    case forcedUITestSignInFailure
    case forcedUITestSignOutFailure

    var errorDescription: String? {
        switch self {
        case .forcedUITestSignInFailure:
            return "Unable to sign in. Check your credentials and try again."
        case .forcedUITestSignOutFailure:
            return "Unable to log out. Please try again."
        }
    }
}

@MainActor
final class AuthService: ObservableObject, AuthServiceProtocol {
    @Published var currentUserId: String?
    @Published var isLoading = true
    @Published private(set) var verified: Bool = false

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private let uiTestAuthMode: String?

    init() {
        #if DEBUG
        uiTestAuthMode = ProcessInfo.processInfo.environment["INYON_UI_TEST_AUTH_MODE"]
        #else
        uiTestAuthMode = nil
        #endif
        if uiTestAuthMode != nil {
            // Modes that test authenticated flows start signed in
            if uiTestAuthMode == "signed_in" || uiTestAuthMode == "sign_out_failure" {
                currentUserId = "ui-test-user"
            } else {
                currentUserId = nil
            }
            verified = true
            isLoading = false
            return
        }

        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUserId = user?.uid
            self?.verified = user?.isEmailVerified ?? false
            self?.isLoading = false
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    var isAuthenticated: Bool {
        currentUserId != nil
    }

    func createAccount(email: String, password: String) async throws -> String {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return result.user.uid
    }

    func signIn(email: String, password: String) async throws {
        if uiTestAuthMode == "sign_in_failure" {
            throw AuthServiceError.forcedUITestSignInFailure
        }
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func signOut() throws {
        if uiTestAuthMode != nil {
            if uiTestAuthMode == "sign_out_failure" {
                throw AuthServiceError.forcedUITestSignOutFailure
            }
            currentUserId = nil
            return
        }
        try Auth.auth().signOut()
    }

    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    func sendEmailVerification() async throws {
        guard let user = Auth.auth().currentUser else { return }
        try await user.sendEmailVerification()
    }

    func reloadUser() async throws {
        try await Auth.auth().currentUser?.reload()
        let nowVerified = Auth.auth().currentUser?.isEmailVerified ?? false
        if !verified && nowVerified, let uid = currentUserId {
            let db = Firestore.firestore()
            try? await db.collection("users").document(uid)
                .setData(["emailVerifiedAt": FieldValue.serverTimestamp()], merge: true)
        }
        verified = nowVerified
    }

    func signInWithGoogle() async throws {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            throw SocialAuthError.missingPresenter
        }
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
        guard let idToken = result.user.idToken?.tokenString else {
            throw SocialAuthError.missingToken
        }
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        do {
            let authResult = try await Auth.auth().signIn(with: credential)
            currentUserId = authResult.user.uid
            verified = authResult.user.isEmailVerified
        } catch let error as NSError {
            if error.code == AuthErrorCode.accountExistsWithDifferentCredential.rawValue {
                throw SocialAuthError.accountExistsWithDifferentCredential
            }
            throw error
        }
    }

    func signInWithApple(idToken: String, rawNonce: String, fullName: PersonNameComponents?) async throws {
        let credential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: rawNonce,
            fullName: fullName
        )
        do {
            let authResult = try await Auth.auth().signIn(with: credential)
            currentUserId = authResult.user.uid
            verified = authResult.user.isEmailVerified
        } catch let error as NSError {
            if error.code == AuthErrorCode.accountExistsWithDifferentCredential.rawValue {
                throw SocialAuthError.accountExistsWithDifferentCredential
            }
            throw error
        }
    }
}
