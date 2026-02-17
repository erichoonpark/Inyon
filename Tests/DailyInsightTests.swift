import XCTest
@testable import Inyon

final class DailyInsightTests: XCTestCase {

    // MARK: - Model Decoding

    func testDecodingFromJSON() throws {
        let json = """
        {
            "localDate": "2026-02-16",
            "timeZoneId": "America/Los_Angeles",
            "dayElement": "Wood",
            "elementTheme": "Growth, flexibility, vision",
            "heavenlyStem": "Gab",
            "earthlyBranch": "Ja",
            "insightText": "Today carries a quiet tone. Conditions may favor reflection over action. Patience tends to serve well in these moments.",
            "generatedAt": 1739750400,
            "version": "v1"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let insight = try decoder.decode(DailyInsight.self, from: json)

        XCTAssertEqual(insight.localDate, "2026-02-16")
        XCTAssertEqual(insight.timeZoneId, "America/Los_Angeles")
        XCTAssertEqual(insight.dayElement, "Wood")
        XCTAssertEqual(insight.elementTheme, "Growth, flexibility, vision")
        XCTAssertEqual(insight.heavenlyStem, "Gab")
        XCTAssertEqual(insight.earthlyBranch, "Ja")
        XCTAssertEqual(insight.version, "v1")
        XCTAssertFalse(insight.insightText.isEmpty)
    }

    func testDecodingFailsWithMissingFields() {
        let json = """
        {
            "localDate": "2026-02-16",
            "dayElement": "Wood"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(DailyInsight.self, from: json))
    }
}
