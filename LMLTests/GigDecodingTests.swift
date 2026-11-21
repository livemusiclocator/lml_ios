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

    @Test func decodesTheGigPageFields() throws {
        let gig = try #require(try Self.fixture().first { $0.name.hasPrefix("Michael Zammit") })
        #expect(gig.ticketingURL?.host() == "www.hopperssports.com.au")
        #expect(gig.startTimestamp != nil)
        #expect(gig.finishTimestamp == nil)
        #expect(gig.sets.first?.act?.name == "Michael Zammit")
        #expect(gig.sets.first?.startTime == "22:48")
        #expect(gig.prices.map(\.amount) == ["$30.00", "$20.00"])
        #expect(gig.prices.first?.description == "Non-members")
    }

    @Test func emptyTicketingURLIsNoURL() throws {
        let gig = try #require(try Self.fixture().first)
        #expect(gig.ticketingURL == nil)
        #expect(gig.finishTimestamp != nil)
        #expect(gig.venue.capacity == 175)
        #expect(gig.venue.locationURL != nil)
    }

    @Test func emptySeriesIsNoSeries() throws {
        #expect(try Self.fixture().first?.series == nil)
    }
}

private final class BundleToken {}
