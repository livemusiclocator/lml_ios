import SwiftUI

/// Filters along the top of the gig list: the info toggles, the most common
/// genres in view, and More for the rest. Scrolls sideways.
struct FilterBar: View {
    @Bindable var model: ExplorerModel
    @State private var showingAllGenres = false

    /// Genres shown as chips before More: picked ones first, then the most
    /// common.
    private static let chipCount = 8

    var body: some View {
        let options = model.genreOptions
        let picked = options.filter { model.genreFilter.contains($0.id) }
        let chips = picked + options.filter { !model.genreFilter.contains($0.id) }.prefix(max(0, Self.chipCount - picked.count))

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if model.isFiltering {
                    Button { model.clearFilters() } label: {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.bold))
                            .frame(width: 32, height: 32)
                            .foregroundStyle(Color.ink)
                            .background(Color.nightChip, in: .circle)
                    }
                    .accessibilityLabel("Clear filters")
                }
                ForEach(InfoFilter.allCases) { info in
                    FilterChip(text: info.caption, isOn: model.infoFilter.contains(info)) {
                        model.infoFilter.formSymmetricDifference([info])
                    }
                }
                Rectangle().fill(Color.nightLine).frame(width: 1, height: 20)
                ForEach(chips) { genre in
                    FilterChip(text: genre.name, count: genre.count, isOn: model.genreFilter.contains(genre.id)) {
                        model.genreFilter.formSymmetricDifference([genre.id])
                    }
                }
                if options.count > chips.count {
                    FilterChip(text: "More", isOn: false, systemImage: "magnifyingglass") { showingAllGenres = true }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color.night)
        .sheet(isPresented: $showingAllGenres) {
            GenreList(model: model)
                .presentationDetents([.medium, .large])
                .presentationBackground(Color.night)
        }
    }
}

struct FilterChip: View {
    let text: String
    var count: Int?
    let isOn: Bool
    var systemImage: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage { Image(systemName: systemImage).font(.caption2) }
                Text(text)
                if let count, count > 0 {
                    Text("\(count)").monospacedDigit().opacity(0.6)
                }
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .frame(height: 32)
            .foregroundStyle(isOn ? .white : Color.inkChip)
            .background(isOn ? Color.lmlPink : Color.nightChip, in: .capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

/// Every genre in view, searchable, for when the chips don't have it.
private struct GenreList: View {
    @Bindable var model: ExplorerModel
    @State private var search = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let needle = Tags.key(search)
        let options = model.genreOptions.filter { needle.isEmpty || $0.id.contains(needle) }
        NavigationStack {
            List(options) { genre in
                Button {
                    model.genreFilter.formSymmetricDifference([genre.id])
                } label: {
                    HStack {
                        Text(genre.name).foregroundStyle(Color.ink)
                        Spacer()
                        if genre.count > 0 {
                            Text("\(genre.count)").monospacedDigit().foregroundStyle(Color.inkMuted)
                        }
                        Image(systemName: model.genreFilter.contains(genre.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(model.genreFilter.contains(genre.id) ? Color.lmlPinkLight : Color.inkDim)
                    }
                }
                .listRowBackground(Color.night)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search genres")
            .overlay {
                if options.isEmpty { Text("No genres match \"\(search)\".").foregroundStyle(Color.inkMuted) }
            }
            .navigationTitle("Genres in view")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .preferredColorScheme(.dark)
    }
}
