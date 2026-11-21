import Foundation
import Observation

/// The gigs someone has starred, kept on the device (like the website, which
/// keeps them in the browser). Only enough is kept to find each gig again and
/// to forget it once its night is over: the gig itself is fetched fresh when
/// the Saved list is shown, so a cancellation or a new time shows up.
@MainActor
@Observable
final class SavedGigs {
    struct Entry: Codable, Hashable, Sendable {
        let id: String
        let venueID: String
        /// The gig's night ("YYYY-MM-DD"), to drop it once that's passed.
        let night: String
    }

    private(set) var entries: [Entry]
    private let defaults: UserDefaults
    private static let key = "savedGigs"

    init(defaults: UserDefaults = .standard, now: Date = .now) {
        self.defaults = defaults
        let stored = defaults.data(forKey: Self.key).flatMap { try? JSONDecoder().decode([Entry].self, from: $0) } ?? []
        // last night's gigs are kept until 5am, like everything else
        let tonight = DateRange.today.dates(now: now).from
        entries = stored.filter { $0.night >= tonight }
        if entries.count != stored.count { persist() }
    }

    var ids: Set<String> { Set(entries.map(\.id)) }
    var venueIDs: Set<String> { Set(entries.map(\.venueID)) }

    func contains(_ gig: Gig) -> Bool {
        entries.contains { $0.id == gig.id }
    }

    func toggle(_ gig: Gig) {
        if contains(gig) {
            remove(id: gig.id)
        } else {
            entries.append(Entry(id: gig.id, venueID: gig.venue.id, night: gig.night))
            persist()
        }
    }

    /// For a saved gig the API no longer knows about.
    func remove(id: String) {
        entries.removeAll { $0.id == id }
        persist()
    }

    /// Keeps the stored night and venue up to date when a refreshed gig has
    /// moved.
    func update(from gig: Gig) {
        guard let index = entries.firstIndex(where: { $0.id == gig.id }) else { return }
        let entry = Entry(id: gig.id, venueID: gig.venue.id, night: gig.night)
        if entries[index] != entry {
            entries[index] = entry
            persist()
        }
    }

    private func persist() {
        defaults.set(try? JSONEncoder().encode(entries), forKey: Self.key)
    }
}
