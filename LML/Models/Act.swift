import Foundation

/// An act as `api.lml.live/acts/<id>` returns it: who they are, where they're
/// from, where to find them online, and the gigs they have coming up.
struct Act: Decodable, Identifiable, Sendable {
    let id: String
    let name: String
    let country: String?
    /// An LML location id ("melbourne"), when they're local to one.
    let location: String?
    let genres: [String]
    let links: [Link]
    let upcomingGigs: [UpcomingGig]

    /// Whether there's more to say than the name the lineup already shows: an
    /// act that's only a name isn't worth a page.
    var isWorthAPage: Bool {
        !links.isEmpty || !genres.isEmpty || origin != nil
    }

    /// "Melbourne, Australia", "USA", or nothing.
    var origin: String? {
        // LML location ids are lower case ("melbourne"); anything else is as typed
        let place = location.map { $0 == $0.lowercased() ? $0.capitalized : $0 }
        let parts = [place, country].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    struct Link: Hashable, Sendable {
        let label: String
        let url: URL
    }

    /// One of the act's gigs, slimmer than a `Gig`: enough to list it.
    struct UpcomingGig: Decodable, Identifiable, Hashable, Sendable {
        let id: String
        let name: String
        let date: String
        let startTime: String?
        let status: String?
        let venue: Venue

        var isCancelled: Bool { status == "cancelled" }

        enum CodingKeys: String, CodingKey {
            case id, name, date, status, venue
            case startTime = "start_time"
        }
    }

    /// The links in the order the website shows them; only those that are set.
    static let linkFields: [(key: String, label: String)] = [
        ("website", "Website"),
        ("bandcamp_url", "Bandcamp"),
        ("spotify_url", "Spotify"),
        ("instagram_url", "Instagram"),
        ("facebook_url", "Facebook"),
        ("youtube_url", "YouTube"),
        ("linktree_url", "Linktree"),
        ("wikipedia_url", "Wikipedia"),
        ("musicbrainz_url", "MusicBrainz"),
        ("rym_url", "RateYourMusic"),
    ]

    private struct Key: CodingKey {
        let stringValue: String
        var intValue: Int? { nil }
        init(_ string: String) { stringValue = string }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)
        id = try c.decode(String.self, forKey: Key("id"))
        name = try c.decode(String.self, forKey: Key("name"))
        country = try c.decodeIfPresent(String.self, forKey: Key("country")).flatMap { $0.isEmpty ? nil : $0 }
        location = try c.decodeIfPresent(String.self, forKey: Key("location")).flatMap { $0.isEmpty ? nil : $0 }
        genres = try c.decodeIfPresent([String].self, forKey: Key("genres")) ?? []
        links = try Self.linkFields.compactMap { field in
            guard c.contains(Key(field.key)),
                  let url = try c.decodeIfPresent(String.self, forKey: Key(field.key)).flatMap(URL.init(nonEmpty:))
            else { return nil }
            return Link(label: field.label, url: url)
        }
        upcomingGigs = try c.decodeIfPresent([UpcomingGig].self, forKey: Key("upcoming_gigs")) ?? []
    }
}

/// Where the gig sheet's navigation can go besides a gig already loaded: an
/// act, or a gig known only by its id (from an act's upcoming gigs).
enum Route: Hashable, Sendable {
    case act(id: String, name: String)
    case gig(id: String)
}
