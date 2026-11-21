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
