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

    @Test func venueDetailsIncludeCapacity() throws {
        let venue = try Self.gig(named: "DJ JULIUS MYLES").venue
        #expect(GigFormat.venueDetails(for: venue) == "74-76 Johnston Street Fitzroy · holds 175")
    }

    @Test func ticketsAreFromTheFirstPrice() throws {
        #expect(GigFormat.ticketsLabel(for: try Self.gig(named: "Michael Zammit - Greatest Hits of the 70s Show")) == "Tickets from $30.00")
        #expect(GigFormat.ticketsLabel(for: try Self.gig(named: "DJ JULIUS MYLES")) == "Tickets")
    }
}
