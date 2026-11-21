import Foundation
import Testing

@testable import LML

struct ActTests {
    static func fixture(_ name: String) throws -> Act {
        let url = try #require(Bundle(for: ActBundleToken.self).url(forResource: name, withExtension: "json"))
        return try JSONDecoder().decode(Act.self, from: Data(contentsOf: url))
    }

    @Test func decodesAFilledInAct() throws {
        let act = try Self.fixture("act-kevin-morby")
        #expect(act.name == "Kevin Morby")
        #expect(act.origin == "USA")
        #expect(act.genres == ["indie rock", "folk"])
        #expect(act.links.map(\.label) == ["Website", "Bandcamp", "Instagram", "Wikipedia", "MusicBrainz"])
        #expect(act.upcomingGigs.count == 2)
        #expect(act.upcomingGigs.first?.venue.name == "The Bridge Hotel")
        #expect(act.isWorthAPage)
    }

    /// Most acts are just a name: the lineup already shows that, so no page.
    @Test func aNameIsNotWorthAPage() throws {
        let act = try Self.fixture("act-name-only")
        #expect(act.links.isEmpty)
        #expect(act.origin == nil)
        #expect(!act.isWorthAPage)
    }

    @Test func upcomingGigsSoonestNightFirst() throws {
        let json = """
        [{"id": "b", "name": "B", "date": "2026-11-23", "start_time": "01:00", "venue": {"id": "v", "name": "V"}},
         {"id": "c", "name": "C", "date": "2026-11-23", "start_time": "20:00", "venue": {"id": "v", "name": "V"}},
         {"id": "a", "name": "A", "date": "2026-11-22", "start_time": "21:00", "venue": {"id": "v", "name": "V"}}]
        """
        let gigs = try JSONDecoder().decode([Act.UpcomingGig].self, from: Data(json.utf8))
        // the 01:00 set on the 23rd is the night of the 22nd, after the 21:00 one
        #expect(Night.upcoming(gigs).map(\.id) == ["a", "b", "c"])
    }
}

private final class ActBundleToken {}

struct ActOriginTests {
    static func act(location: String?, country: String?) throws -> Act {
        var json: [String: Any] = ["id": "a", "name": "A"]
        json["location"] = location ?? NSNull()
        json["country"] = country ?? NSNull()
        return try JSONDecoder().decode(Act.self, from: JSONSerialization.data(withJSONObject: json))
    }

    @Test func lmlLocationIdsGetCapitals() throws {
        #expect(try Self.act(location: "melbourne", country: "Australia").origin == "Melbourne, Australia")
    }

    @Test func typedPlacesStayAsTyped() throws {
        #expect(try Self.act(location: "UK", country: nil).origin == "UK")
    }
}
