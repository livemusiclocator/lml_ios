import Foundation
import Testing

@testable import LML

struct NightTests {
    /// A gig with just the fields `Night` cares about.
    static func gig(_ date: String, _ startTime: String?) throws -> Gig {
        let json: [String: Any] = [
            "id": UUID().uuidString, "name": "Gig at \(startTime ?? "?")", "date": date,
            "start_time": startTime ?? NSNull(),
            "venue": ["id": "v", "name": "The Old Bar"],
        ]
        return try JSONDecoder().decode(Gig.self, from: JSONSerialization.data(withJSONObject: json))
    }

    @Test(arguments: [
        ("2026-11-21", "00:30", "2026-11-20"),
        ("2026-11-21", "04:59", "2026-11-20"),
        ("2026-11-21", "05:00", "2026-11-21"),
        ("2026-11-21", "23:00", "2026-11-21"),
        ("2026-12-01", "01:00", "2026-11-30"),
    ])
    func afterMidnightIsTheNightBefore(date: String, startTime: String, night: String) {
        #expect(Night.of(date: date, startTime: startTime) == night)
    }

    @Test func noStartTimeIsThatDay() {
        #expect(Night.of(date: "2026-11-21", startTime: nil) == "2026-11-21")
    }

    @Test func aNightRunsEveningThenAfterMidnightThenUntimed() {
        let times: [String?] = [nil, "00:30", "23:00", "11:00", "03:00", "20:00"]
        let sorted = times.sorted { Night.sortKey(startTime: $0) < Night.sortKey(startTime: $1) }
        #expect(sorted == ["11:00", "20:00", "23:00", "00:30", "03:00", nil])
    }

    @Test func rangeKeepsGigsOnItsNights() throws {
        let gigs = [
            try Self.gig("2026-11-16", "00:30"), // Sunday night before the week
            try Self.gig("2026-11-16", "20:00"), // Monday
            try Self.gig("2026-11-22", "22:00"), // Sunday
            try Self.gig("2026-11-23", "01:00"), // still Sunday night
            try Self.gig("2026-11-23", "20:00"), // next Monday
        ]
        let kept = Night.gigs(gigs, from: "2026-11-16", to: "2026-11-22").map(\.name)
        #expect(kept == ["Gig at 20:00", "Gig at 22:00", "Gig at 01:00"])
    }
}

struct LineupTests {
    static func set(_ name: String, _ startTime: String?) throws -> GigSet {
        let json: [String: Any] = ["start_time": startTime ?? NSNull(), "act": ["name": name]]
        return try JSONDecoder().decode(GigSet.self, from: JSONSerialization.data(withJSONObject: json))
    }

    /// Chattahoochee Joes, Friday 27 November, as the API lists it.
    @Test func afterMidnightSetsCloseTheNight() throws {
        let sets = try [
            Self.set("Benny", "01:00"),
            Self.set("Gilly's Line Dancing", "17:00"),
            Self.set("Tané-Rua", "18:30"),
            Self.set("Tate Cole", "22:00"),
        ]
        #expect(Night.lineup(sets).map { $0.act?.name } == ["Gilly's Line Dancing", "Tané-Rua", "Tate Cole", "Benny"])
    }

    @Test func untimedSetsStayFirstInTheirOrder() throws {
        let sets = try [
            Self.set("Felix Meredith", nil),
            Self.set("Jesse Chin-Quan", nil),
            Self.set("Amin Payne", "19:00"),
            Self.set("Shantael Raphael", "15:00"),
        ]
        #expect(Night.lineup(sets).map { $0.act?.name } == ["Felix Meredith", "Jesse Chin-Quan", "Shantael Raphael", "Amin Payne"])
    }
}
