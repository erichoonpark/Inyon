import Foundation
@testable import Inyon

final class MockDailyInsightService: DailyInsightServiceProtocol {
    var fetchCalls: [(timeZoneId: String, localDate: String)] = []
    var fetchResult: Result<DailyInsight, Error> = .failure(DailyInsightError.invalidResponse)

    func fetchDailyInsight(timeZoneId: String, localDate: String) async throws -> DailyInsight {
        fetchCalls.append((timeZoneId: timeZoneId, localDate: localDate))
        switch fetchResult {
        case .success(let insight):
            return insight
        case .failure(let error):
            throw error
        }
    }
}
