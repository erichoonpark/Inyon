import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoadingUser = false

    private let userService: UserServiceProtocol

    init(userService: UserServiceProtocol = UserService()) {
        self.userService = userService
    }

    func clearUser() {
        currentUser = nil
        isLoadingUser = false
    }

    func loadUser(id: String) async {
        isLoadingUser = true
        do {
            currentUser = try await userService.fetchUser(id: id)
        } catch {
            print("Failed to load user: \(error)")
        }
        isLoadingUser = false
    }
}
