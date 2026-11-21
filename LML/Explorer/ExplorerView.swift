import MapKit
import SwiftUI

/// The map of venues with the gig list over it, like the website's explorer.
/// The list shows the gigs on the part of the map in view; tapping a pin
/// narrows it to that venue's gigs.
///
/// In narrow windows (every iPhone, iPad Slide Over) the list is a sheet over
/// the bottom of the map. In wide ones (iPad) it's a panel down the side, so
/// the map stays in view while you read a gig.
struct ExplorerView: View {
    @State private var model = ExplorerModel(saved: SavedGigs())
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isWide: Bool { sizeClass == .regular }
    static let panelWidth: CGFloat = 380
    static let panelMargin: CGFloat = 16
    /// Where the bottom of the map is on screen, to compare with the sheet's top.
    @State private var mapBottom: CGFloat = 0
    /// The sheet's smallest height: just the grabber and the gig count, leaving
    /// the rest of the screen to the map.
    static let collapsed = PresentationDetent.height(64)
    @State private var detent: PresentationDetent = .fraction(0.4)
    @State private var locateRequest = 0
    /// Where the top of the sheet is on screen.
    @State private var sheetTop: CGFloat?

    var body: some View {
        VenueMap(
            venues: model.venues,
            savedVenueIDs: model.saved.venueIDs,
            selectedVenueID: $model.selectedVenueID,
            initialRegion: Self.metroMelbourne,
            locateRequest: locateRequest,
            venuesLoaded: model.hasLoaded,
            covered: covered
        ) { model.visibleRegion = $0 }
        .ignoresSafeArea()
        .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).maxY } action: { mapBottom = $0 }
        .overlay(alignment: .leading) {
            if isWide { panel }
        }
        .overlay(alignment: .topTrailing) {
            VStack(alignment: .trailing, spacing: 12) {
                datePicker
                locateButton
            }
            .padding()
        }
        .sheet(isPresented: .constant(!isWide)) {
            GigSheet(model: model)
                .environment(model.saved)
                .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: { sheetTop = $0 }
                .presentationDetents([Self.collapsed, .fraction(0.4), .large], selection: $detent)
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.4)))
                .presentationBackground(Color.night)
                .interactiveDismissDisabled()
        }
        .task(id: model.showing) {
            await model.load()
        }
        .onChange(of: model.selectedVenueID) { _, id in
            if id != nil, detent == Self.collapsed { detent = .fraction(0.4) }
        }
        .onChange(of: model.path.isEmpty) { _, isEmpty in
            withAnimation { detent = isEmpty ? .fraction(0.4) : .large }
        }
        .preferredColorScheme(.dark)
    }

    /// The gig list beside the map, for wide windows.
    private var panel: some View {
        GigSheet(model: model)
            .environment(model.saved)
            .frame(width: Self.panelWidth)
            .background(Color.night)
            .clipShape(.rect(cornerRadius: 24))
            .shadow(color: .black.opacity(0.4), radius: 12, y: 4)
            .padding(Self.panelMargin)
    }

    /// The edges of the map the list covers: the side for the panel, the
    /// bottom for the sheet.
    private var covered: UIEdgeInsets {
        if isWide {
            return UIEdgeInsets(top: 0, left: Self.panelWidth + Self.panelMargin * 2, bottom: 0, right: 0)
        }
        guard let sheetTop, mapBottom > 0 else { return .zero }
        return UIEdgeInsets(top: 0, left: 0, bottom: max(0, mapBottom - sheetTop), right: 0)
    }

    private var datePicker: some View {
        Menu {
            Picker("When", selection: $model.showing) {
                ForEach(DateRange.allCases) { Text($0.caption).tag(Showing.dates($0)) }
                Divider()
                Label("Saved", systemImage: "star").tag(Showing.saved)
            }
        } label: {
            HStack(spacing: 4) {
                if model.showing == .saved { Image(systemName: "star.fill").font(.caption) }
                Text(model.showing.caption)
                Image(systemName: "chevron.down").font(.caption2)
            }
            .font(.subheadline.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.lmlPink, in: .capsule)
            .shadow(color: .black.opacity(0.4), radius: 6, y: 2)
        }
        .accessibilityLabel("Choose dates: \(model.showing.caption)")
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
                    Text(emptyMessage).foregroundStyle(Color.inkMuted)
                }
                ForEach(model.days, id: \.date) { day in
                    Section {
                        ForEach(day.gigs) { gig in
                            NavigationLink(value: gig) {
                                GigRow(gig: gig, showVenue: model.selectedVenueID == nil, isSaved: model.saved.contains(gig))
                            }
                        }
                    } header: {
                        Text(DayHeading.text(for: day.date))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.inkMuted)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                            .background(Color.night)
                    }
                }
                .listRowBackground(Color.night)
            }
            .listStyle(.plain)
            .safeAreaInset(edge: .top, spacing: 0) { FilterBar(model: model) }
            // the first day straight under the count, not a row's height below it
            .listSectionSpacing(0)
            .contentMargins(.top, 0, for: .scrollContent)
            .environment(\.defaultMinListHeaderHeight, 0)
            .scrollContentBackground(.hidden)
            .refreshable { await model.load() }
            .navigationDestination(for: Gig.self) { gig in
                GigDetailView(gig: gig) { model.show(venue: $0) }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case let .act(id, name): ActView(id: id, name: name)
                case let .gig(id): GigLoaderView(id: id) { model.show(venue: $0) }
                }
            }
            .overlay {
                if model.isLoading && model.gigs.isEmpty { ProgressView() }
            }
            // the toolbar's title item draws the title; this is for VoiceOver
            .navigationTitle(model.selectedVenue?.name ?? "\(model.shownGigs.count) gigs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { title }
                if model.selectedVenue != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Show all", systemImage: "xmark.circle.fill") { model.selectedVenueID = nil }
                    }
                }
            }
        }
    }

    private var emptyMessage: String {
        switch model.showing {
        case _ where model.isFiltering && !model.gigs.isEmpty: "No gigs here match these filters."
        case .saved: "No saved gigs coming up. Tap ☆ on a gig to save it."
        case let .dates(range) where model.gigs.isEmpty: "No gigs \(range.caption.lowercased())."
        case let .dates(range): "No gigs on this part of the map \(range.caption.lowercased())."
        }
    }

    /// The count rolls from one number to the next, like an odometer, as the
    /// map moves and the sheet is dragged.
    @ViewBuilder private var title: some View {
        if let venue = model.selectedVenue {
            Text(venue.name).font(.headline).lineLimit(1)
        } else {
            let count = model.shownGigs.count
            Text("\(count) \(model.showing == .saved ? "saved" : "") \(count == 1 ? "gig" : "gigs")".replacingOccurrences(of: "  ", with: " "))
                .font(.headline)
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(count)))
                .animation(.snappy, value: count)
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
