import XCTest
@testable import Inyon

// MARK: - Derived Data Tests
//
// Tests the zodiac animal and lunar birthday calculations
// used in YouView's Cultural Context section.

final class DerivedDataTests: XCTestCase {

    // MARK: - Zodiac Animal

    func test_zodiacAnimal_nilDate_returnsDash() {
        XCTAssertEqual(DerivedData.zodiacAnimal(from: nil), "—")
    }

    func test_zodiacAnimal_ratYear() {
        // 1924 is a Rat year, born in June (well after LNY)
        let date = makeDate(year: 1924)
        XCTAssertEqual(DerivedData.zodiacAnimal(from: date), "Rat")
    }

    func test_zodiacAnimal_oxYear() {
        let date = makeDate(year: 1925)
        XCTAssertEqual(DerivedData.zodiacAnimal(from: date), "Ox")
    }

    func test_zodiacAnimal_tigerYear() {
        let date = makeDate(year: 1926)
        XCTAssertEqual(DerivedData.zodiacAnimal(from: date), "Tiger")
    }

    func test_zodiacAnimal_dragonYear() {
        // 2000 is a Dragon year (born in June, well after LNY Feb 5)
        let date = makeDate(year: 2000)
        XCTAssertEqual(DerivedData.zodiacAnimal(from: date), "Dragon")
    }

    func test_zodiacAnimal_fullCycle() {
        let expected = ["Rat", "Ox", "Tiger", "Rabbit", "Dragon", "Snake",
                       "Horse", "Goat", "Monkey", "Rooster", "Dog", "Pig"]

        // Use June dates to be well after LNY for all years
        for (offset, animal) in expected.enumerated() {
            let date = makeDate(year: 1924 + offset)
            XCTAssertEqual(DerivedData.zodiacAnimal(from: date), animal,
                          "Year \(1924 + offset) should be \(animal)")
        }
    }

    func test_zodiacAnimal_cycleRepeats() {
        let rat1 = makeDate(year: 1924)
        let rat2 = makeDate(year: 1936)
        let rat3 = makeDate(year: 1996)

        XCTAssertEqual(DerivedData.zodiacAnimal(from: rat1), "Rat")
        XCTAssertEqual(DerivedData.zodiacAnimal(from: rat2), "Rat")
        XCTAssertEqual(DerivedData.zodiacAnimal(from: rat3), "Rat")
    }

    func test_zodiacAnimal_recentYears() {
        XCTAssertEqual(DerivedData.zodiacAnimal(from: makeDate(year: 1990)), "Horse")
        XCTAssertEqual(DerivedData.zodiacAnimal(from: makeDate(year: 1995)), "Pig")
        XCTAssertEqual(DerivedData.zodiacAnimal(from: makeDate(year: 2024)), "Dragon")
    }

    func test_zodiacAnimal_yearBefore1924() {
        // 1920, June: well after LNY (Feb 20), so lunar year = 1920
        // (1920 - 1924) % 12 = -4, + 12 = 8 → Monkey
        let date = makeDate(year: 1920)
        XCTAssertEqual(DerivedData.zodiacAnimal(from: date), "Monkey")
    }

    // MARK: - Zodiac with Lunar New Year Boundary

    func test_zodiacAnimal_beforeLunarNewYear_usesPreviousYear() {
        // 2023 LNY is Jan 22. Born Jan 15, 2023 → still Year of Tiger (2022's animal)
        // 2022 lunar year: (2022 - 1924) % 12 = 98 % 12 = 2 → Tiger
        let date = makeDate(year: 2023, month: 1, day: 15)
        XCTAssertEqual(DerivedData.zodiacAnimal(from: date), "Tiger")
    }

    func test_zodiacAnimal_onLunarNewYear_usesCurrentYear() {
        // 2023 LNY is Jan 22. Born Jan 22 → Year of Rabbit
        // (2023 - 1924) % 12 = 99 % 12 = 3 → Rabbit
        let date = makeDate(year: 2023, month: 1, day: 22)
        XCTAssertEqual(DerivedData.zodiacAnimal(from: date), "Rabbit")
    }

    func test_zodiacAnimal_afterLunarNewYear_usesCurrentYear() {
        // 2023 LNY is Jan 22. Born Feb 1 → Year of Rabbit
        let date = makeDate(year: 2023, month: 2, day: 1)
        XCTAssertEqual(DerivedData.zodiacAnimal(from: date), "Rabbit")
    }

    func test_zodiacAnimal_earlyJanuary2025_beforeLNY() {
        // 2025 LNY is Jan 29. Born Jan 10 → still Dragon (2024 animal)
        // (2024 - 1924) % 12 = 100 % 12 = 4 → Dragon
        let date = makeDate(year: 2025, month: 1, day: 10)
        XCTAssertEqual(DerivedData.zodiacAnimal(from: date), "Dragon")
    }

    func test_zodiacAnimal_afterLNY2025() {
        // 2025 LNY is Jan 29. Born Feb 1 → Year of Snake
        // (2025 - 1924) % 12 = 101 % 12 = 5 → Snake
        let date = makeDate(year: 2025, month: 2, day: 1)
        XCTAssertEqual(DerivedData.zodiacAnimal(from: date), "Snake")
    }

    // MARK: - Lunar Birthday

    func test_lunarBirthday_nilDate_returnsDash() {
        XCTAssertEqual(DerivedData.lunarBirthday(from: nil), "—")
    }

    func test_lunarBirthday_validDate_returnsAbbreviatedFormat() {
        let date = makeDate(year: 1990, month: 6, day: 15)
        let result = DerivedData.lunarBirthday(from: date)
        // Should be "MMM D" format like "May 23", not "Month X, Day Y"
        let validPrefixes = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                             "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        XCTAssertTrue(validPrefixes.contains(where: { result.hasPrefix($0) }),
                      "Expected abbreviated month prefix, got: \(result)")
        XCTAssertFalse(result.hasPrefix("Month "), "Should not use 'Month X' format, got: \(result)")
    }

    func test_lunarBirthday_differentDate_returnsAbbreviatedFormat() {
        let date = makeDate(year: 2000, month: 1, day: 1)
        let result = DerivedData.lunarBirthday(from: date)
        let validPrefixes = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                             "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        XCTAssertTrue(validPrefixes.contains(where: { result.hasPrefix($0) }),
                      "Expected abbreviated month prefix, got: \(result)")
    }

    // MARK: - Helpers

    private func makeDate(year: Int, month: Int = 6, day: Int = 15) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)!
    }
}
