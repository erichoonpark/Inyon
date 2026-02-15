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
        // 1924 is a Rat year (base year)
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
        // 2000 is a Dragon year: (2000 - 1924) % 12 = 76 % 12 = 4 → Dragon
        let date = makeDate(year: 2000)
        XCTAssertEqual(DerivedData.zodiacAnimal(from: date), "Dragon")
    }

    func test_zodiacAnimal_fullCycle() {
        let expected = ["Rat", "Ox", "Tiger", "Rabbit", "Dragon", "Snake",
                       "Horse", "Goat", "Monkey", "Rooster", "Dog", "Pig"]

        for (offset, animal) in expected.enumerated() {
            let date = makeDate(year: 1924 + offset)
            XCTAssertEqual(DerivedData.zodiacAnimal(from: date), animal,
                          "Year \(1924 + offset) should be \(animal)")
        }
    }

    func test_zodiacAnimal_cycleRepeats() {
        // 1924 and 1936 should both be Rat
        let rat1 = makeDate(year: 1924)
        let rat2 = makeDate(year: 1936)
        let rat3 = makeDate(year: 1996)

        XCTAssertEqual(DerivedData.zodiacAnimal(from: rat1), "Rat")
        XCTAssertEqual(DerivedData.zodiacAnimal(from: rat2), "Rat")
        XCTAssertEqual(DerivedData.zodiacAnimal(from: rat3), "Rat")
    }

    func test_zodiacAnimal_recentYears() {
        // Verify common recent years
        XCTAssertEqual(DerivedData.zodiacAnimal(from: makeDate(year: 1990)), "Horse")
        XCTAssertEqual(DerivedData.zodiacAnimal(from: makeDate(year: 1995)), "Pig")
        XCTAssertEqual(DerivedData.zodiacAnimal(from: makeDate(year: 2024)), "Dragon")
    }

    func test_zodiacAnimal_yearBefore1924() {
        // 1920: (1920 - 1924) % 12 = -4 % 12 → needs safe index → Monkey
        // -4 + 12 = 8 → Monkey
        let date = makeDate(year: 1920)
        XCTAssertEqual(DerivedData.zodiacAnimal(from: date), "Monkey")
    }

    func test_zodiacAnimal_farPast() {
        // 1900: (1900 - 1924) % 12 = -24 % 12 = 0 → Rat
        let date = makeDate(year: 1900)
        XCTAssertEqual(DerivedData.zodiacAnimal(from: date), "Rat")
    }

    // MARK: - Lunar Birthday

    func test_lunarBirthday_nilDate_returnsDash() {
        XCTAssertEqual(DerivedData.lunarBirthday(from: nil), "—")
    }

    func test_lunarBirthday_validDate_containsApprox() {
        let date = makeDate(year: 1990, month: 6, day: 15)
        let result = DerivedData.lunarBirthday(from: date)

        XCTAssertTrue(result.hasSuffix("(approx.)"))
    }

    func test_lunarBirthday_formatsMonthAndDay() {
        let date = makeDate(year: 1990, month: 3, day: 22)
        let result = DerivedData.lunarBirthday(from: date)

        // Should contain "Mar 22"
        XCTAssertTrue(result.contains("Mar"), "Should contain abbreviated month")
        XCTAssertTrue(result.contains("22"), "Should contain day")
    }

    func test_lunarBirthday_january1() {
        let date = makeDate(year: 2000, month: 1, day: 1)
        let result = DerivedData.lunarBirthday(from: date)

        XCTAssertTrue(result.contains("Jan"))
        XCTAssertTrue(result.contains("1"))
    }

    func test_lunarBirthday_december31() {
        let date = makeDate(year: 2000, month: 12, day: 31)
        let result = DerivedData.lunarBirthday(from: date)

        XCTAssertTrue(result.contains("Dec"))
        XCTAssertTrue(result.contains("31"))
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
