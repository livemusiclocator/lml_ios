import SwiftUI

/// One gig, laid out like the website's gig page
/// (`src/pages/GigDetails/GigDetails.jsx` in lml_frontend_client): a header,
/// a tickets button, a card of when / where / lineup / prices, then tags.
struct GigDetailView: View {
    let gig: Gig
    /// Narrows the explorer to this gig's venue.
    var showVenue: (Venue) -> Void = { _ in }
    var api = GigsAPI()

    @Environment(SavedGigs.self) private var saved

    /// The lineup's acts that have more than a name, so get a page.
    @State private var actsWorthAPage: Set<String> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                tickets
                details
                tags
                allGigsAtVenue
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(Color.night)
        .foregroundStyle(Color.ink)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: gig.id) { await findActsWorthAPage() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                let isSaved = saved.contains(gig)
                Button {
                    saved.toggle(gig)
                } label: {
                    Image(systemName: isSaved ? "star.fill" : "star")
                        .foregroundStyle(Color.lmlPinkLight)
                }
                .accessibilityLabel(isSaved ? "Remove from saved" : "Save this gig")
            }
        }
    }

    private func findActsWorthAPage() async {
        let ids = Set(gig.sets.compactMap { $0.act?.id })
        await withTaskGroup(of: String?.self) { group in
            for id in ids {
                group.addTask { [api] in
                    (try? await api.act(id: id))?.isWorthAPage == true ? id : nil
                }
            }
            for await id in group {
                if let id { actsWorthAPage.insert(id) }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(GigFormat.kicker(for: gig))
                .font(.system(.caption, design: .monospaced).weight(.medium))
                .tracking(1.5)
                .foregroundStyle(Color.lmlPinkLight)
            if let series = gig.series {
                Text(series.uppercased())
                    .font(.caption.weight(.semibold))
                    .tracking(0.5)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .foregroundStyle(Color.seriesInk)
                    .background(Color.seriesBackground, in: .capsule)
                    .accessibilityLabel("Gig series: \(series)")
            }
            (Text(gig.name)
                + Text(gig.isCancelled ? " (cancelled)" : "").foregroundStyle(Color.inkMuted))
                .font(.title.bold())
            Label(gig.venue.name, systemImage: "mappin.and.ellipse")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.inkMuted)
        }
        .padding(.top, 8)
    }

    @ViewBuilder private var tickets: some View {
        if let url = gig.ticketingURL {
            Link(destination: url) {
                Label(GigFormat.ticketsLabel(for: gig), systemImage: "ticket")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .foregroundStyle(.white)
                    .background(Color.lmlPink, in: .rect(cornerRadius: 12))
            }
        }
    }

    private var details: some View {
        VStack(spacing: 0) {
            DetailRow(icon: "clock") {
                Text(GigFormat.fullDate(for: gig)).font(.subheadline.weight(.semibold))
                Text([GigFormat.times(for: gig), GigFormat.timeZoneNote(for: gig)].compactMap { $0 }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(Color.inkMuted)
            }
            Divider().overlay(Color.nightLine)
            DetailRow(icon: "mappin.and.ellipse") {
                Button { showVenue(gig.venue) } label: {
                    Text(gig.venue.name).font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.plain)
                let venueDetails = GigFormat.venueDetails(for: gig.venue)
                if !venueDetails.isEmpty {
                    Text(venueDetails).font(.caption).foregroundStyle(Color.inkMuted)
                }
                if let directions = directionsURL {
                    Link(destination: directions) {
                        Label("Get directions", systemImage: "arrow.up.right.square")
                            .labelStyle(TrailingIconLabelStyle())
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.lmlPinkLight)
                    }
                    .padding(.top, 4)
                }
            }
            if !gig.sets.isEmpty {
                Divider().overlay(Color.nightLine)
                DetailRow(icon: "music.mic") {
                    Text("LINEUP")
                        .font(.caption2.weight(.semibold))
                        .tracking(1.5)
                        .foregroundStyle(Color.inkMuted)
                    ForEach(Array(Night.lineup(gig.sets).enumerated()), id: \.offset) { _, set in
                        if let act = set.act, let id = act.id, actsWorthAPage.contains(id) {
                            NavigationLink(value: Route.act(id: id, name: act.name)) {
                                LineupRow(set: set, linked: true)
                            }
                            .buttonStyle(.plain)
                        } else {
                            LineupRow(set: set, linked: false)
                        }
                    }
                }
            }
            if !gig.prices.isEmpty {
                Divider().overlay(Color.nightLine)
                DetailRow(icon: "ticket") {
                    ForEach(Array(gig.prices.enumerated()), id: \.offset) { _, price in
                        HStack(alignment: .firstTextBaseline) {
                            Text(price.description.flatMap { $0.isEmpty ? nil : $0 } ?? "Admission")
                            Spacer()
                            Text(price.amount).monospaced()
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                }
            }
        }
        .background(Color.nightRaised, in: .rect(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.nightLine))
    }

    @ViewBuilder private var tags: some View {
        if !gig.informationTags.isEmpty || !gig.genreTags.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                if !gig.informationTags.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(gig.informationTags, id: \.self) { Chip(text: $0, accent: false) }
                    }
                }
                if !gig.genreTags.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(gig.genreTags, id: \.self) { Chip(text: $0, accent: true) }
                    }
                }
            }
        }
    }

    private var allGigsAtVenue: some View {
        Button { showVenue(gig.venue) } label: {
            HStack {
                Text("All gigs at \(gig.venue.name)")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.right").font(.footnote).foregroundStyle(Color.inkDim)
            }
            .padding(14)
            .background(Color.nightRaised, in: .rect(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.nightLine))
        }
        .buttonStyle(.plain)
    }

    /// Apple Maps when we know where the venue is, otherwise the venue's own
    /// map link (usually Google Maps) like the website.
    private var directionsURL: URL? {
        if let coordinate = gig.venue.coordinate {
            var components = URLComponents(string: "https://maps.apple.com/")!
            components.queryItems = [
                URLQueryItem(name: "daddr", value: "\(coordinate.latitude),\(coordinate.longitude)"),
                URLQueryItem(name: "q", value: gig.venue.name),
            ]
            return components.url
        }
        return gig.venue.locationURL
    }
}

/// One act in the lineup: the name wraps rather than pushing the time off the
/// end. Acts with a page get a chevron.
private struct LineupRow: View {
    let set: GigSet
    let linked: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(set.act?.name ?? "TBA")
                .fontWeight(.semibold)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let startTime = set.startTime {
                Text(startTime)
                    .monospaced()
                    .foregroundStyle(Color.inkMuted)
            }
            if linked {
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(Color.inkDim)
            }
        }
        .font(.subheadline)
        .padding(.vertical, 2)
        .contentShape(.rect)
    }
}

private struct DetailRow<Content: View>: View {
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color.inkMuted)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 4) { content }
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
    }
}

struct Chip: View {
    let text: String
    let accent: Bool

    var body: some View {
        Text(text)
            .font(.caption.weight(accent ? .semibold : .medium))
            .padding(.horizontal, 12)
            .frame(height: 32)
            .foregroundStyle(accent ? Color.lmlPinkLight : Color.inkChip)
            .background(accent ? Color.lmlPink.opacity(0.15) : Color.nightChip, in: .capsule)
            .overlay(Capsule().stroke(accent ? Color.lmlPink.opacity(0.35) : .clear))
    }
}

private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.title
            configuration.icon
        }
    }
}

/// Lays chips out in rows, wrapping when a row is full.
struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(for: subviews, width: proposal.width ?? .infinity)
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(for: subviews, width: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func rows(for subviews: Subviews, width: CGFloat) -> [Row] {
        var rows = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if !rows[rows.count - 1].indices.isEmpty, rows[rows.count - 1].width + spacing + size.width > width {
                rows.append(Row())
            }
            var row = rows[rows.count - 1]
            row.width += (row.indices.isEmpty ? 0 : spacing) + size.width
            row.height = max(row.height, size.height)
            row.indices.append(index)
            rows[rows.count - 1] = row
        }
        return rows.filter { !$0.indices.isEmpty }
    }
}
