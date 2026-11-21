import CoreLocation
import Foundation

/// A gig as `api.lml.live/gigs/query` returns it. Only the fields the explorer
/// and the gig page show are decoded; anything else in the payload is ignored.
struct Gig: Decodable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    /// The gig's date in Melbourne, as the API sends it ("2026-11-03").
    let date: String
    let startTime: String?
    let status: String?
    let ticketStatus: String?
    let series: String?
    let informationTags: [String]
    let genreTags: [String]
    let venue: Venue
    let ticketingURL: URL?
    /// The venue's clock time the gig ends ("03:00"), like `startTime`.
    let finishTime: String?
    let sets: [GigSet]
    let prices: [Price]

    var isCancelled: Bool { status == "cancelled" }
    /// "Free", "free", "Free entry"... (see `InfoFilter`).
    var isFree: Bool { InfoFilter.free.matches(self) }

    var ticketStatusLabel: String? {
        switch ticketStatus {
        case "selling_fast": "Selling fast"
        case "sold_out": "Sold out"
        default: nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, name, date, status, series, venue
        case startTime = "start_time"
        case ticketStatus = "ticket_status"
        case informationTags = "information_tags"
        case genreTags = "genre_tags"
        case ticketingURL = "ticketing_url"
        case finishTime = "finish_time"
        case sets, prices
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        date = try c.decode(String.self, forKey: .date)
        startTime = try c.decodeIfPresent(String.self, forKey: .startTime)
        status = try c.decodeIfPresent(String.self, forKey: .status)
        ticketStatus = try c.decodeIfPresent(String.self, forKey: .ticketStatus)
        // the API sends "" rather than null for a gig with no series
        series = try c.decodeIfPresent(String.self, forKey: .series).flatMap { $0.isEmpty ? nil : $0 }
        informationTags = try c.decodeIfPresent([String].self, forKey: .informationTags) ?? []
        genreTags = try c.decodeIfPresent([String].self, forKey: .genreTags) ?? []
        venue = try c.decode(Venue.self, forKey: .venue)
        // "" rather than null again
        ticketingURL = try c.decodeIfPresent(String.self, forKey: .ticketingURL).flatMap(URL.init(nonEmpty:))
        finishTime = try c.decodeIfPresent(String.self, forKey: .finishTime)
        sets = try c.decodeIfPresent([GigSet].self, forKey: .sets) ?? []
        prices = try c.decodeIfPresent([Price].self, forKey: .prices) ?? []
    }
}

/// One act's set in a gig's lineup.
struct GigSet: Decodable, Hashable, Sendable {
    let startTime: String?
    let act: Act?

    struct Act: Decodable, Hashable, Sendable {
        let id: String?
        let name: String
    }

    enum CodingKeys: String, CodingKey {
        case act
        case startTime = "start_time"
    }
}

struct Price: Decodable, Hashable, Sendable {
    /// Already formatted by the API ("$30.00").
    let amount: String
    let description: String?
}

extension URL {
    init?(nonEmpty string: String) {
        guard !string.isEmpty else { return nil }
        self.init(string: string)
    }
}

struct Venue: Decodable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let address: String?
    let postcode: String?
    let capacity: Int?
    let locationURL: URL?
    let latitude: Double?
    let longitude: Double?

    enum CodingKeys: String, CodingKey {
        case id, name, address, postcode, capacity, latitude, longitude
        case locationURL = "location_url"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        address = try c.decodeIfPresent(String.self, forKey: .address)
        postcode = try c.decodeIfPresent(String.self, forKey: .postcode)
        capacity = try c.decodeIfPresent(Int.self, forKey: .capacity)
        locationURL = try c.decodeIfPresent(String.self, forKey: .locationURL).flatMap(URL.init(nonEmpty:))
        latitude = try c.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try c.decodeIfPresent(Double.self, forKey: .longitude)
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
