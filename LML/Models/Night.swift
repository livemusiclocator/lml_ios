import Foundation

/// Gigs belong to nights, not calendar days. A set that starts at 00:30 on
/// Saturday is part of Friday night: it's listed at the end of Friday, after
/// the 11pm set, not at the top of Saturday above the afternoon shows.
///
/// The API dates a gig by the day it starts, so the app works the night out
/// from the start time. A night runs until 5am.
enum Night {
    /// Gigs that start before this belong to the night before.
    static let endsAt = "05:00"
    static let endsAtHour = 5

    /// The night a gig belongs to, as "YYYY-MM-DD".
    static func of(date: String, startTime: String?) -> String {
        guard let startTime, startTime < endsAt else { return date }
        return previousDay(date) ?? date
    }

    /// Orders a night's gigs as the night runs: the evening, then after
    /// midnight, then gigs with no start time last.
    static func sortKey(startTime: String?) -> String {
        guard let startTime else { return "2" }
        return (startTime < endsAt ? "1" : "0") + startTime
    }

    /// Only the gigs whose night falls in `from...to` (both "YYYY-MM-DD").
    static func gigs(_ gigs: [Gig], from: String, to: String) -> [Gig] {
        gigs.filter { (from...to).contains($0.night) }
    }

    static func previousDay(_ date: String) -> String? {
        adding(-1, to: date)
    }

    static func nextDay(_ date: String) -> String? {
        adding(1, to: date)
    }

    private static func adding(_ days: Int, to date: String) -> String? {
        let parser = DateFormatter()
        parser.calendar = DateRange.melbourneCalendar
        parser.timeZone = DateRange.melbourne
        parser.locale = Locale(identifier: "en_AU_POSIX")
        parser.dateFormat = "yyyy-MM-dd"
        guard let parsed = parser.date(from: date),
              let moved = DateRange.melbourneCalendar.date(byAdding: .day, value: days, to: parsed)
        else { return nil }
        return DateRange.format(moved)
    }
}

extension Gig {
    /// The night this gig is part of; see `Night`.
    var night: String { Night.of(date: date, startTime: startTime) }
}
