import Foundation

/// The gig page's text, worked out here so it can be tested. Dates and times
/// are always shown in Melbourne time, like the website, wherever the phone is.
enum GigFormat {
    private static let locale = Locale(identifier: "en_AU")

    /// "TUE 3 NOV · 22:30", the line above the gig's name.
    static func kicker(for gig: Gig) -> String {
        let day = formatted(gig.date, template: "EEEdMMM") ?? gig.date
        return [day, gig.startTime].compactMap { $0 }.joined(separator: " · ").uppercased()
    }

    /// "Tuesday 3 November 2026".
    static func fullDate(for gig: Gig) -> String {
        formatted(gig.date, template: "EEEEdMMMMyyyy") ?? gig.date
    }

    /// "10:30 am – 3:00 am", or just the start when the finish isn't known.
    static func times(for gig: Gig) -> String {
        guard let start = gig.startTimestamp else { return "Start time not listed" }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = DateRange.melbourne
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        // times only: an interval formatter adds both dates when a gig runs
        // past midnight, and the date is already on the line above
        guard let finish = gig.finishTimestamp, finish > start else { return formatter.string(from: start) }
        return "\(formatter.string(from: start)) – \(formatter.string(from: finish))"
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
