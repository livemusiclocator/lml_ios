import Foundation

/// Genre and info tags as the filters see them. Tags are typed in by hand, so
/// the same genre arrives as "Rock", "rock" and "ROCK", or "hip-hop" and "hip
/// hop": they're merged by a key that ignores case, dashes and spacing.
enum Tags {
    /// "hip hop" for "Hip-Hop", " hip  hop ", "HIP_HOP".
    static func key(_ tag: String) -> String {
        tag.lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    /// The genres on these gigs, most gigs first, each under its most used
    /// spelling with a capital letter ("Rock", "DJ", "Hip hop").
    static func genres(in gigs: [Gig]) -> [GenreOption] {
        var gigCounts: [String: Int] = [:]
        var spellings: [String: [String: Int]] = [:]
        for gig in gigs {
            for key in Set(gig.genreTags.map(key)) where !key.isEmpty {
                gigCounts[key, default: 0] += 1
            }
            for tag in gig.genreTags {
                spellings[key(tag), default: [:]][tag.trimmingCharacters(in: .whitespaces), default: 0] += 1
            }
        }
        return gigCounts.map { key, count in
            let spelling = spellings[key]?.max { ($0.value, $1.key) < ($1.value, $0.key) }?.key ?? key
            return GenreOption(id: key, name: spelling.prefix(1).uppercased() + spelling.dropFirst(), count: count)
        }
        .sorted { ($0.count, $1.name) > ($1.count, $0.name) }
    }
}

struct GenreOption: Identifiable, Hashable, Sendable {
    /// The merged key, which is what the filter remembers.
    let id: String
    let name: String
    /// How many gigs have it.
    let count: Int
}

/// The info tags worth a simple on/off filter. Each matches the spellings the
/// listings actually use.
enum InfoFilter: String, CaseIterable, Identifiable, Sendable {
    case free, eighteenPlus, allAges

    var id: String { rawValue }

    var caption: String {
        switch self {
        case .free: "Free"
        case .eighteenPlus: "18+"
        case .allAges: "All ages"
        }
    }

    func matches(_ gig: Gig) -> Bool {
        gig.informationTags.map(Tags.key).contains { tag in
            switch self {
            // "Free", "Free entry", "free entry before 10pm"
            case .free: tag == "free" || tag.hasPrefix("free entry")
            // "18+", "18+ Only", "18 Plus", "This event is strictly 18+"
            case .eighteenPlus: tag.contains("18+") || tag.contains("18 plus")
            case .allAges: tag == "all ages" || tag == "allages"
            }
        }
    }
}
