import Foundation
import MapKit
import Observation

/// Everything the explorer screen shows: which gigs, for when, and which of
/// them the sheet lists.
///
/// Every gig in the date range is fetched at once, so the map always has every
/// pin. The sheet lists the gigs on the part of the map in view, or one venue's
/// gigs when a pin is selected.
@MainActor
@Observable
final class ExplorerModel {
    /// The part of the map in view, once the map has reported it.
    var visibleRegion: MKCoordinateRegion?
    var range: DateRange = .thisWeek
    var selectedVenueID: Venue.ID?
    /// The gig pages pushed over the sheet's list.
    var path: [Gig] = []

    private(set) var gigs: [Gig] = []
    private(set) var isLoading = false
    private(set) var error: String?

    private let api: GigsAPI

    init(api: GigsAPI = GigsAPI()) {
        self.api = api
    }

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            gigs = try await api.gigs(range: range)
            if let selectedVenueID, !venues.contains(where: { $0.id == selectedVenueID }) {
                self.selectedVenueID = nil
            }
        } catch is CancellationError {
            // a newer load replaced this one
        } catch {
            self.error = "Couldn't load gigs. Pull to try again."
        }
    }

    /// Back to the list, narrowed to one venue's gigs.
    func show(venue: Venue) {
        selectedVenueID = venue.id
        path = []
    }

    /// One pin per venue, however many gigs it has.
    var venues: [Venue] {
        var seen = Set<Venue.ID>()
        return gigs.map(\.venue).filter { $0.coordinate != nil && seen.insert($0.id).inserted }
    }

    var selectedVenue: Venue? {
        venues.first { $0.id == selectedVenueID }
    }

    /// The gigs the sheet lists: the selected venue's, or those on the part of
    /// the map in view. A venue without coordinates has no pin, so its gigs are
    /// never in view.
    var shownGigs: [Gig] {
        if let selectedVenueID {
            return gigs.filter { $0.venue.id == selectedVenueID }
        }
        guard let visibleRegion else { return gigs }
        return gigs.filter { $0.venue.coordinate.map(visibleRegion.contains) ?? false }
    }

    /// The sheet's gigs, grouped under a heading per night.
    var days: [(date: String, gigs: [Gig])] {
        let byNight = Dictionary(grouping: shownGigs, by: \.night)
        return byNight.keys.sorted().map { night in
            (night, byNight[night]!.sorted { Night.sortKey(startTime: $0.startTime) < Night.sortKey(startTime: $1.startTime) })
        }
    }
}

extension MKCoordinateRegion {
    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        abs(coordinate.latitude - center.latitude) <= span.latitudeDelta / 2
            && abs(coordinate.longitude - center.longitude) <= span.longitudeDelta / 2
    }
}
