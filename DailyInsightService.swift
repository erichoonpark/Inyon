import Foundation
import FirebaseFunctions

protocol DailyInsightServiceProtocol {
    func fetchDailyInsight(timeZoneId: String, localDate: String) async throws -> DailyInsight
}

final class DailyInsightService: DailyInsightServiceProtocol {
    private let functions = Functions.functions()

    func fetchDailyInsight(timeZoneId: String, localDate: String) async throws -> DailyInsight {
        let data: [String: Any] = [
            "timeZoneId": timeZoneId,
            "localDate": localDate
        ]

        let result = try await functions.httpsCallable("getDailyInsight").call(data)

        guard let responseDict = result.data as? [String: Any] else {
            throw DailyInsightError.invalidResponse
        }

        return try parseInsight(from: responseDict)
    }

    private func parseInsight(from dict: [String: Any]) throws -> DailyInsight {
        guard
            let localDate = dict["localDate"] as? String,
            let timeZoneId = dict["timeZoneId"] as? String,
            let dayElement = dict["dayElement"] as? String,
            let elementTheme = dict["elementTheme"] as? String,
            let heavenlyStem = dict["heavenlyStem"] as? String,
            let earthlyBranch = dict["earthlyBranch"] as? String,
            let insightText = dict["insightText"] as? String,
            let version = dict["version"] as? String
        else {
            throw DailyInsightError.missingFields
        }

        let generatedAt: Date
        if let timestamp = dict["generatedAt"] as? Double {
            generatedAt = Date(timeIntervalSince1970: timestamp / 1000)
        } else {
            generatedAt = Date()
        }

        return DailyInsight(
            localDate: localDate,
            timeZoneId: timeZoneId,
            dayElement: dayElement,
            elementTheme: elementTheme,
            heavenlyStem: heavenlyStem,
            earthlyBranch: earthlyBranch,
            insightText: insightText,
            generatedAt: generatedAt,
            version: version
        )
    }
}

enum DailyInsightError: LocalizedError {
    case invalidResponse
    case missingFields

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Unable to read today's reflection."
        case .missingFields:
            return "Today's reflection is incomplete."
        }
    }
}
