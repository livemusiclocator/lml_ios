import Foundation

/// The explorer's date chips, matching `DATE_RANGES` in the web client's
/// `timeStuff.js`. Weeks run Monday to Sunday and "today" is always today in
/// Melbourne, wherever the phone is.
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

    static let melbourne = TimeZone(identifier: "Australia/Melbourne")!

    static var melbourneCalendar: Calendar {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = melbourne
        return calendar
    }

    /// The first and last day this range covers, as "YYYY-MM-DD".
    func dates(now: Date = .now) -> (from: String, to: String) {
        let calendar = Self.melbourneCalendar
        let today = calendar.startOfDay(for: now)
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
        return (Self.format(from), Self.format(to))
    }

    static func format(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = melbourneCalendar
        formatter.timeZone = melbourne
        formatter.locale = Locale(identifier: "en_AU_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
