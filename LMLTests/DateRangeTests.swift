import Foundation
import Testing

@testable import LML

struct DateRangeTests {
    static let melbourne = DateRange.melbourne
    static let brisbane = TimeZone(identifier: "Australia/Brisbane")!
    static let perth = TimeZone(identifier: "Australia/Perth")!

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
        let dates = range.dates(now: Self.tuesdayNight, timeZone: Self.melbourne)
        #expect(dates.from == from)
        #expect(dates.to == to)
    }

    @Test func todayIsMelbournesDay() {
        #expect(DateRange.today.dates(now: Self.wednesdayMorning, timeZone: Self.melbourne).from == "2026-11-04")
    }

    @Test func afterMidnightTodayIsStillLastNight() {
        #expect(DateRange.today.dates(now: Self.justAfterMidnight, timeZone: Self.melbourne).from == "2026-11-03")
    }

    @Test func thisWeekOnSundayIsJustSunday() {
        let sunday = ISO8601DateFormatter().date(from: "2026-11-08T10:00:00+11:00")!
        let dates = DateRange.thisWeek.dates(now: sunday, timeZone: Self.melbourne)
        #expect(dates.from == "2026-11-08")
        #expect(dates.to == "2026-11-08")
    }

    /// 4:15am Saturday in Brisbane is 5:15am in Melbourne (daylight saving),
    /// but Friday night is still going in the Valley.
    @Test func tonightIsOnThePhonesClock() {
        let valley = ISO8601DateFormatter().date(from: "2026-11-21T04:15:00+10:00")!
        #expect(DateRange.today.dates(now: valley, timeZone: Self.brisbane).from == "2026-11-20")
        #expect(DateRange.today.dates(now: valley, timeZone: Self.melbourne).from == "2026-11-21")
    }

    /// 2am in Perth is 5am in Melbourne: Perth's night isn't over.
    @Test func perthsNightRunsToFiveAmPerthTime() {
        let perth = ISO8601DateFormatter().date(from: "2026-11-21T02:00:00+08:00")!
        #expect(DateRange.today.dates(now: perth, timeZone: Self.perth).from == "2026-11-20")
    }

    /// The week turns over at 5am Monday on the phone's clock, too.
    @Test func thisWeekTurnsOverAtFiveAmMonday() {
        let earlyMonday = ISO8601DateFormatter().date(from: "2026-11-23T04:15:00+10:00")!
        let dates = DateRange.thisWeek.dates(now: earlyMonday, timeZone: Self.brisbane)
        #expect(dates.from == "2026-11-22")
        #expect(dates.to == "2026-11-22")
    }
}
