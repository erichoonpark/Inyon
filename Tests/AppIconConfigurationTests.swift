import XCTest
@testable import Inyon

final class AppIconConfigurationTests: XCTestCase {

    /// Verify the app bundle is configured with AppIcon as the primary icon.
    func testAppIconIsConfigured() {
        let bundle = Bundle.main
        let infoDictionary = bundle.infoDictionary
        XCTAssertNotNil(infoDictionary, "Info.plist should exist in the main bundle")

        guard let icons = infoDictionary?["CFBundleIcons"] as? [String: Any] else {
            XCTFail("CFBundleIcons is missing from Info.plist")
            return
        }

        guard let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any] else {
            XCTFail("CFBundlePrimaryIcon is missing from CFBundleIcons")
            return
        }

        guard let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String] else {
            XCTFail("CFBundleIconFiles is missing from CFBundlePrimaryIcon")
            return
        }

        XCTAssertTrue(
            iconFiles.contains(where: { $0.hasPrefix("AppIcon") }),
            "CFBundleIconFiles should contain an entry starting with 'AppIcon', got: \(iconFiles)"
        )
    }
}
