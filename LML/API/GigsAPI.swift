import Foundation

/// The read-only gigs API the website uses. No auth, no writes.
struct GigsAPI: Sendable {
    var baseURL = URL(string: "https://api.lml.live/gigs")!
    var session: URLSession = .shared

    /// Every gig on the range's nights, wherever it is. The website asks for one
    /// volunteer group's location at a time; the app lets the map do that job.
    /// "everywhere" has no location filter at all, unlike "anywhere", which
    /// leaves out places whose listings aren't complete yet (Brisbane, for now).
    func gigs(range: DateRange, now: Date = .now) async throws -> [Gig] {
        let nights = range.dates(now: now)
        // the API dates gigs by the day they start, so the last night's
        // after-midnight sets are dated the day after the range
        let dates = (from: nights.from, to: Night.nextDay(nights.to) ?? nights.to)
        var components = URLComponents(url: baseURL.appending(path: "query"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "location", value: "everywhere"),
            URLQueryItem(name: "date_from", value: dates.from),
            URLQueryItem(name: "date_to", value: dates.to),
        ]
        let (data, response) = try await session.data(from: components.url!)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        let gigs = try JSONDecoder().decode([Gig].self, from: data)
        // and the first day's after-midnight sets belong to the night before it
        return Night.gigs(gigs, from: nights.from, to: nights.to)
    }

    /// One gig, in full.
    func gig(id: String) async throws -> Gig {
        try await get(baseURL.appending(path: id))
    }

    /// One act, with their upcoming gigs. Remembered for the session, since a
    /// gig page looks up its lineup and the act page then shows the same act.
    func act(id: String) async throws -> Act {
        if let act = await ActCache.shared.act(id: id) { return act }
        let act: Act = try await get(actsURL.appending(path: id))
        await ActCache.shared.store(act)
        return act
    }

    var actsURL: URL { baseURL.deletingLastPathComponent().appending(path: "acts") }

    private func get<T: Decodable>(_ url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse {
            if http.statusCode == 404 { throw NotFound() }
            if !(200..<300).contains(http.statusCode) { throw URLError(.badServerResponse) }
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    struct NotFound: Error {}
}

private actor ActCache {
    static let shared = ActCache()
    private var acts: [Act.ID: Act] = [:]

    func act(id: Act.ID) -> Act? { acts[id] }
    func store(_ act: Act) { acts[act.id] = act }
}
