import Foundation

enum InsightTonePreference: String, Codable, CaseIterable, Identifiable {
    case calm  = "calm"   // softer, grounded, reflective
    case sharp = "sharp"  // more direct, piercing — still emotionally safe

    var id: String { rawValue }

    static let `default`: InsightTonePreference = .sharp

    var displayName: String { rawValue.capitalized }

    var helpText: String {
        switch self {
        case .calm:  return "Gentle, grounded, and reflective."
        case .sharp: return "Clearer, more direct, and more piercing."
        }
    }
}
