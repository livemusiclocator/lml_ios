import Foundation
import MapKit
import Observation
import SwiftUI

/// Everything the explorer screen shows: which gigs, for when, and which of
/// them the sheet lists.
///
/// Every gig in the date range is fetched at once, so the map always has every
/// pin. The sheet lists the gigs on the part of the map in view, or one venue's
/// gigs when a pin is selected. Or, for Saved, the starred gigs, wherever they
/// are.
@MainActor
@Observable
final class ExplorerModel {
    /// The part of the map in view, once the map has reported it.
    var visibleRegion: MKCoordinateRegion?
    var showing: Showing = .dates(.thisWeek)
    var selectedVenueID: Venue.ID?
    /// Genres picked in the filter, by `Tags.key`; a gig with any of them shows.
    var genreFilter: Set<String> = []
    /// Info toggles that are on; a gig must match them all.
    var infoFilter: Set<InfoFilter> = []

    var isFiltering: Bool { !genreFilter.isEmpty || !infoFilter.isEmpty }

    func clearFilters() {
        genreFilter = []
        infoFilter = []
    }
    /// The gig pages pushed over the sheet's list.
    var path = NavigationPath()

    private(set) var gigs: [Gig] = []
    private(set) var isLoading = false
    /// Whether gigs have loaded at least once, so an empty list means none.
    private(set) var hasLoaded = false
    private(set) var error: String?

    private let api: GigsAPI
    let saved: SavedGigs

    init(api: GigsAPI = GigsAPI(), saved: SavedGigs) {
        self.api = api
        self.saved = saved
    }

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            switch showing {
            case let .dates(range): gigs = try await api.gigs(range: range)
            case .saved: gigs = try await loadSaved()
            }
            hasLoaded = true
            if let selectedVenueID, !venues.contains(where: { $0.id == selectedVenueID }) {
                self.selectedVenueID = nil
            }
        } catch is CancellationError {
            // a newer load replaced this one
        } catch {
            self.error = "Couldn't load gigs. Pull to try again."
        }
    }

    /// The saved gigs, fresh from the API: still upcoming, soonest first.
    /// Gigs the API no longer has are forgotten.
    private func loadSaved() async throws -> [Gig] {
        let ids = saved.ids
        let api = self.api
        var fetched: [Gig] = []
        var gone: [String] = []
        try await withThrowingTaskGroup(of: (String, Gig?).self) { group in
            for id in ids {
                group.addTask {
                    do { return (id, try await api.gig(id: id)) } catch is GigsAPI.NotFound { return (id, nil) }
                }
            }
            for try await (id, gig) in group {
                if let gig { fetched.append(gig) } else { gone.append(id) }
            }
        }
        gone.forEach(saved.remove(id:))
        fetched.forEach(saved.update(from:))
        let tonight = DateRange.today.dates().from
        return fetched.filter { $0.night >= tonight }
    }

    /// Back to the list, narrowed to one venue's gigs.
    func show(venue: Venue) {
        selectedVenueID = venue.id
        path = NavigationPath()
    }

    /// One pin per venue, however many gigs it has.
    var venues: [Venue] {
        var seen = Set<Venue.ID>()
        return filteredGigs.map(\.venue).filter { $0.coordinate != nil && seen.insert($0.id).inserted }
    }

    /// The loaded gigs that pass the filters: what the pins show.
    var filteredGigs: [Gig] {
        gigs.filter { matchesInfo($0) && matchesGenre($0) }
    }

    private func matchesInfo(_ gig: Gig) -> Bool {
        infoFilter.allSatisfy { $0.matches(gig) }
    }

    private func matchesGenre(_ gig: Gig) -> Bool {
        genreFilter.isEmpty || gig.genreTags.contains { genreFilter.contains(Tags.key($0)) }
    }

    /// The genres to offer: those on the gigs the list would show without a
    /// genre filter (in view, info toggles applied), most gigs first. Picked
    /// genres stay offered even when nothing in view has them.
    var genreOptions: [GenreOption] {
        let options = Tags.genres(in: listed(gigs.filter(matchesInfo)))
        let offered = Set(options.map(\.id))
        let picked = Tags.genres(in: gigs).filter { genreFilter.contains($0.id) && !offered.contains($0.id) }
            .map { GenreOption(id: $0.id, name: $0.name, count: 0) }
        return options + picked
    }

    var selectedVenue: Venue? {
        venues.first { $0.id == selectedVenueID }
    }

    /// The gigs the sheet lists: the selected venue's, or those on the part of
    /// the map in view. A venue without coordinates has no pin, so its gigs are
    /// never in view.
    var shownGigs: [Gig] { listed(filteredGigs) }

    private func listed(_ gigs: [Gig]) -> [Gig] {
        if let selectedVenueID {
            return gigs.filter { $0.venue.id == selectedVenueID }
        }
        // the Saved list is every saved gig, on the map in view or not; one
        // unstarred since it loaded drops out straight away
        if showing == .saved { return gigs.filter { saved.ids.contains($0.id) } }
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

/// What the explorer lists: a range of nights, or the saved gigs.
enum Showing: Hashable, Sendable {
    case dates(DateRange)
    case saved

    var caption: String {
        switch self {
        case let .dates(range): range.caption
        case .saved: "Saved"
        }
    }
}
