import MapKit
import Testing

@testable import LML

struct VisibleRegionTests {
    static let metro = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -37.83, longitude: 145.0),
        span: MKCoordinateSpan(latitudeDelta: 0.26, longitudeDelta: 0.26)
    )

    @Test func fitzroyIsInMetroMelbourne() {
        #expect(Self.metro.contains(CLLocationCoordinate2D(latitude: -37.798362, longitude: 144.977083)))
    }

    @Test func bendigoIsNot() {
        #expect(!Self.metro.contains(CLLocationCoordinate2D(latitude: -36.76, longitude: 144.28)))
    }
}

struct NearbyGigsTests {
    static func venues() throws -> [Venue] {
        try GigDecodingTests.fixture().map(\.venue)
    }

    @Test func fitzroyHasGigsNearby() throws {
        let fitzroy = CLLocationCoordinate2D(latitude: -37.7985, longitude: 144.9785)
        #expect(VenueMap.hasVenues(near: fitzroy, in: try Self.venues()))
    }

    /// An App Store reviewer in California shouldn't land on an empty map.
    @Test func cupertinoDoesNot() throws {
        let cupertino = CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090)
        #expect(!VenueMap.hasVenues(near: cupertino, in: try Self.venues()))
    }

    @Test func sydneyDoesNot() throws {
        let sydney = CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093)
        #expect(!VenueMap.hasVenues(near: sydney, in: try Self.venues()))
    }
}
