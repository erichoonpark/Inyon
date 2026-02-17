import XCTest
@testable import Inyon

@MainActor
final class HomeViewModelTests: XCTestCase {

    private func makeSampleInsight(
        localDate: String = "2026-02-16",
        dayElement: String = "Wood"
    ) -> DailyInsight {
        DailyInsight(
            localDate: localDate,
            timeZoneId: "America/Los_Angeles",
            dayElement: dayElement,
            elementTheme: "Growth, flexibility, vision",
            heavenlyStem: "Gab",
            earthlyBranch: "Ja",
            insightText: "Today carries a quiet tone. Conditions may favor reflection.",
            generatedAt: Date(),
            version: "v1"
        )
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
}
