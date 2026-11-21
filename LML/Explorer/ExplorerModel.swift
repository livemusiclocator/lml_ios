import Foundation
import Observation

/// Everything the explorer screen shows: which gigs, for where and when, and
/// which venue (if any) the sheet is narrowed to.
@MainActor
@Observable
final class ExplorerModel {
    var location: Location = .anywhere
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
            gigs = try await api.gigs(location: location, range: range)
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

    /// The sheet's gigs, grouped under a heading per day.
    var days: [(date: String, gigs: [Gig])] {
        let shown = gigs.filter { selectedVenueID == nil || $0.venue.id == selectedVenueID }
        let byDate = Dictionary(grouping: shown, by: \.date)
        return byDate.keys.sorted().map { date in
            (date, byDate[date]!.sorted { ($0.startTime ?? "99") < ($1.startTime ?? "99") })
        }
    }
}
