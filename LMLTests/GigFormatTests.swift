import Foundation
import Testing

@testable import LML

struct GigFormatTests {
    static func gig(named name: String) throws -> Gig {
        try #require(try GigDecodingTests.fixture().first { $0.name == name })
    }

    @Test func kickerIsTheMelbourneDayAndStartTime() throws {
        #expect(GigFormat.kicker(for: try Self.gig(named: "DJ JULIUS MYLES")) == "TUE 3 NOV · 10:30")
    }

    @Test func fullDate() throws {
        #expect(GigFormat.fullDate(for: try Self.gig(named: "DJ JULIUS MYLES")) == "Tuesday 3 November 2026")
    }

    @Test func timesRunFromStartToFinishAcrossMidnight() throws {
        let times = GigFormat.times(for: try Self.gig(named: "DJ JULIUS MYLES"))
        #expect(times.hasPrefix("10:30"))
        #expect(times.contains("3:00"))
    }

    @Test func timesWithoutAFinishAreJustTheStart() throws {
        let times = GigFormat.times(for: try Self.gig(named: "Cup Day Blowout"))
        #expect(times.hasPrefix("1:00"))
        #expect(!times.contains("–"))
    }

    /// Brisbane has no daylight saving, so in November its gigs are an hour
    /// behind Melbourne's: times are the venue's own clock, not Melbourne's.
    @Test func timesAreTheVenuesClock() throws {
        let json: [String: Any] = [
            "id": "b", "name": "Friday Night Entertainment", "date": "2026-11-27",
            "start_time": "17:00", "start_timestamp": "2026-11-27T17:00:00.000+10:00",
            "finish_time": "03:00", "finish_timestamp": "2026-11-28T03:00:00.000+10:00",
            "venue": ["id": "v", "name": "Chattahoochee Joes Honky Tonk"],
        ]
        let gig = try JSONDecoder().decode(Gig.self, from: JSONSerialization.data(withJSONObject: json))
        let times = GigFormat.times(for: gig)
        #expect(times.hasPrefix("5:00"))
        #expect(times.contains("3:00"))
    }

    @Test func venueDetailsIncludeCapacity() throws {
        let venue = try Self.gig(named: "DJ JULIUS MYLES").venue
        #expect(GigFormat.venueDetails(for: venue) == "74-76 Johnston Street Fitzroy · holds 175")
    }

    @Test func ticketsAreFromTheFirstPrice() throws {
        #expect(GigFormat.ticketsLabel(for: try Self.gig(named: "Michael Zammit - Greatest Hits of the 70s Show")) == "Tickets from $30.00")
        #expect(GigFormat.ticketsLabel(for: try Self.gig(named: "DJ JULIUS MYLES")) == "Tickets")
    }
}
