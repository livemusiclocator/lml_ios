import Foundation

/// The read-only gigs API the website uses. No auth, no writes.
struct GigsAPI: Sendable {
    var baseURL = URL(string: "https://api.lml.live/gigs")!
    var session: URLSession = .shared

    func gigs(location: Location, range: DateRange, now: Date = .now) async throws -> [Gig] {
        let dates = range.dates(now: now)
        var components = URLComponents(url: baseURL.appending(path: "query"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "location", value: location.id),
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
