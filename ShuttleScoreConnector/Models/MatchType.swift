import Foundation

enum MatchType: String, CaseIterable, Codable {
    case singles = "单打"
    case mensDoubles = "男双"
    case womensDoubles = "女双"
    case mixedDoubles = "混双"

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        if raw == "双打" {
            self = .mixedDoubles
        } else {
            self = MatchType(rawValue: raw) ?? .singles
        }
    }
}
