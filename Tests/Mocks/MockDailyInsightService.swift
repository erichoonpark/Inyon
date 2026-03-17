import Foundation
@testable import Inyon

final class MockDailyInsightService: DailyInsightServiceProtocol {
    struct FetchCall {
        let timeZoneId: String
        let localDate: String
        let tonePreference: InsightTonePreference
    }

    var fetchCalls: [FetchCall] = []
    var fetchResult: Result<DailyInsight, Error> = .failure(DailyInsightError.invalidResponse)

    func fetchDailyInsight(
        timeZoneId: String,
        localDate: String,
        tonePreference: InsightTonePreference
    ) async throws -> DailyInsight {
        fetchCalls.append(FetchCall(timeZoneId: timeZoneId, localDate: localDate, tonePreference: tonePreference))
        switch fetchResult {
        case .success(let insight):
            return insight
        case .failure(let error):
            throw error
        }
    }
}
