// Encore/Views/Discover/DiscoveryFilterSheet.swift
import SwiftUI

struct DiscoveryFilterSheet: View {

    @EnvironmentObject var discoveryStore: FestivalDiscoveryStore
    @Environment(\.dismiss) private var dismiss

    /// Which genre category rows are currently expanded to show sub-genres.
    @State private var expandedCategories: Set<String> = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    artistSection
                    sectionDivider
                    campingSection
                    sectionDivider
                    regionSection
                    sectionDivider
                    genreSection
                }
                .padding(.bottom, DS.Spacing.pageMargin)
            }
            .background(Color.appBackground)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear all") {
                        discoveryStore.clearFilters()
                        expandedCategories = []
                    }
                    .font(DS.Font.listItem)
                    .foregroundColor(discoveryStore.hasActiveFilters ? .appCTA : .appTextMuted)
                    .disabled(!discoveryStore.hasActiveFilters)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(DS.Font.listItem)
                        .fontWeight(.semibold)
                        .foregroundColor(.appCTA)
                }
            }
        }
    }

    // MARK: - Section: Artist Name

    private var artistSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sectionGap) {
            sectionHeader("Find festivals featuring")
            HStack(spacing: 10) {
                Image(systemName: "person.fill")
                    .font(DS.Font.metadata)
                    .foregroundColor(.appTextMuted)
                TextField("Artist name…", text: $discoveryStore.artistNameFilter)
                    .font(DS.Font.listItem)
                    .foregroundColor(.appTextPrimary)
                    .autocorrectionDisabled()
                if !discoveryStore.artistNameFilter.isEmpty {
                    Button(action: { discoveryStore.artistNameFilter = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.appTextMuted)
                    }
                }
            }
            .padding(DS.Spacing.cardPadding)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
        }
        .padding(.horizontal, DS.Spacing.pageMargin)
        .padding(.top, DS.Spacing.sectionHeaderGap)
        .padding(.bottom, DS.Spacing.cardPadding)
    }

    // MARK: - Section: Camping

    private var campingSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sectionGap) {
            sectionHeader("Type")
            HStack(spacing: 8) {
                ForEach(CampingFilter.allCases) { option in
                    campingPill(option)
                }
            }
        }
        .padding(.horizontal, DS.Spacing.pageMargin)
        .padding(.top, DS.Spacing.sectionHeaderGap)
        .padding(.bottom, DS.Spacing.cardPadding)
    }

    private func campingPill(_ option: CampingFilter) -> some View {
        let isSelected = discoveryStore.campingFilter == option
        return Button(action: { discoveryStore.campingFilter = option }) {
            HStack(spacing: 5) {
                if option == .campingOnly {
                    Image(systemName: "tent.fill")
                        .font(.system(size: 10))
                } else if option == .noCamping {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 10))
                }
                Text(option.rawValue)
                    .font(DS.Font.label)
            }
            .foregroundColor(isSelected ? Color.appBackground : .appTextMuted)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(isSelected ? Color.appCTA : Color.appSurface)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section: Region

    private var regionSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sectionGap) {
            sectionHeader("Region")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(RegionFilter.allCases) { option in
                        regionPill(option)
                    }
                }
            }
        }
        .padding(.horizontal, DS.Spacing.pageMargin)
        .padding(.top, DS.Spacing.sectionHeaderGap)
        .padding(.bottom, DS.Spacing.cardPadding)
    }

    private func regionPill(_ option: RegionFilter) -> some View {
        let isSelected = discoveryStore.regionFilter == option
        return Button(action: { discoveryStore.regionFilter = option }) {
            Text(option.rawValue)
                .font(DS.Font.label)
                .foregroundColor(isSelected ? Color.appBackground : .appTextMuted)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(isSelected ? Color.appCTA : Color.appSurface)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section: Genre

    private var genreSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Genre")
                .padding(.horizontal, DS.Spacing.pageMargin)
                .padding(.top, DS.Spacing.sectionHeaderGap)
                .padding(.bottom, DS.Spacing.sectionGap)

            ForEach(GenreTaxonomy.categories) { category in
                categoryRow(category)
                if expandedCategories.contains(category.id) {
                    subGenreGrid(category)
                        .padding(.bottom, 4)
                }
                Divider()
                    .padding(.horizontal, DS.Spacing.pageMargin)
                    .opacity(0.4)
            }
        }
    }

    private func categoryRow(_ category: GenreCategory) -> some View {
        let isActive = discoveryStore.isCategoryActive(category)
        let isExpanded = expandedCategories.contains(category.id)
        let selectedSubCount = category.subcategories.filter { discoveryStore.selectedGenres.contains($0) }.count

        return HStack(spacing: 0) {
            // Left: icon + name — tap to select/deselect whole category
            Button(action: { discoveryStore.toggleCategory(category) }) {
                HStack(spacing: 10) {
                    Image(systemName: category.icon)
                        .font(.system(size: 14))
                        .foregroundColor(isActive ? .appCTA : .appTextMuted)
                        .frame(width: 22)
                    Text(category.name)
                        .font(DS.Font.listItem)
                        .foregroundColor(isActive ? .appTextPrimary : .appTextMuted)
                    Spacer()
                    // Show how many subs are selected, or just a checkmark for top-level
                    if selectedSubCount > 0 {
                        Text("\(selectedSubCount)")
                            .font(DS.Font.caps)
                            .foregroundColor(.appBackground)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.appCTA)
                            .clipShape(Capsule())
                    } else if discoveryStore.selectedGenres.contains(category.name) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.appCTA)
                    }
                }
                .padding(.leading, DS.Spacing.pageMargin)
                .padding(.trailing, DS.Spacing.cardPadding)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Right: expand/collapse chevron — tap to reveal sub-genres
            Button(action: { toggleExpand(category.id) }) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.appTextMuted)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 4)
        }
    }

    private func subGenreGrid(_ category: GenreCategory) -> some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 100), spacing: 8)],
            alignment: .leading,
            spacing: 8
        ) {
            ForEach(category.subcategories, id: \.self) { sub in
                subChip(sub)
            }
        }
        .padding(.horizontal, DS.Spacing.pageMargin)
        .padding(.bottom, DS.Spacing.sectionGap)
    }

    private func subChip(_ genre: String) -> some View {
        let isSelected = discoveryStore.selectedGenres.contains(genre)
        return Button(action: { discoveryStore.toggleGenre(genre) }) {
            Text(genre)
                .font(DS.Font.caps)
                .lineLimit(1)
                .foregroundColor(isSelected ? Color.appBackground : .appTextMuted)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(isSelected ? Color.appCTA : Color.appSurface)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(
                        isSelected ? Color.clear : Color.appAccent.opacity(0.25),
                        lineWidth: 1
                    )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func toggleExpand(_ id: String) {
        if expandedCategories.contains(id) {
            expandedCategories.remove(id)
        } else {
            expandedCategories.insert(id)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(DS.Font.label)
            .foregroundColor(.appTextMuted)
            .textCase(.uppercase)
            .tracking(0.8)
    }

    private var sectionDivider: some View {
        Divider()
            .padding(.horizontal, DS.Spacing.pageMargin)
    }
}

#Preview {
    DiscoveryFilterSheet()
        .environmentObject(FestivalDiscoveryStore())
        .preferredColorScheme(.dark)
}
