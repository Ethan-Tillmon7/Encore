// Encore/Views/Journal/SetJournalEntryView.swift
import SwiftUI

struct SetJournalEntryView: View {

    @EnvironmentObject var journalStore: JournalStore
    @Environment(\.dismiss) private var dismiss

    // If editing an existing entry
    let existingEntry: JournalEntry?
    // Set context (optional — may not be known in "create from journal" flow)
    let festivalSet: FestivalSet?

    @State private var rating: Int = 0
    @State private var notes: String = ""
    @State private var selectedHighlights: Set<String> = []
    @State private var customHighlight: String = ""
    @State private var showCustomHighlightField = false
    @State private var wouldSeeAgain: WouldSeeAgain? = nil
    @State private var attended: Bool = true
    @State private var showDeleteConfirm = false

    private let presetHighlights = [
        "Best energy", "Surprise guest", "Perfect setlist", "Great crowd",
        "Emotional moment", "Technical issues", "Too crowded", "Discovered a new fave"
    ]

    // Convenience init for editing
    init(entry: JournalEntry) {
        self.existingEntry = entry
        self.festivalSet = nil
        self._rating = State(initialValue: entry.rating ?? 0)
        self._notes = State(initialValue: entry.notes)
        self._selectedHighlights = State(initialValue: Set(entry.highlights))
        self._wouldSeeAgain = State(initialValue: entry.wouldSeeAgain)
        self._attended = State(initialValue: true)
    }

    // Convenience init for creating
    init(festivalSet: FestivalSet?, existingEntry: JournalEntry?) {
        self.festivalSet = festivalSet
        self.existingEntry = existingEntry
        if let e = existingEntry {
            self._rating = State(initialValue: e.rating ?? 0)
            self._notes = State(initialValue: e.notes)
            self._selectedHighlights = State(initialValue: Set(e.highlights))
            self._wouldSeeAgain = State(initialValue: e.wouldSeeAgain)
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Artist + Set header
                    if let set = festivalSet {
                        artistHeader(set: set)
                    } else if let entry = existingEntry {
                        existingEntryHeader(entry: entry)
                    }

                    Divider()

                    // Attendance toggle
                    attendanceToggle

                    if attended {
                        // Rating
                        ratingSection

                        // Highlights
                        highlightSection

                        // Notes
                        notesSection

                        // Would see again
                        wouldSeeAgainSection
                    }

                    // Delete button (edit mode only)
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
                .opacity(attended ? 1 : 0.5)
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

    private func artistHeader(set: FestivalSet) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(set.artist.name)
                .font(DS.Font.cardTitle)
                .foregroundColor(.appTextPrimary)
            Text("\(set.stageName)  ·  \(set.day.fullName)")
                .font(DS.Font.metadata)
                .foregroundColor(.appTextMuted)
        }
    }

    private func existingEntryHeader(entry: JournalEntry) -> some View {
        let name = Artist.mockLineup.first(where: { $0.id == entry.artistID })?.name ?? "Unknown"
        return VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(DS.Font.cardTitle)
                .foregroundColor(.appTextPrimary)
            Text(formattedDate(entry.dateAttended))
                .font(DS.Font.metadata)
                .foregroundColor(.appTextMuted)
        }
    }

    private var attendanceToggle: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Did you see this set?")
                    .font(DS.Font.listItem)
                    .foregroundColor(.appTextPrimary)
                if !attended {
                    Text("Entry will be saved as missed.")
                        .font(DS.Font.metadata)
                        .foregroundColor(.appTextMuted)
                }
            }
            Spacer()
            Toggle("", isOn: $attended)
                .tint(.appCTA)
                .labelsHidden()
        }
        .padding(DS.Spacing.cardPadding)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
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

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(DS.Font.label)
                .foregroundColor(.appTextMuted)
                .textCase(.uppercase)
                .tracking(0.8)
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

    // MARK: - Save

    private func saveEntry() {
        let entry = JournalEntry(
            id: existingEntry?.id ?? UUID(),
            artistID: existingEntry?.artistID ?? (festivalSet?.artist.id ?? UUID()),
            festivalID: existingEntry?.festivalID ?? UUID(),
            setID: existingEntry?.setID ?? (festivalSet?.id ?? UUID()),
            dateAttended: existingEntry?.dateAttended ?? Date(),
            rating: attended && rating > 0 ? rating : nil,
            notes: attended ? notes : "",
            highlights: attended ? Array(selectedHighlights) : [],
            wouldSeeAgain: attended ? wouldSeeAgain : nil
        )
        journalStore.upsert(entry)
        dismiss()
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
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
