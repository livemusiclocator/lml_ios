import Foundation
import Testing

@testable import LML

struct TimeZoneNoteTests {
    static let melbourne = TimeZone(identifier: "Australia/Melbourne")!
    static let brisbane = TimeZone(identifier: "Australia/Brisbane")!

    static func gig(date: String, postcode: String?, address: String? = nil) throws -> Gig {
        var venue: [String: Any] = ["id": "v", "name": "Venue"]
        venue["postcode"] = postcode ?? NSNull()
        venue["address"] = address ?? NSNull()
        let json: [String: Any] = ["id": "g", "name": "Gig", "date": date, "start_time": "21:00", "venue": venue]
        return try JSONDecoder().decode(Gig.self, from: JSONSerialization.data(withJSONObject: json))
    }

    @Test func brisbaneGigFromMelbourneInSummer() throws {
        let gig = try Self.gig(date: "2026-11-27", postcode: "4006")
        #expect(GigFormat.timeZoneNote(for: gig, phone: Self.melbourne) == "Brisbane time")
    }

    @Test func noNoteAtHome() throws {
        let gig = try Self.gig(date: "2026-11-27", postcode: "4006")
        #expect(GigFormat.timeZoneNote(for: gig, phone: Self.brisbane) == nil)
    }

    @Test func melbourneGigFromBrisbaneInSummer() throws {
        let gig = try Self.gig(date: "2026-11-27", postcode: "3065")
        #expect(GigFormat.timeZoneNote(for: gig, phone: Self.brisbane) == "Melbourne time")
    }

    /// No daylight saving in July: Melbourne and Brisbane read the same.
    @Test func noNoteInWinter() throws {
        let gig = try Self.gig(date: "2026-07-10", postcode: "3065")
        #expect(GigFormat.timeZoneNote(for: gig, phone: Self.brisbane) == nil)
    }

    /// Northcote Social Club has no postcode, but its address says Victoria.
    @Test func stateFromTheAddressWithoutAPostcode() throws {
        let gig = try Self.gig(date: "2026-11-27", postcode: nil, address: "301 High Street, Northcote, Victoria")
        #expect(GigFormat.timeZoneNote(for: gig, phone: Self.brisbane) == "Melbourne time")
    }

    @Test func noNoteWhenTheStateIsUnknown() throws {
        let gig = try Self.gig(date: "2026-11-27", postcode: nil, address: "Somewhere")
        #expect(GigFormat.timeZoneNote(for: gig, phone: Self.brisbane) == nil)
    }

    @Test(arguments: [("3065", AustralianState.vic), ("4006", .qld), ("2000", .nsw), ("2600", .act), ("0800", .nt), ("6000", .wa)])
    func postcodes(postcode: String, state: AustralianState) {
        #expect(AustralianState(postcode: postcode) == state)
    }
}
