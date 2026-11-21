import MapKit
import SwiftUI

/// The map of venues with the gig list in a sheet over it, like the website's
/// explorer. Tapping a pin narrows the sheet to that venue's gigs.
struct ExplorerView: View {
    @State private var model = ExplorerModel()
    @State private var camera: MapCameraPosition = .region(Self.region(for: .anywhere))
    @State private var detent: PresentationDetent = .fraction(0.4)

    var body: some View {
        Map(position: $camera, selection: $model.selectedVenueID) {
            ForEach(model.venues) { venue in
                if let coordinate = venue.coordinate {
                    Marker(venue.name, systemImage: "music.note", coordinate: coordinate)
                        .tint(Color.lmlPink)
                        .tag(venue.id)
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .safeAreaInset(edge: .top, spacing: 0) { header }
        .sheet(isPresented: .constant(true)) {
            GigSheet(model: model)
                .presentationDetents([.height(120), .fraction(0.4), .large], selection: $detent)
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.4)))
                .presentationBackground(Color.night)
                .interactiveDismissDisabled()
        }
        .task(id: Query(location: model.location, range: model.range)) {
            await model.load()
        }
        .onChange(of: model.location) { _, location in
            model.selectedVenueID = nil
            withAnimation { camera = .region(Self.region(for: location)) }
        }
        .onChange(of: model.selectedVenueID) { _, id in
            if id != nil, detent == .height(120) { detent = .fraction(0.4) }
        }
        .onChange(of: model.path.isEmpty) { _, isEmpty in
            withAnimation { detent = isEmpty ? .fraction(0.4) : .large }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Menu {
                Picker("Location", selection: $model.location) {
                    ForEach(Location.all) { Text($0.caption).tag($0) }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(model.location.caption).font(.title2.bold())
                    Image(systemName: "chevron.down").font(.footnote).foregroundStyle(Color.inkMuted)
                }
                .foregroundStyle(Color.ink)
            }
            .accessibilityLabel("Choose a location")

            Spacer()

            Menu {
                Picker("When", selection: $model.range) {
                    ForEach(DateRange.allCases) { Text($0.caption).tag($0) }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(model.range.caption)
                    Image(systemName: "chevron.down").font(.caption2)
                }
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.lmlPink, in: .capsule)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color.nightRaised.opacity(0.95))
    }

    private static func region(for location: Location) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: location.center,
            span: MKCoordinateSpan(latitudeDelta: location.spanDegrees, longitudeDelta: location.spanDegrees)
        )
    }

    private struct Query: Equatable {
        let location: Location
        let range: DateRange
    }
}

private struct GigSheet: View {
    @Bindable var model: ExplorerModel

    var body: some View {
        NavigationStack(path: $model.path) {
            List {
                if let error = model.error {
                    Text(error).foregroundStyle(Color.inkMuted)
                } else if !model.isLoading && model.days.isEmpty {
                    Text("No gigs \(model.range.caption.lowercased()).").foregroundStyle(Color.inkMuted)
                }
                ForEach(model.days, id: \.date) { day in
                    Section(DayHeading.text(for: day.date)) {
                        ForEach(day.gigs) { gig in
                            NavigationLink(value: gig) {
                                GigRow(gig: gig, showVenue: model.selectedVenueID == nil)
                            }
                        }
                    }
                }
                .listRowBackground(Color.night)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .refreshable { await model.load() }
            .navigationDestination(for: Gig.self) { gig in
                GigDetailView(gig: gig) { model.show(venue: $0) }
            }
            .overlay {
                if model.isLoading && model.gigs.isEmpty { ProgressView() }
            }
            .navigationTitle(model.selectedVenue?.name ?? "\(model.days.reduce(0) { $0 + $1.gigs.count }) gigs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if model.selectedVenue != nil {
                    Button("Show all", systemImage: "xmark.circle.fill") { model.selectedVenueID = nil }
                }
            }
        }
    }
}

enum DayHeading {
    /// "Tuesday 3 November" from "2026-11-03".
    static func text(for date: String) -> String {
        let parser = DateFormatter()
        parser.timeZone = DateRange.melbourne
        parser.locale = Locale(identifier: "en_AU_POSIX")
        parser.dateFormat = "yyyy-MM-dd"
        guard let parsed = parser.date(from: date) else { return date }
        let formatter = DateFormatter()
        formatter.timeZone = DateRange.melbourne
        formatter.locale = Locale(identifier: "en_AU")
        formatter.setLocalizedDateFormatFromTemplate("EEEEdMMMM")
        return formatter.string(from: parsed)
    }
}

#Preview {
    ExplorerView()
}
