import Foundation

protocol OnboardingServiceProtocol {
    func saveOnboardingData(_ data: OnboardingData, userId: String?) async throws
    func loadOnboardingData(userId: String) async throws -> [String: Any]?
    func updateOnboardingData(userId: String, data: [String: Any]) async throws
    func migrateAnonymousData(toUserId userId: String) async throws
}
