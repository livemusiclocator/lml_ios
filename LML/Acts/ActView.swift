import SwiftUI

/// An act, laid out like the website's act page (`src/pages/ActDetails` in
/// lml_frontend_client): who they are, their upcoming gigs, links.
struct ActView: View {
    let id: String
    /// Shown while the act loads, so the page isn't blank.
    let name: String
    var api = GigsAPI()

    @State private var act: Act?
    @State private var failure: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                if let act {
                    if !act.genres.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(act.genres, id: \.self) { Chip(text: $0, accent: true) }
                        }
                    }
                    upcoming(act)
                    links(act)
                } else if let failure {
                    Text(failure).foregroundStyle(Color.inkMuted)
                } else {
                    ProgressView().frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(Color.night)
        .foregroundStyle(Color.ink)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: id) { await load() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ACT")
                .font(.system(.caption, design: .monospaced).weight(.medium))
                .tracking(1.5)
                .foregroundStyle(Color.lmlPinkLight)
            Text(act?.name ?? name).font(.title.bold())
            if let origin = act?.origin {
                Label(origin, systemImage: "globe")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.inkMuted)
            }
        }
        .padding(.top, 8)
    }

    @ViewBuilder private func upcoming(_ act: Act) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeading(text: "UPCOMING GIGS")
            if act.upcomingGigs.isEmpty {
                Text("Nothing coming up that we know of.")
                    .font(.subheadline)
                    .foregroundStyle(Color.inkMuted)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(Night.upcoming(act.upcomingGigs).enumerated()), id: \.element.id) { index, gig in
                        if index > 0 { Divider().overlay(Color.nightLine) }
                        NavigationLink(value: Route.gig(id: gig.id)) {
                            UpcomingGigRow(gig: gig)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(Color.nightRaised, in: .rect(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.nightLine))
            }
        }
    }

    @ViewBuilder private func links(_ act: Act) -> some View {
        if !act.links.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeading(text: "FIND THEM ONLINE")
                FlowLayout(spacing: 8) {
                    ForEach(act.links, id: \.self) { link in
                        Link(destination: link.url) {
                            HStack(spacing: 6) {
                                Text(link.label)
                                Image(systemName: "arrow.up.right").font(.caption2)
                            }
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .frame(height: 32)
                            .foregroundStyle(Color.ink)
                            .background(Color.nightChip, in: .capsule)
                        }
                    }
                }
            }
        }
    }

    private func load() async {
        do {
            act = try await api.act(id: id)
        } catch is CancellationError {
        } catch is GigsAPI.NotFound {
            failure = "We don't seem to know about this act."
        } catch {
            failure = "Act details are unavailable right now. Please try again later."
        }
    }
}

private struct SectionHeading: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .tracking(1.5)
            .foregroundStyle(Color.inkMuted)
    }
}

/// "SAT 21 NOV · 20:00", the gig, and where.
private struct UpcomingGigRow: View {
    let gig: Act.UpcomingGig

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(GigFormat.kicker(date: gig.date, startTime: gig.startTime))
                    .font(.system(.caption2, design: .monospaced).weight(.medium))
                    .tracking(1)
                    .foregroundStyle(Color.lmlPinkLight)
                (Text(gig.name).fontWeight(.semibold)
                    + Text(gig.isCancelled ? " (cancelled)" : "").foregroundStyle(Color.inkMuted))
                    .font(.subheadline)
                    .lineLimit(2)
                Label(gig.venue.name, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(Color.inkMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right").font(.footnote).foregroundStyle(Color.inkDim)
        }
        .padding(14)
        .contentShape(.rect)
    }
}

/// A gig page for a gig known only by its id, such as one of an act's upcoming
/// gigs, which may be outside the dates the map has loaded.
struct GigLoaderView: View {
    let id: String
    var api = GigsAPI()
    var showVenue: (Venue) -> Void = { _ in }

    @State private var gig: Gig?
    @State private var failure: String?

    var body: some View {
        Group {
            if let gig {
                GigDetailView(gig: gig, showVenue: showVenue)
            } else if let failure {
                VStack(spacing: 12) {
                    Text("Gig not found").font(.title2.bold())
                    Text(failure).foregroundStyle(Color.inkMuted)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.night)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.night)
            }
        }
        .task(id: id) {
            do {
                gig = try await api.gig(id: id)
            } catch is CancellationError {
            } catch is GigsAPI.NotFound {
                failure = "We don't seem to know about this gig."
            } catch {
                failure = "Gig details are unavailable right now. Please try again later."
            }
        }
    }
}
