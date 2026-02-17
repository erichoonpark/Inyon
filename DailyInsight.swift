import Foundation

struct DailyInsight: Codable {
    let localDate: String
    let timeZoneId: String
    let dayElement: String
    let elementTheme: String
    let heavenlyStem: String
    let earthlyBranch: String
    let insightText: String
    let generatedAt: Date
    let version: String
}
