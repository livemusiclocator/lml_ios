import Foundation

/// The gig page's text, worked out here so it can be tested. Dates and times
/// are always shown in Melbourne time, like the website, wherever the phone is.
enum GigFormat {
    private static let locale = Locale(identifier: "en_AU")

    /// "TUE 3 NOV · 22:30", the line above the gig's name.
    static func kicker(for gig: Gig) -> String {
        kicker(date: gig.date, startTime: gig.startTime)
    }

    static func kicker(date: String, startTime: String?) -> String {
        let day = formatted(date, template: "EEEdMMM") ?? date
        return [day, startTime].compactMap { $0 }.joined(separator: " · ").uppercased()
    }

    /// "Tuesday 3 November 2026".
    static func fullDate(for gig: Gig) -> String {
        formatted(gig.date, template: "EEEEdMMMMyyyy") ?? gig.date
    }

    /// "10:30 am – 3:00 am", or just the start when the finish isn't known.
    ///
    /// From the API's "17:00" style times, which are the venue's own clock
    /// time. The timestamps would need converting to the venue's time zone:
    /// Brisbane has no daylight saving, so in summer it's an hour behind
    /// Melbourne.
    static func times(for gig: Gig) -> String {
        guard let start = gig.startTime.flatMap(clockTime) else { return "Start time not listed" }
        guard let finish = gig.finishTime.flatMap(clockTime) else { return start }
        return "\(start) – \(finish)"
    }

    /// "Brisbane time" when the venue's clock differs from the phone's on the
    /// gig's date, so nobody wonders whether the times were converted. Nothing
    /// when they agree: Melbourne and Brisbane only differ in daylight saving.
    static func timeZoneNote(for gig: Gig, phone: TimeZone = .current) -> String? {
        guard let state = AustralianState(venue: gig.venue) else { return nil }
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = state.timeZone
        let parser = DateFormatter()
        parser.calendar = calendar
        parser.timeZone = state.timeZone
        parser.locale = Locale(identifier: "en_AU_POSIX")
        parser.dateFormat = "yyyy-MM-dd HH:mm"
        guard let moment = parser.date(from: "\(gig.date) \(gig.startTime ?? "20:00")"),
              state.timeZone.secondsFromGMT(for: moment) != phone.secondsFromGMT(for: moment)
        else { return nil }
        return "\(state.city) time"
    }

    /// "5:00 pm" from "17:00".
    private static func clockTime(_ time: String) -> String? {
        let utc = TimeZone(identifier: "UTC")!
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_AU_POSIX")
        parser.timeZone = utc
        parser.dateFormat = "HH:mm"
        guard let parsed = parser.date(from: time) else { return nil }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = utc
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: parsed)
    }

    /// "74-76 Johnston Street Fitzroy · holds 175".
    static func venueDetails(for venue: Venue) -> String {
        [venue.address, venue.capacity.map { "holds \($0)" }]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    /// The website takes the first price as the cheapest, so this does too.
    static func ticketsLabel(for gig: Gig) -> String {
        gig.prices.first.map { "Tickets from \($0.amount)" } ?? "Tickets"
    }

    /// "2026-11-03" formatted with a date template, in Melbourne.
    private static func formatted(_ date: String, template: String) -> String? {
        let parser = DateFormatter()
        parser.timeZone = DateRange.melbourne
        parser.locale = Locale(identifier: "en_AU_POSIX")
        parser.dateFormat = "yyyy-MM-dd"
        guard let parsed = parser.date(from: date) else { return nil }
        let formatter = DateFormatter()
        formatter.timeZone = DateRange.melbourne
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter.string(from: parsed).replacingOccurrences(of: ",", with: "")
    }
}
