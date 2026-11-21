import Foundation
import Testing

@testable import LML

struct TagsTests {
    static func gig(genres: [String] = [], info: [String] = []) throws -> Gig {
        let json: [String: Any] = ["id": UUID().uuidString, "name": "Gig", "date": "2026-11-27",
                                   "genre_tags": genres, "information_tags": info,
                                   "venue": ["id": "v", "name": "Venue"]]
        return try JSONDecoder().decode(Gig.self, from: JSONSerialization.data(withJSONObject: json))
    }

    @Test(arguments: [("Rock", "rock"), ("ROCK ", "rock"), ("Hip-Hop", "hip hop"), (" hip  hop", "hip hop"), ("R&B", "r&b")])
    func keysIgnoreCaseDashesAndSpacing(tag: String, key: String) {
        #expect(Tags.key(tag) == key)
    }

    /// rock 114 + Rock 105 in the live data: one Rock.
    @Test func genresMergeAndTakeTheCommonestSpellingCapitalised() throws {
        let gigs = try [
            Self.gig(genres: ["rock", "indie"]),
            Self.gig(genres: ["rock"]),
            Self.gig(genres: ["Rock", "DJ"]),
            Self.gig(genres: ["dj"]),
        ]
        let genres = Tags.genres(in: gigs)
        #expect(genres.map(\.name) == ["Rock", "DJ", "Indie"])
        #expect(genres.map(\.count) == [3, 2, 1])
    }

    @Test func aGigCountsOnceEvenWithTheSameGenreTwice() throws {
        #expect(Tags.genres(in: [try Self.gig(genres: ["rock", "Rock"])]).first?.count == 1)
    }

    @Test(arguments: ["Free", "free", "Free entry", "FREE ENTRY", "free entry before 10pm"])
    func freeMatches(tag: String) throws {
        #expect(InfoFilter.free.matches(try Self.gig(info: [tag])))
    }

    @Test(arguments: ["Free Salsa Class", "dress up for free entry", "Ticketed"])
    func freeDoesNotMatch(tag: String) throws {
        #expect(!InfoFilter.free.matches(try Self.gig(info: [tag])))
    }

    @Test(arguments: ["18+", "18 Plus", "18+ Only", "This event is strictly 18+"])
    func eighteenPlusMatches(tag: String) throws {
        #expect(InfoFilter.eighteenPlus.matches(try Self.gig(info: [tag])))
    }

    @Test func allAges() throws {
        #expect(InfoFilter.allAges.matches(try Self.gig(info: ["All Ages"])))
        #expect(!InfoFilter.allAges.matches(try Self.gig(info: ["18+"])))
    }
}
