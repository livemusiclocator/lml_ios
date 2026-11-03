import SwiftUI

/// One gig in the sheet, laid out like the web client's `GigRow`.
struct GigRow: View {
    let gig: Gig
    var showVenue = true

    private var secondary: String {
        ([showVenue ? gig.venue.name : nil] + gig.genreTags.prefix(3).map(Optional.some))
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(gig.startTime ?? "—")
                .font(.system(.footnote, design: .monospaced).weight(.medium))
                .foregroundStyle(Color.lmlPinkLight)
                .frame(width: 44, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                if let series = gig.series {
                    Text(series.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.lmlPinkLight)
                }
                (Text(gig.name).fontWeight(.semibold)
                    + Text(gig.isCancelled ? " · cancelled" : "").foregroundStyle(Color.inkMuted))
                    .lineLimit(1)
                if !secondary.isEmpty {
                    Text(secondary)
                        .font(.caption)
                        .foregroundStyle(Color.inkMuted)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if gig.isFree {
                Badge(text: "Free", filled: false)
            }
            if let label = gig.ticketStatusLabel {
                Badge(text: label, filled: true)
            }
        }
        .foregroundStyle(Color.ink)
        .padding(.vertical, 6)
    }
}

private struct Badge: View {
    let text: String
    let filled: Bool

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 9.5, weight: .bold))
            .tracking(1)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .foregroundStyle(filled ? Color.night : Color.lmlPinkLight)
            .background(filled ? Color.lmlPinkLight : .clear, in: .rect(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(filled ? .clear : Color.lmlPink.opacity(0.4)))
    }
}
