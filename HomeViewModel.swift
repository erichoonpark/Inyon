import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case ready
        case error
    }

    @Published var state: LoadState = .idle
    @Published var currentInsight: DailyInsight?
    @Published var lastKnownInsight: DailyInsight?

    private let service: DailyInsightServiceProtocol

    init(service: DailyInsightServiceProtocol = DailyInsightService()) {
        self.service = service
    }

    func loadTodayInsight() {
        guard state != .loading else { return }
        state = .loading

        let timeZoneId = TimeZone.current.identifier
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        let localDate = formatter.string(from: Date())

        Task {
            do {
                let insight = try await service.fetchDailyInsight(
                    timeZoneId: timeZoneId,
                    localDate: localDate
                )
                currentInsight = insight
                lastKnownInsight = insight
                state = .ready
            } catch {
                state = .error
            }
        }
    }

    func retry() {
        loadTodayInsight()
    }
}
