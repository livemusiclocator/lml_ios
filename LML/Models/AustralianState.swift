import Foundation

/// Which state or territory a venue is in, for its time zone. Gig times are
/// the venue's own clock; this says whose clock that is.
enum AustralianState: CaseIterable, Sendable {
    case nsw, act, vic, qld, sa, wa, tas, nt

    /// The city people name the time after: "Brisbane time".
    var city: String {
        switch self {
        case .nsw: "Sydney"
        case .act: "Canberra"
        case .vic: "Melbourne"
        case .qld: "Brisbane"
        case .sa: "Adelaide"
        case .wa: "Perth"
        case .tas: "Hobart"
        case .nt: "Darwin"
        }
    }

    var timeZone: TimeZone {
        let identifier = switch self {
        case .nsw, .act: "Australia/Sydney"
        case .vic: "Australia/Melbourne"
        case .qld: "Australia/Brisbane"
        case .sa: "Australia/Adelaide"
        case .wa: "Australia/Perth"
        case .tas: "Australia/Hobart"
        case .nt: "Australia/Darwin"
        }
        return TimeZone(identifier: identifier)!
    }

    /// The venue's state from its postcode, or failing that its address
    /// ("301 High Street, Northcote, Victoria").
    init?(venue: Venue) {
        if let state = venue.postcode.flatMap(Self.init(postcode:)) {
            self = state
        } else if let state = venue.address.flatMap(Self.init(address:)) {
            self = state
        } else {
            return nil
        }
    }

    /// Australia Post's ranges: 3xxx is Victoria, 4xxx Queensland, and so on.
    init?(postcode: String) {
        guard let code = Int(postcode.trimmingCharacters(in: .whitespaces)) else { return nil }
        switch code {
        case 200...299, 2600...2618, 2900...2920: self = .act
        case 800...999: self = .nt
        case 1000...2999: self = .nsw
        case 3000...3999, 8000...8999: self = .vic
        case 4000...4999, 9000...9999: self = .qld
        case 5000...5999: self = .sa
        case 6000...6999: self = .wa
        case 7000...7999: self = .tas
        default: return nil
        }
    }

    init?(address: String) {
        let words = Set(address.uppercased().split { !$0.isLetter }.map(String.init))
        let names: [(AustralianState, [String])] = [
            (.vic, ["VIC", "VICTORIA"]),
            (.qld, ["QLD", "QUEENSLAND"]),
            (.nsw, ["NSW"]),
            (.act, ["ACT"]),
            (.sa, ["SA"]),
            (.wa, ["WA"]),
            (.tas, ["TAS", "TASMANIA"]),
            (.nt, ["NT"]),
        ]
        guard let match = names.first(where: { !words.isDisjoint(with: $0.1) }) else { return nil }
        self = match.0
    }
}
