// Encore/Views/Journal/SetJournalEntryView.swift
import SwiftUI

struct SetJournalEntryView: View {

    @EnvironmentObject var journalStore: JournalStore
    @Environment(\.dismiss) private var dismiss

    // Context
    let existingEntry: JournalEntry?
    let festivalSet: FestivalSet?
    let artist: Artist?
    let festival: Festival?

    @State private var rating: Int = 0
    @State private var notes: String = ""
    @State private var showNotes: Bool = false
    @State private var selectedHighlights: Set<String> = []
    @State private var customHighlight: String = ""
    @State private var showCustomHighlightField = false
    @State private var wouldSeeAgain: WouldSeeAgain? = nil
    @State private var showDeleteConfirm = false

    private let presetHighlights = [
        "Best energy", "Surprise guest", "Perfect setlist", "Great crowd",
        "Emotional moment", "Technical issues", "Too crowded", "Discovered a new fave"
    ]

    // MARK: - Inits

    /// Edit an existing journal entry.
    init(entry: JournalEntry) {
        self.existingEntry = entry
        self.festivalSet = nil
        self.artist = nil
        self.festival = nil
        self._rating = State(initialValue: entry.rating ?? 0)
        self._notes = State(initialValue: entry.notes)
        self._showNotes = State(initialValue: !entry.notes.isEmpty)
        self._selectedHighlights = State(initialValue: Set(entry.highlights))
        self._wouldSeeAgain = State(initialValue: entry.wouldSeeAgain)
    }

    /// Create a new entry from the quick-log flow (festival → artist picker).
    init(artist: Artist, festival: Festival) {
        self.existingEntry = nil
        self.festivalSet = nil
        self.artist = artist
        self.festival = festival
    }

    /// Create a new entry from an artist detail page that has a specific FestivalSet.
    init(festivalSet: FestivalSet, festival: Festival? = nil) {
        self.existingEntry = nil
        self.festivalSet = festivalSet
        self.artist = nil
        self.festival = festival
    }

    // MARK: - Derived display helpers

    private var displayArtistName: String {
        if let n = existingEntry?.artistName, !n.isEmpty { return n }
        if let n = festivalSet?.artist.name { return n }
        if let n = artist?.name { return n }
        return "Unknown Artist"
    }

    private var displayFestivalName: String {
        if let n = existingEntry?.festivalName, !n.isEmpty { return n }
        if let n = festival?.name { return n }
        return "Unknown Festival"
    }

    private var entryArtistID: UUID {
        existingEntry?.artistID ?? festivalSet?.artist.id ?? artist?.id ?? UUID()
    }

    private var entryFestivalID: UUID {
        existingEntry?.festivalID ?? festival?.id ?? UUID()
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    entryHeader

                    Divider()

                    // Rating
                    ratingSection

                    // Highlights
                    highlightSection

                    // Would see again
                    wouldSeeAgainSection

                    // Notes (collapsible)
                    notesSection

                    // Delete (edit mode only)
                    if existingEntry != nil {
                        Button(action: { showDeleteConfirm = true }) {
                            Text("Delete Entry")
                                .font(DS.Font.label)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.appSurface)
                                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, DS.Spacing.sectionGap)
                    }
                }
                .padding(DS.Spacing.pageMargin)
            }
            .background(Color.appBackground)
            .navigationTitle(existingEntry != nil ? "Edit Entry" : "Log This Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.appTextMuted)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveEntry() }
                        .font(DS.Font.listItem)
                        .foregroundColor(.appCTA)
                }
            }
            .confirmationDialog("Delete this entry?", isPresented: $showDeleteConfirm) {
                Button("Delete Entry", role: .destructive) {
                    if let e = existingEntry { journalStore.delete(e) }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    // MARK: - Subviews

    private var entryHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(displayArtistName)
                .font(DS.Font.cardTitle)
                .foregroundColor(.appTextPrimary)
            if let set = festivalSet {
                Text("\(set.stageName)  ·  \(set.day.fullName)")
                    .font(DS.Font.metadata)
                    .foregroundColor(.appTextMuted)
            } else {
                Text(displayFestivalName)
                    .font(DS.Font.metadata)
                    .foregroundColor(.appTextMuted)
            }
        }
    }

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Rating")
                .font(DS.Font.label)
                .foregroundColor(.appTextMuted)
                .textCase(.uppercase)
                .tracking(0.8)
            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { star in
                    Button(action: {
                        withAnimation(.spring(response: 0.2)) {
                            rating = (rating == star) ? 0 : star
                        }
                    }) {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(DS.Font.rating)
                            .foregroundColor(star <= rating ? DS.Journal.starFilled : DS.Journal.starEmpty)
                            .scaleEffect(star == rating ? 1.2 : 1.0)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var highlightSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Highlights")
                .font(DS.Font.label)
                .foregroundColor(.appTextMuted)
                .textCase(.uppercase)
                .tracking(0.8)
            FlowLayout(spacing: 8) {
                ForEach(presetHighlights, id: \.self) { tag in
                    highlightChip(tag)
                }
                Button(action: { showCustomHighlightField.toggle() }) {
                    Text("+ Add custom...")
                        .font(DS.Font.metadata)
                        .foregroundColor(.appAccent)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.appSurface)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            if showCustomHighlightField {
                HStack {
                    TextField("Custom highlight", text: $customHighlight)
                        .font(DS.Font.metadata)
                        .foregroundColor(.appTextPrimary)
                    Button("Add") {
                        let t = customHighlight.trimmingCharacters(in: .whitespaces)
                        if !t.isEmpty { selectedHighlights.insert(t) }
                        customHighlight = ""
                        showCustomHighlightField = false
                    }
                    .font(DS.Font.label)
                    .foregroundColor(.appCTA)
                }
                .padding(10)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
            }
        }
    }

    private func highlightChip(_ tag: String) -> some View {
        let isSelected = selectedHighlights.contains(tag)
        return Button(action: {
            if isSelected { selectedHighlights.remove(tag) }
            else { selectedHighlights.insert(tag) }
        }) {
            Text(tag)
                .font(DS.Font.metadata)
                .foregroundColor(isSelected ? Color.appBackground : .appTextMuted)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(isSelected ? Color.appCTA : Color.appSurface)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var wouldSeeAgainSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Would see again?")
                .font(DS.Font.label)
                .foregroundColor(.appTextMuted)
                .textCase(.uppercase)
                .tracking(0.8)
            HStack(spacing: 8) {
                ForEach([WouldSeeAgain.yes, .maybe, .no], id: \.self) { option in
                    Button(action: {
                        wouldSeeAgain = wouldSeeAgain == option ? nil : option
                    }) {
                        Text(option.rawValue.capitalized)
                            .font(DS.Font.label)
                            .foregroundColor(wouldSeeAgain == option ? Color.appBackground : .appTextMuted)
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .background(wouldSeeAgain == option ? Color.appCTA : Color.appSurface)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) { showNotes.toggle() }
            }) {
                HStack {
                    Text(showNotes ? "Notes" : "+ Add notes")
                        .font(DS.Font.label)
                        .foregroundColor(showNotes ? .appTextMuted : .appAccent)
                        .textCase(showNotes ? .uppercase : .none)
                        .tracking(showNotes ? 0.8 : 0)
                    Spacer()
                    if showNotes {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.appTextMuted)
                    }
                }
            }
            .buttonStyle(.plain)

            if showNotes {
                ZStack(alignment: .bottomTrailing) {
                    TextEditor(text: $notes)
                        .font(DS.Font.listItem)
                        .foregroundColor(.appTextPrimary)
                        .frame(minHeight: 100, maxHeight: 200)
                        .scrollContentBackground(.hidden)
                        .background(Color.appSurface)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
                        .onChange(of: notes) { newValue in
                            if newValue.count > 2000 {
                                notes = String(newValue.prefix(2000))
                            }
                        }
                    Text("\(notes.count)/2000")
                        .font(.system(size: 10))
                        .foregroundColor(Color.appTextMuted.opacity(0.5))
                        .padding(6)
                }
            }
        }
    }

    // MARK: - Save

    private func saveEntry() {
        let entry = JournalEntry(
            id: existingEntry?.id ?? UUID(),
            artistID: entryArtistID,
            festivalID: entryFestivalID,
            setID: existingEntry?.setID ?? (festivalSet?.id ?? UUID()),
            dateAttended: existingEntry?.dateAttended ?? Date(),
            rating: rating > 0 ? rating : nil,
            notes: showNotes ? notes : "",
            highlights: Array(selectedHighlights),
            wouldSeeAgain: wouldSeeAgain,
            artistName: displayArtistName,
            festivalName: displayFestivalName
        )
        journalStore.upsert(entry)
        dismiss()
    }
}

// MARK: - FlowLayout (simple tag wrap layout)

private struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
    }
}

#Preview {
    SetJournalEntryView(entry: JournalEntry.mockEntries[0])
        .environmentObject(JournalStore())
        .preferredColorScheme(.dark)
}
