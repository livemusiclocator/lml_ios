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
                    Section {
                        ForEach(day.gigs) { gig in
                            NavigationLink(value: gig) {
                                GigRow(gig: gig, showVenue: model.selectedVenueID == nil)
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
            // the first day straight under the count, not a row's height below it
            .listSectionSpacing(0)
            .contentMargins(.top, 0, for: .scrollContent)
            .environment(\.defaultMinListHeaderHeight, 0)
            .scrollContentBackground(.hidden)
            .refreshable { await model.load() }
            .navigationDestination(for: Gig.self) { gig in
                GigDetailView(gig: gig) { model.show(venue: $0) }
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

    /// The count rolls from one number to the next, like an odometer, as the
    /// map moves and the sheet is dragged.
    @ViewBuilder private var title: some View {
        if let venue = model.selectedVenue {
            Text(venue.name).font(.headline).lineLimit(1)
        } else {
            let count = model.shownGigs.count
            Text("\(count) \(count == 1 ? "gig" : "gigs")")
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
