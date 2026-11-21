import MapKit
import SwiftUI

/// The venue map. It's UIKit's MKMapView rather than SwiftUI's Map because
/// only MKMapView groups nearby pins into one numbered pin when zoomed out.
struct VenueMap: UIViewRepresentable {
    let venues: [Venue]
    @Binding var selectedVenueID: Venue.ID?
    let initialRegion: MKCoordinateRegion
    /// Bumped by the locate button; each new value jumps to the person.
    var locateRequest = 0
    /// Whether `venues` is the loaded list yet, rather than empty for now.
    var venuesLoaded = false
    /// How far down the screen the map can be seen: the top of the gig sheet.
    /// Pins below it are hidden, so they aren't in the visible region.
    var visibleBottom: CGFloat?
    /// The part of the map that can be seen, whenever it comes to rest after a
    /// pan or zoom, or the sheet moves.
    var onRegionChange: (MKCoordinateRegion) -> Void = { _ in }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.overrideUserInterfaceStyle = .dark
        map.pointOfInterestFilter = .excludingAll
        map.showsCompass = false
        // flat and north-up, like the website's map
        map.isPitchEnabled = false
        map.isRotateEnabled = false
        map.register(VenueMarker.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        map.register(ClusterMarker.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        map.setRegion(initialRegion, animated: false)
        map.showsUserLocation = true
        context.coordinator.locationManager.requestWhenInUseAuthorization()
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        context.coordinator.parent = self
        if locateRequest != context.coordinator.lastLocateRequest {
            context.coordinator.lastLocateRequest = locateRequest
            context.coordinator.locate(on: map)
        }
        if visibleBottom != context.coordinator.lastVisibleBottom {
            context.coordinator.lastVisibleBottom = visibleBottom
            context.coordinator.reportVisibleRegion(of: map)
        }
        syncAnnotations(on: map)
        syncSelection(on: map)
        context.coordinator.jumpToUserIfWanted(on: map)
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    /// How close a venue has to be for the map to open on the person: a
    /// metro area's worth.
    nonisolated static let nearbyMeters: CLLocationDistance = 25_000

    /// Whether any venue is within reach of the person. Outside the places LML
    /// covers there aren't, and jumping there would open on an empty map.
    nonisolated static func hasVenues(near coordinate: CLLocationCoordinate2D, in venues: [Venue]) -> Bool {
        let here = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return venues.contains { venue in
            guard let c = venue.coordinate else { return false }
            return here.distance(from: CLLocation(latitude: c.latitude, longitude: c.longitude)) <= nearbyMeters
        }
    }

    /// A few suburbs around the person, with them in the part of the map above
    /// the sheet rather than in the middle of the screen, where it would hide them.
    static func region(around coordinate: CLLocationCoordinate2D) -> MKCoordinateRegion {
        let span = MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
        let center = CLLocationCoordinate2D(latitude: coordinate.latitude - span.latitudeDelta * 0.2, longitude: coordinate.longitude)
        return MKCoordinateRegion(center: center, span: span)
    }

    private func syncAnnotations(on map: MKMapView) {
        let existing = map.annotations.compactMap { $0 as? VenueAnnotation }
        let wanted = Dictionary(venues.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let stale = existing.filter { wanted[$0.venue.id] == nil }
        let present = Set(existing.map(\.venue.id))
        let added = wanted.values.filter { !present.contains($0.id) }.compactMap(VenueAnnotation.init)
        if !stale.isEmpty { map.removeAnnotations(stale) }
        if !added.isEmpty { map.addAnnotations(added) }
    }

    private func syncSelection(on map: MKMapView) {
        let selected = map.selectedAnnotations.compactMap { $0 as? VenueAnnotation }.first
        guard selected?.venue.id != selectedVenueID else { return }
        if let selected { map.deselectAnnotation(selected, animated: true) }
        if let id = selectedVenueID,
           let annotation = map.annotations.compactMap({ $0 as? VenueAnnotation }).first(where: { $0.venue.id == id }) {
            map.selectAnnotation(annotation, animated: true)
        }
    }

    @MainActor
    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: VenueMap
        let locationManager = CLLocationManager()
        /// On launch the map jumps to the person once, if there are gigs near
        /// them, and then leaves the map alone. It needs both their location and
        /// the gigs to decide, and either can arrive first.
        private var awaitingFirstJump = true
        /// The locate button was tapped before there was a fix: go to them
        /// when it arrives, gigs or not, since they asked.
        private var jumpWhenLocated = false

        init(parent: VenueMap) {
            self.parent = parent
        }

        var lastLocateRequest = 0

        func locate(on map: MKMapView) {
            if let location = map.userLocation.location {
                map.setRegion(VenueMap.region(around: location.coordinate), animated: true)
            } else {
                // no fix yet (or no permission): jump when one arrives
                jumpWhenLocated = true
                locationManager.requestWhenInUseAuthorization()
            }
        }

        func jumpToUserIfWanted(on map: MKMapView) {
            guard let location = map.userLocation.location else { return }
            if jumpWhenLocated {
                jumpWhenLocated = false
                awaitingFirstJump = false
                map.setRegion(VenueMap.region(around: location.coordinate), animated: true)
                return
            }
            guard awaitingFirstJump, parent.venuesLoaded else { return }
            awaitingFirstJump = false
            // nowhere near any gigs (another state, or overseas): stay on Melbourne
            guard VenueMap.hasVenues(near: location.coordinate, in: parent.venues) else { return }
            map.setRegion(VenueMap.region(around: location.coordinate), animated: true)
        }

        func mapView(_ map: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
            // the standard blue dot, not a venue pin that could be grouped
            annotation is MKUserLocation ? nil : map.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier, for: annotation)
        }

        func mapView(_ map: MKMapView, didAdd views: [MKAnnotationView]) {
            // you-are-here sits on top of the pins
            for view in views where view.annotation is MKUserLocation {
                view.zPriority = .max
            }
        }

        func mapView(_ map: MKMapView, didUpdate userLocation: MKUserLocation) {
            jumpToUserIfWanted(on: map)
        }

        var lastVisibleBottom: CGFloat?

        func mapView(_ map: MKMapView, regionDidChangeAnimated animated: Bool) {
            reportVisibleRegion(of: map)
        }

        /// The map above the sheet. Nothing is reported when the sheet covers
        /// (nearly) all of it: the list stays as it was until the map is back.
        func reportVisibleRegion(of map: MKMapView) {
            let bounds = map.bounds
            let height = min(bounds.height, parent.visibleBottom ?? bounds.height)
            guard bounds.width > 0, height > 80 else { return }
            let region = map.convert(CGRect(x: 0, y: 0, width: bounds.width, height: height), toRegionFrom: map)
            // not while SwiftUI is updating the view
            Task { @MainActor in self.parent.onRegionChange(region) }
        }

        func mapView(_ map: MKMapView, didSelect annotation: any MKAnnotation) {
            if let cluster = annotation as? MKClusterAnnotation {
                // a numbered pin opens up: zoom in until its venues separate
                map.deselectAnnotation(cluster, animated: false)
                map.showAnnotations(cluster.memberAnnotations, animated: true)
            } else if annotation is MKUserLocation {
                map.deselectAnnotation(annotation, animated: false)
            } else if let venue = annotation as? VenueAnnotation {
                parent.selectedVenueID = venue.venue.id
            }
        }

        func mapView(_ map: MKMapView, didDeselect annotation: any MKAnnotation) {
            guard let venue = annotation as? VenueAnnotation, parent.selectedVenueID == venue.venue.id else { return }
            // let a tap on another pin select it before deciding nothing is selected
            Task { @MainActor in
                if map.selectedAnnotations.isEmpty { self.parent.selectedVenueID = nil }
            }
        }
    }
}

final class VenueAnnotation: NSObject, MKAnnotation {
    let venue: Venue
    let coordinate: CLLocationCoordinate2D
    var title: String? { venue.name }

    init?(venue: Venue) {
        guard let coordinate = venue.coordinate else { return nil }
        self.venue = venue
        self.coordinate = coordinate
    }
}

private final class VenueMarker: MKMarkerAnnotationView {
    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = "venue"
        markerTintColor = UIColor(Color.lmlPink)
        glyphImage = UIImage(systemName: "music.note")
        titleVisibility = .adaptive
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    override func prepareForReuse() {
        super.prepareForReuse()
        clusteringIdentifier = "venue"
    }
}

/// A group of venues too close together to show apart at this zoom, numbered
/// with how many venues it holds.
private final class ClusterMarker: MKMarkerAnnotationView {
    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        markerTintColor = UIColor(Color.lmlPink)
        titleVisibility = .hidden
        subtitleVisibility = .hidden
        displayPriority = .defaultHigh
    }

    required init?(coder: NSCoder) { fatalError("not used") }
}
