import Foundation

/// The read-only gigs API the website uses. No auth, no writes.
struct GigsAPI: Sendable {
    var baseURL = URL(string: "https://api.lml.live/gigs")!
    var session: URLSession = .shared

    /// Every location's gigs in the range. The website asks for one volunteer
    /// group's location at a time; the app lets the map do that job.
    func gigs(range: DateRange, now: Date = .now) async throws -> [Gig] {
        let dates = range.dates(now: now)
        var components = URLComponents(url: baseURL.appending(path: "query"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "location", value: "anywhere"),
            URLQueryItem(name: "date_from", value: dates.from),
            URLQueryItem(name: "date_to", value: dates.to),
        ]
        let (data, response) = try await session.data(from: components.url!)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode([Gig].self, from: data)
    }
}
