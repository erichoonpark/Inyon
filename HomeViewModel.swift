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
    private static let tonePreferenceKey = "inyon.tonePreference.v1"

    // Cache key includes tone so a change in preference triggers a fresh fetch
    private var cacheKey: String {
        "inyon.cachedInsight.v1.\(currentTonePreference.rawValue)"
    }

    private var currentTonePreference: InsightTonePreference {
        InsightTonePreference(
            rawValue: UserDefaults.standard.string(forKey: Self.tonePreferenceKey) ?? ""
        ) ?? .sharp
    }

    var todayLocalDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: Date())
    }

    var todayTimeZoneId: String {
        TimeZone.current.identifier
    }

    init(service: DailyInsightServiceProtocol = DailyInsightService()) {
        self.service = service
        if let cached = loadCachedInsight(), isValidForToday(cached) {
            currentInsight = cached
            lastKnownInsight = cached
            state = .ready
        }
    }

    func loadTodayInsight() {
        let hasCachedContent = state == .ready

        if !hasCachedContent {
            guard state != .loading else { return }
            state = .loading
        }

        let timeZoneId = todayTimeZoneId
        let localDate = todayLocalDate
        let tonePreference = currentTonePreference

        Task {
            do {
                let insight = try await service.fetchDailyInsight(
                    timeZoneId: timeZoneId,
                    localDate: localDate,
                    tonePreference: tonePreference
                )
                currentInsight = insight
                lastKnownInsight = insight
                saveInsightToCache(insight)
                state = .ready
            } catch {
                if !hasCachedContent {
                    state = .error
                }
                // If cached content is visible, swallow the error silently
            }
        }
    }

    private var lastRetryDate: Date?

    func retry() {
        if let last = lastRetryDate, Date().timeIntervalSince(last) < 5 {
            return
        }
        lastRetryDate = Date()
        state = .idle
        loadTodayInsight()
    }

    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
    }

    // MARK: - Cache

    private func loadCachedInsight() -> DailyInsight? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let insight = try? JSONDecoder().decode(DailyInsight.self, from: data)
        else { return nil }
        return insight
    }

    private func saveInsightToCache(_ insight: DailyInsight) {
        if let data = try? JSONEncoder().encode(insight) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }

    private func isValidForToday(_ insight: DailyInsight) -> Bool {
        insight.localDate == todayLocalDate && insight.timeZoneId == todayTimeZoneId
    }
}
