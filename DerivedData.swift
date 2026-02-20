import Foundation

enum DerivedData {

    // MARK: - Lunar New Year Dates (Gregorian month, day)
    // Source: astronomical calculations of Chinese lunisolar calendar

    private static let lunarNewYearDates: [Int: (month: Int, day: Int)] = [
        1920: (2, 20), 1921: (2, 8), 1922: (1, 28), 1923: (2, 16), 1924: (2, 5),
        1925: (1, 24), 1926: (2, 13), 1927: (2, 2), 1928: (1, 23), 1929: (2, 10),
        1930: (1, 30), 1931: (2, 17), 1932: (2, 6), 1933: (1, 26), 1934: (2, 14),
        1935: (2, 4), 1936: (1, 24), 1937: (2, 11), 1938: (1, 31), 1939: (2, 19),
        1940: (2, 8), 1941: (1, 27), 1942: (2, 15), 1943: (2, 5), 1944: (1, 25),
        1945: (2, 13), 1946: (2, 2), 1947: (1, 22), 1948: (2, 10), 1949: (1, 29),
        1950: (2, 17), 1951: (2, 6), 1952: (1, 27), 1953: (2, 14), 1954: (2, 3),
        1955: (1, 24), 1956: (2, 12), 1957: (1, 31), 1958: (2, 18), 1959: (2, 8),
        1960: (1, 28), 1961: (2, 15), 1962: (2, 5), 1963: (1, 25), 1964: (2, 13),
        1965: (2, 2), 1966: (1, 21), 1967: (2, 9), 1968: (1, 30), 1969: (2, 17),
        1970: (2, 6), 1971: (1, 27), 1972: (2, 15), 1973: (2, 3), 1974: (1, 23),
        1975: (2, 11), 1976: (1, 31), 1977: (2, 18), 1978: (2, 7), 1979: (1, 28),
        1980: (2, 16), 1981: (2, 5), 1982: (1, 25), 1983: (2, 13), 1984: (2, 2),
        1985: (2, 20), 1986: (2, 9), 1987: (1, 29), 1988: (2, 17), 1989: (2, 6),
        1990: (1, 27), 1991: (2, 15), 1992: (2, 4), 1993: (1, 23), 1994: (2, 10),
        1995: (1, 31), 1996: (2, 19), 1997: (2, 7), 1998: (1, 28), 1999: (2, 16),
        2000: (2, 5), 2001: (1, 24), 2002: (2, 12), 2003: (2, 1), 2004: (1, 22),
        2005: (2, 9), 2006: (1, 29), 2007: (2, 18), 2008: (2, 7), 2009: (1, 26),
        2010: (2, 14), 2011: (2, 3), 2012: (1, 23), 2013: (2, 10), 2014: (1, 31),
        2015: (2, 19), 2016: (2, 8), 2017: (1, 28), 2018: (2, 16), 2019: (2, 5),
        2020: (1, 25), 2021: (2, 12), 2022: (2, 1), 2023: (1, 22), 2024: (2, 10),
        2025: (1, 29), 2026: (2, 17), 2027: (2, 6), 2028: (1, 26), 2029: (2, 13),
        2030: (2, 3), 2031: (1, 23), 2032: (2, 11), 2033: (1, 31), 2034: (2, 19),
        2035: (2, 8), 2036: (1, 28), 2037: (2, 15), 2038: (2, 4), 2039: (1, 24),
        2040: (2, 12), 2041: (2, 1), 2042: (1, 22), 2043: (2, 10), 2044: (1, 30),
        2045: (2, 17), 2046: (2, 6), 2047: (1, 26), 2048: (2, 14), 2049: (2, 2),
        2050: (1, 23), 2051: (2, 11), 2052: (2, 1), 2053: (2, 19), 2054: (2, 8),
        2055: (1, 28), 2056: (2, 15), 2057: (2, 4), 2058: (1, 24), 2059: (2, 12),
        2060: (2, 2),
    ]

    // MARK: - Zodiac Animal

    private static let zodiacAnimals = [
        "Rat", "Ox", "Tiger", "Rabbit", "Dragon", "Snake",
        "Horse", "Goat", "Monkey", "Rooster", "Dog", "Pig"
    ]

    /// Returns the Chinese zodiac animal for a given birth date,
    /// accounting for the Lunar New Year boundary.
    static func zodiacAnimal(from date: Date?) -> String {
        guard let date else { return "—" }

        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)

        // Determine the lunar year: if birth is before LNY, use previous year
        let lunarYear: Int
        if let lny = lunarNewYearDates[year] {
            let lnyDate = calendar.date(from: DateComponents(year: year, month: lny.month, day: lny.day))!
            lunarYear = date < lnyDate ? year - 1 : year
        } else {
            // Fallback for years outside lookup table
            lunarYear = year
        }

        let index = ((lunarYear - 1924) % 12 + 12) % 12
        return zodiacAnimals[index]
    }

    // MARK: - Lunar Birthday (Approximate)

    /// Returns an approximate lunar birthday using the Chinese calendar.
    /// Uses Foundation's Chinese calendar for conversion.
    static func lunarBirthday(from date: Date?) -> String {
        guard let date else { return "—" }

        let chineseCalendar = Calendar(identifier: .chinese)
        let lunarMonth = chineseCalendar.component(.month, from: date)
        let lunarDay = chineseCalendar.component(.day, from: date)

        let monthNames = [
            "1st Month", "2nd Month", "3rd Month", "4th Month",
            "5th Month", "6th Month", "7th Month", "8th Month",
            "9th Month", "10th Month", "11th Month", "12th Month"
        ]

        let monthName = lunarMonth <= 12 ? monthNames[lunarMonth - 1] : "\(lunarMonth)th Month"
        return "\(monthName), Day \(lunarDay)"
    }
}
