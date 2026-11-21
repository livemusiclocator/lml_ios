import Foundation
import Testing

@testable import LML

@MainActor
struct SavedGigsTests {
    let defaults = UserDefaults(suiteName: "SavedGigsTests-\(UUID().uuidString)")!
    /// Saturday 21 November 2026, 3pm in Melbourne.
    let saturday = ISO8601DateFormatter().date(from: "2026-11-21T15:00:00+11:00")!

    func gig(_ id: String, date: String, startTime: String = "20:00", venue: String = "v") throws -> Gig {
        let json: [String: Any] = ["id": id, "name": "Gig \(id)", "date": date, "start_time": startTime,
                                   "venue": ["id": venue, "name": "Venue"]]
        return try JSONDecoder().decode(Gig.self, from: JSONSerialization.data(withJSONObject: json))
    }

    @Test func togglingSavesAndUnsaves() throws {
        let saved = SavedGigs(defaults: defaults, now: saturday)
        let gig = try gig("a", date: "2026-11-27")
        saved.toggle(gig)
        #expect(saved.contains(gig))
        #expect(saved.venueIDs == ["v"])
        saved.toggle(gig)
        #expect(!saved.contains(gig))
    }

    @Test func keptBetweenLaunches() throws {
        SavedGigs(defaults: defaults, now: saturday).toggle(try gig("a", date: "2026-11-27"))
        #expect(SavedGigs(defaults: defaults, now: saturday).ids == ["a"])
    }

    @Test func forgottenOnceTheirNightIsOver() throws {
        let saved = SavedGigs(defaults: defaults, now: saturday)
        saved.toggle(try gig("past", date: "2026-11-20"))
        saved.toggle(try gig("tonight", date: "2026-11-21"))
        // a 1am Sunday set is still Saturday night
        saved.toggle(try gig("late", date: "2026-11-22", startTime: "01:00"))
        let sundayMorning = ISO8601DateFormatter().date(from: "2026-11-22T10:00:00+11:00")!
        #expect(SavedGigs(defaults: defaults, now: saturday).ids == ["tonight", "late"])
        #expect(SavedGigs(defaults: defaults, now: sundayMorning).ids.isEmpty)
    }

    @Test func followsAGigThatMoves() throws {
        let saved = SavedGigs(defaults: defaults, now: saturday)
        saved.toggle(try gig("a", date: "2026-11-27"))
        saved.update(from: try gig("a", date: "2026-11-28", venue: "w"))
        #expect(saved.entries.first?.night == "2026-11-28")
        #expect(saved.venueIDs == ["w"])
    }
}
