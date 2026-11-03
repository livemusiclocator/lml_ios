import Foundation
import Testing

@testable import LML

struct GigDecodingTests {
    static func fixture() throws -> [Gig] {
        let url = try #require(Bundle(for: BundleToken.self).url(forResource: "gigs", withExtension: "json"))
        return try JSONDecoder().decode([Gig].self, from: Data(contentsOf: url))
    }

    @Test func decodesARealResponse() throws {
        let gig = try #require(try Self.fixture().first)
        #expect(gig.name == "DJ JULIUS MYLES")
        #expect(gig.startTime == "10:30")
        #expect(gig.genreTags == ["DJ"])
        #expect(gig.venue.name == "The Old Bar")
        #expect(gig.venue.coordinate != nil)
    }

    @Test func emptySeriesIsNoSeries() throws {
        #expect(try Self.fixture().first?.series == nil)
    }
}

private final class BundleToken {}
