import XCTest
@testable import Inyon

@MainActor
final class HomeViewModelTests: XCTestCase {

    private let cacheKey = "inyon.cachedInsight.v1.calm"

    private let toneKey = "inyon.tonePreference.v1"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.set("calm", forKey: toneKey)
    }

    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: toneKey)
    }

    private func makeSampleInsight(
        localDate: String = "2026-02-16",
        timeZoneId: String = "America/Los_Angeles",
        dayElement: String = "Wood"
    ) -> DailyInsight {
        DailyInsight(
            localDate: localDate,
            timeZoneId: timeZoneId,
            dayElement: dayElement,
            elementTheme: "Growth, flexibility, vision",
            heavenlyStem: "Gab",
            earthlyBranch: "Ja",
            insightText: "Today carries a quiet tone. Conditions may favor reflection.",
            dynamicText: nil,
            generatedAt: Date(),
            version: "v1"
        )
    }

    private func makeTodayInsight(dayElement: String = "Wood") -> DailyInsight {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return makeSampleInsight(
            localDate: formatter.string(from: Date()),
            timeZoneId: TimeZone.current.identifier,
            dayElement: dayElement
        )
    }

    private func seedCache(_ insight: DailyInsight) {
        if let data = try? JSONEncoder().encode(insight) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }

    // MARK: - Load Success

    func testLoadSuccess() async {
        let mock = MockDailyInsightService()
        let insight = makeSampleInsight()
        mock.fetchResult = .success(insight)

        let vm = HomeViewModel(service: mock)
        XCTAssertEqual(vm.state, .idle)

        vm.loadTodayInsight()

        // Wait for async work
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(vm.state, .ready)
        XCTAssertNotNil(vm.currentInsight)
        XCTAssertEqual(vm.currentInsight?.dayElement, "Wood")
        XCTAssertNotNil(vm.lastKnownInsight)
    }

    // MARK: - Load Failure

    func testLoadFailureSetsErrorState() async {
        let mock = MockDailyInsightService()
        mock.fetchResult = .failure(DailyInsightError.invalidResponse)

        let vm = HomeViewModel(service: mock)
        vm.loadTodayInsight()

        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(vm.state, .error)
        XCTAssertNil(vm.currentInsight)
    }

    // MARK: - Fallback on Error

    func testErrorKeepsLastKnownInsight() async {
        let mock = MockDailyInsightService()
        let insight = makeSampleInsight()
        mock.fetchResult = .success(insight)

        let vm = HomeViewModel(service: mock)
        vm.loadTodayInsight()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(vm.state, .ready)
        XCTAssertNotNil(vm.lastKnownInsight)

        // Now simulate failure
        mock.fetchResult = .failure(DailyInsightError.invalidResponse)
        vm.retry()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(vm.state, .error)
        XCTAssertNotNil(vm.lastKnownInsight)
        XCTAssertEqual(vm.lastKnownInsight?.dayElement, "Wood")
    }

    // MARK: - Timezone and Date Parameters

    func testPassesCorrectTimezoneAndDate() async {
        let mock = MockDailyInsightService()
        mock.fetchResult = .success(makeSampleInsight())

        let vm = HomeViewModel(service: mock)
        vm.loadTodayInsight()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(mock.fetchCalls.count, 1)
        let call = mock.fetchCalls[0]
        XCTAssertEqual(call.timeZoneId, TimeZone.current.identifier)
        // Date should be in YYYY-MM-DD format
        XCTAssertTrue(call.localDate.contains("-"))
        XCTAssertEqual(call.localDate.count, 10)
    }

    // MARK: - Retry

    func testRetryCallsServiceAgain() async {
        let mock = MockDailyInsightService()
        mock.fetchResult = .failure(DailyInsightError.invalidResponse)

        let vm = HomeViewModel(service: mock)
        vm.loadTodayInsight()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(mock.fetchCalls.count, 1)

        mock.fetchResult = .success(makeSampleInsight())
        vm.retry()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(mock.fetchCalls.count, 2)
        XCTAssertEqual(vm.state, .ready)
    }

    // MARK: - Deduplication

    func testDoesNotDoubleLoad() async {
        let mock = MockDailyInsightService()
        mock.fetchResult = .success(makeSampleInsight())

        let vm = HomeViewModel(service: mock)
        vm.loadTodayInsight()
        vm.loadTodayInsight() // Second call while loading

        try? await Task.sleep(nanoseconds: 100_000_000)

        // Should only have called service once
        XCTAssertEqual(mock.fetchCalls.count, 1)
    }

    // MARK: - Local Cache: Init

    func testInit_withValidCache_startsReady() {
        seedCache(makeTodayInsight(dayElement: "Fire"))

        let vm = HomeViewModel(service: MockDailyInsightService())

        XCTAssertEqual(vm.state, .ready)
        XCTAssertNotNil(vm.currentInsight)
        XCTAssertEqual(vm.currentInsight?.dayElement, "Fire")
        XCTAssertNotNil(vm.lastKnownInsight)
    }

    func testInit_withStaleDate_startsIdle() {
        seedCache(makeSampleInsight(localDate: "2020-01-01", timeZoneId: TimeZone.current.identifier))

        let vm = HomeViewModel(service: MockDailyInsightService())

        XCTAssertEqual(vm.state, .idle, "Stale date should not populate state from cache")
        XCTAssertNil(vm.currentInsight)
    }

    func testInit_withWrongTimezone_startsIdle() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        let today = formatter.string(from: Date())

        seedCache(makeSampleInsight(localDate: today, timeZoneId: "UTC"))

        let vm = HomeViewModel(service: MockDailyInsightService())

        // Only invalid if current timezone is not UTC
        if TimeZone.current.identifier != "UTC" {
            XCTAssertEqual(vm.state, .idle, "Wrong timezone should not populate state from cache")
        }
    }

    func testInit_withNoCache_startsIdle() {
        let vm = HomeViewModel(service: MockDailyInsightService())
        XCTAssertEqual(vm.state, .idle)
        XCTAssertNil(vm.currentInsight)
    }

    // MARK: - Local Cache: Silent Refresh

    func testLoadWithCache_doesNotFlashLoading() async {
        seedCache(makeTodayInsight())
        let mock = MockDailyInsightService()
        mock.fetchResult = .success(makeTodayInsight(dayElement: "Metal"))

        let vm = HomeViewModel(service: mock)
        XCTAssertEqual(vm.state, .ready)

        vm.loadTodayInsight()

        // State should remain .ready — never flashes .loading
        XCTAssertEqual(vm.state, .ready, "Should not flash .loading when cache is present")

        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(vm.state, .ready)
        XCTAssertEqual(vm.currentInsight?.dayElement, "Metal", "Should update to fresh data")
    }

    func testLoadWithCache_silentlySwallowsError() async {
        seedCache(makeTodayInsight(dayElement: "Water"))
        let mock = MockDailyInsightService()
        mock.fetchResult = .failure(DailyInsightError.invalidResponse)

        let vm = HomeViewModel(service: mock)
        XCTAssertEqual(vm.state, .ready)

        vm.loadTodayInsight()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Error is swallowed — cached content stays visible
        XCTAssertEqual(vm.state, .ready, "Network error should not evict cached content")
        XCTAssertNotNil(vm.currentInsight)
    }

    // MARK: - Local Cache: Persistence

    func testSuccessfulLoad_writesToCache() async {
        let mock = MockDailyInsightService()
        mock.fetchResult = .success(makeTodayInsight(dayElement: "Earth"))

        let vm = HomeViewModel(service: mock)
        vm.loadTodayInsight()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // A new VM should pick up the cached value
        let vm2 = HomeViewModel(service: MockDailyInsightService())
        XCTAssertEqual(vm2.state, .ready)
        XCTAssertEqual(vm2.currentInsight?.dayElement, "Earth")
    }

    func testClearCache_removesStoredInsight() async {
        seedCache(makeTodayInsight())

        let vm = HomeViewModel(service: MockDailyInsightService())
        XCTAssertEqual(vm.state, .ready)

        vm.clearCache()

        let vm2 = HomeViewModel(service: MockDailyInsightService())
        XCTAssertEqual(vm2.state, .idle, "Cache should be empty after clearCache()")
    }
}
