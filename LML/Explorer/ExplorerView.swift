import MapKit
import SwiftUI

/// The map of venues with the gig list in a sheet over it, like the website's
/// explorer. The sheet lists the gigs on the part of the map in view; tapping
/// a pin narrows it to that venue's gigs.
struct ExplorerView: View {
    @State private var model = ExplorerModel()
    @State private var detent: PresentationDetent = .fraction(0.4)
    @State private var locateRequest = 0
    /// Where the top of the sheet is on screen.
    @State private var sheetTop: CGFloat?

    var body: some View {
        VenueMap(
            venues: model.venues,
            selectedVenueID: $model.selectedVenueID,
            initialRegion: Self.metroMelbourne,
            locateRequest: locateRequest,
            visibleBottom: sheetTop
        ) { model.visibleRegion = $0 }
        .ignoresSafeArea()
        .overlay(alignment: .topTrailing) {
            VStack(alignment: .trailing, spacing: 12) {
                datePicker
                locateButton
            }
            .padding()
        }
        .sheet(isPresented: .constant(true)) {
            GigSheet(model: model)
                .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: { sheetTop = $0 }
                .presentationDetents([.height(120), .fraction(0.4), .large], selection: $detent)
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.4)))
                .presentationBackground(Color.night)
                .interactiveDismissDisabled()
        }
        .task(id: model.range) {
            await model.load()
        }
        .onChange(of: model.selectedVenueID) { _, id in
            if id != nil, detent == .height(120) { detent = .fraction(0.4) }
        }
        .onChange(of: model.path.isEmpty) { _, isEmpty in
            withAnimation { detent = isEmpty ? .fraction(0.4) : .large }
        }
        .preferredColorScheme(.dark)
    }

    private var datePicker: some View {
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
            .shadow(color: .black.opacity(0.4), radius: 6, y: 2)
        }
        .accessibilityLabel("Choose dates: \(model.range.caption)")
    }

    private var locateButton: some View {
        Button { locateRequest += 1 } label: {
            Image(systemName: "location.fill")
                .font(.subheadline.bold())
                .foregroundStyle(Color.lmlPinkLight)
                .frame(width: 40, height: 40)
                .background(Color.nightRaised.opacity(0.95), in: .circle)
                .shadow(color: .black.opacity(0.4), radius: 6, y: 2)
        }
        .accessibilityLabel("Show where I am")
    }

    /// Where the map starts: metro Melbourne, where most of the gigs are.
    private static let metroMelbourne = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -37.83, longitude: 145.0),
        span: MKCoordinateSpan(latitudeDelta: 0.26, longitudeDelta: 0.26)
    )
}

private struct GigSheet: View {
    @Bindable var model: ExplorerModel

    var body: some View {
        NavigationStack(path: $model.path) {
            List {
                if let error = model.error {
                    Text(error).foregroundStyle(Color.inkMuted)
                } else if !model.isLoading && model.days.isEmpty {
                    Text(model.gigs.isEmpty ? "No gigs \(model.range.caption.lowercased())." : "No gigs on this part of the map \(model.range.caption.lowercased()).").foregroundStyle(Color.inkMuted)
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
            .navigationTitle(model.selectedVenue?.name ?? "\(model.shownGigs.count) gigs")
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
