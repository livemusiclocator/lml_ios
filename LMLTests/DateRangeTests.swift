import Foundation
import Testing

@testable import LML

struct DateRangeTests {
    /// Tuesday 3 November 2026, 11pm in Melbourne.
    static let tuesdayNight = ISO8601DateFormatter().date(from: "2026-11-03T23:00:00+11:00")!

    /// 9am Wednesday in Melbourne is still Tuesday in UTC - the app must use
    /// Melbourne's day, like the website does.
    static let wednesdayMorning = ISO8601DateFormatter().date(from: "2026-11-04T09:00:00+11:00")!

    /// 12:30am Wednesday in Melbourne: Tuesday night is still going.
    static let justAfterMidnight = ISO8601DateFormatter().date(from: "2026-11-04T00:30:00+11:00")!

    @Test(arguments: [
        (DateRange.today, "2026-11-03", "2026-11-03"),
        (.tomorrow, "2026-11-04", "2026-11-04"),
        (.weekend, "2026-11-06", "2026-11-08"),
        (.thisWeek, "2026-11-03", "2026-11-08"),
        (.nextWeek, "2026-11-09", "2026-11-15"),
    ])
    func dates(range: DateRange, from: String, to: String) {
        let dates = range.dates(now: Self.tuesdayNight)
        #expect(dates.from == from)
        #expect(dates.to == to)
    }

    @Test func todayIsMelbournesDay() {
        #expect(DateRange.today.dates(now: Self.wednesdayMorning).from == "2026-11-04")
    }

    @Test func afterMidnightTodayIsStillLastNight() {
        #expect(DateRange.today.dates(now: Self.justAfterMidnight).from == "2026-11-03")
    }

    @Test func thisWeekOnSundayIsJustSunday() {
        let sunday = ISO8601DateFormatter().date(from: "2026-11-08T10:00:00+11:00")!
        let dates = DateRange.thisWeek.dates(now: sunday)
        #expect(dates.from == "2026-11-08")
        #expect(dates.to == "2026-11-08")
    }
}
