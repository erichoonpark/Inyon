import XCTest
@testable import Inyon

// MARK: - Tab Enum Tests
//
// Tests the Tab enum used for bottom navigation.

final class TabEnumTests: XCTestCase {

    // MARK: - Cases

    func test_allCases_returnsThreeTabs() {
        let tabs = Tab.allCases
        XCTAssertEqual(tabs.count, 3)
    }

    func test_allCases_correctOrder() {
        let tabs = Tab.allCases
        XCTAssertEqual(tabs[0], .home)
        XCTAssertEqual(tabs[1], .guide)
        XCTAssertEqual(tabs[2], .you)
    }

    // MARK: - Raw Values

    func test_rawValues_areUppercase() {
        XCTAssertEqual(Tab.home.rawValue, "HOME")
        XCTAssertEqual(Tab.guide.rawValue, "GUIDE")
        XCTAssertEqual(Tab.you.rawValue, "YOU")
    }

    // MARK: - Identifiable

    func test_id_matchesRawValue() {
        for tab in Tab.allCases {
            XCTAssertEqual(tab.id, tab.rawValue)
        }
    }

    func test_ids_areUnique() {
        let ids = Tab.allCases.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "All tab IDs should be unique")
    }

    // MARK: - Initialization from Raw Value

    func test_initFromRawValue_valid() {
        XCTAssertEqual(Tab(rawValue: "HOME"), .home)
        XCTAssertEqual(Tab(rawValue: "GUIDE"), .guide)
        XCTAssertEqual(Tab(rawValue: "YOU"), .you)
    }

    func test_initFromRawValue_invalid_returnsNil() {
        XCTAssertNil(Tab(rawValue: "home"))
        XCTAssertNil(Tab(rawValue: "SETTINGS"))
        XCTAssertNil(Tab(rawValue: ""))
    }
}
