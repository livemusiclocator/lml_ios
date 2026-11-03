import CoreLocation

/// A volunteer group's patch, not a piece of geography: it decides which gigs
/// the API returns and where the map starts.
///
/// Hardcoded from the selectable locations in the website's explorer config
/// for now. The real list lives in `Web::Location` in lml_rb and reaches the
/// website embedded in the page as `window.APP_CONFIG`; an app wants a JSON
/// endpoint for it so a new location doesn't need an App Store release.
struct Location: Identifiable, Hashable, Sendable {
    let id: String
    let caption: String
    let latitude: Double
    let longitude: Double
    /// The web map's zoom level, converted to a span for MapKit below.
    let zoom: Int

    var center: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Roughly what a web map tile zoom shows across a phone screen.
    var spanDegrees: Double { 360 / pow(2, Double(zoom)) * 1.5 }

    static let all: [Location] = [
        Location(id: "anywhere", caption: "Anywhere", latitude: -37.40725549559874, longitude: 143.90167236328128, zoom: 9),
        Location(id: "castlemaine", caption: "Castlemaine", latitude: -37.063670785361964, longitude: 144.21660007885495, zoom: 15),
        Location(id: "melbourne", caption: "Melbourne", latitude: -37.80198943476701, longitude: 144.9594068527222, zoom: 14),
        Location(id: "stkilda", caption: "St Kilda", latitude: -37.8642383, longitude: 144.9613908, zoom: 15),
        Location(id: "geelong", caption: "Geelong", latitude: -38.16272938784327, longitude: 144.3539325977462, zoom: 12),
        Location(id: "queenscliff", caption: "Queenscliff", latitude: -38.26662363973944, longitude: 144.65717383782115, zoom: 15),
        Location(id: "bendigo", caption: "Bendigo", latitude: -36.760192398148355, longitude: 144.2293739318848, zoom: 13),
    ]

    static let anywhere = all[0]
}
