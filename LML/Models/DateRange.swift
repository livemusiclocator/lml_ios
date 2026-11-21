import Foundation

/// The explorer's date chips, matching `DATE_RANGES` in the web client's
/// `timeStuff.js`. Weeks run Monday to Sunday and "today" is tonight on the
/// phone's own clock: until 5am it's still last night (see `Night`). Someone in
/// Brisbane wants Brisbane's tonight, wherever the gigs are.
enum DateRange: String, CaseIterable, Identifiable, Sendable {
    case today, tomorrow, weekend, thisWeek, nextWeek

    var id: String { rawValue }

    var caption: String {
        switch self {
        case .today: "Today"
        case .tomorrow: "Tomorrow"
        case .weekend: "Weekend"
        case .thisWeek: "This Week"
        case .nextWeek: "Next Week"
        }
    }

    /// For arithmetic on "YYYY-MM-DD" dates, which are calendar days rather
    /// than moments: any fixed zone works, as long as reading and writing use
    /// the same one.
    static let melbourne = TimeZone(identifier: "Australia/Melbourne")!

    static var melbourneCalendar: Calendar { calendar(in: melbourne) }

    static func calendar(in timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = timeZone
        return calendar
    }

    /// The first and last night this range covers, as "YYYY-MM-DD", on the
    /// clock of `timeZone` (the phone's, normally).
    func dates(now: Date = .now, timeZone: TimeZone = .current) -> (from: String, to: String) {
        let calendar = Self.calendar(in: timeZone)
        let tonight = now.addingTimeInterval(-Double(Night.endsAtHour) * 3600)
        let today = calendar.startOfDay(for: tonight)
        let day = { (offset: Int, from: Date) in calendar.date(byAdding: .day, value: offset, to: from)! }
        // iso8601 calendar: weekday 2 is Monday ... 1 is Sunday
        let weekday = calendar.component(.weekday, from: today)
        let daysSinceMonday = (weekday + 5) % 7
        let monday = day(-daysSinceMonday, today)

        let (from, to): (Date, Date) =
            switch self {
            case .today: (today, today)
            case .tomorrow: (day(1, today), day(1, today))
            case .weekend: (day(4, monday), day(6, monday))
            case .thisWeek: (today, day(6, monday))
            case .nextWeek: (day(7, monday), day(13, monday))
            }
        return (Self.format(from, timeZone: timeZone), Self.format(to, timeZone: timeZone))
    }

    static func format(_ date: Date, timeZone: TimeZone = melbourne) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar(in: timeZone)
        formatter.timeZone = timeZone
        formatter.locale = Locale(identifier: "en_AU_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
