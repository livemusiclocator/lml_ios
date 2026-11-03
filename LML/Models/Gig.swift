import CoreLocation
import Foundation

/// A gig as `api.lml.live/gigs/query` returns it. Only the fields the explorer
/// shows are decoded; anything else in the payload is ignored.
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

    var isCancelled: Bool { status == "cancelled" }
    var isFree: Bool { informationTags.contains { $0.lowercased() == "free" } }

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
    }
}

struct Venue: Decodable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let address: String?
    let latitude: Double?
    let longitude: Double?

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
