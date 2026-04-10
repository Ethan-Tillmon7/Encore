// Encore/Views/Profile/TravelDetailsView.swift
import SwiftUI

struct TravelDetailsView: View {

    let festivalID: UUID

    @EnvironmentObject var festivalStore: FestivalStore
    @Environment(\.dismiss) private var dismiss

    @State private var details: TravelDetails
    @State private var newItemName = ""
    @State private var newItemCategory = "Gear"
    @State private var showAddItem = false
    @State private var newExpenseDesc = ""
    @State private var newExpenseAmount = ""
    @State private var newExpensePaidBy = "Me"
    @State private var showAddExpense = false

    private let transportOptions  = ["Car", "Flight", "Bus", "Other"]
    private let accommodationOptions = ["Tent", "RV", "Hotel", "Other"]
    private let categories = ["Gear", "Clothing", "Food", "Docs"]

    init(festivalID: UUID) {
        self.festivalID = festivalID
        self._details = State(initialValue: TravelDetails(
            festivalID: festivalID,
            packingItems: [],
            expenses: []
        ))
    }

    var body: some View {
        NavigationView {
            List {
                // Trip Overview
                Section("Trip Overview") {
                    DatePicker("Arrival", selection: Binding(
                        get: { details.arrivalDate ?? Date() },
                        set: { details.arrivalDate = $0 }
                    ), displayedComponents: .date)
                    .foregroundColor(.appTextPrimary)

                    DatePicker("Departure", selection: Binding(
                        get: { details.departureDate ?? Date() },
                        set: { details.departureDate = $0 }
                    ), displayedComponents: .date)
                    .foregroundColor(.appTextPrimary)

                    Picker("Transport", selection: Binding(
                        get: { details.transportMode ?? "Car" },
                        set: { details.transportMode = $0 }
                    )) {
                        ForEach(transportOptions, id: \.self) { Text($0) }
                    }
                    .foregroundColor(.appTextPrimary)

                    Picker("Accommodation", selection: Binding(
                        get: { details.accommodationType ?? "Tent" },
                        set: { details.accommodationType = $0 }
                    )) {
                        ForEach(accommodationOptions, id: \.self) { Text($0) }
                    }
                    .foregroundColor(.appTextPrimary)

                    HStack {
                        Text("Campsite")
                            .foregroundColor(.appTextPrimary)
                        Spacer()
                        TextField("e.g. Row G", text: Binding(
                            get: { details.campsite ?? "" },
                            set: { details.campsite = $0.isEmpty ? nil : $0 }
                        ))
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.appTextMuted)
                    }
                }
                .listRowBackground(Color.appSurface)

                // Packing List
                Section {
                    ForEach($details.packingItems) { $item in
                        HStack {
                            Toggle(isOn: $item.isPacked) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(DS.Font.listItem)
                                        .foregroundColor(item.isPacked ? .appTextMuted : .appTextPrimary)
                                        .strikethrough(item.isPacked)
                                    Text(item.category)
                                        .font(DS.Font.caps)
                                        .foregroundColor(.appTextMuted)
                                }
                            }
                            .tint(.appCTA)
                        }
                    }
                    .onDelete { details.packingItems.remove(atOffsets: $0) }

                    if showAddItem {
                        HStack {
                            TextField("Item name", text: $newItemName)
                                .font(DS.Font.listItem)
                            Picker("", selection: $newItemCategory) {
                                ForEach(categories, id: \.self) { Text($0) }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 80)
                            Button("Add") {
                                let t = newItemName.trimmingCharacters(in: .whitespaces)
                                if !t.isEmpty {
                                    details.packingItems.append(PackingItem(id: UUID(), name: t, isPacked: false, category: newItemCategory))
                                }
                                newItemName = ""
                                showAddItem = false
                            }
                            .foregroundColor(.appCTA)
                        }
                    }

                    Button("+ Add item") { showAddItem.toggle() }
                        .font(DS.Font.metadata)
                        .foregroundColor(.appCTA)

                    Button("Load Bonnaroo defaults") {
                        let existing = Set(details.packingItems.map(\.name))
                        let toAdd = PackingItem.bonnarooDefaults.filter { !existing.contains($0.name) }
                        details.packingItems.append(contentsOf: toAdd)
                    }
                    .font(DS.Font.metadata)
                    .foregroundColor(.appAccent)
                } header: {
                    Text("Packing List (\(details.packingItems.filter(\.isPacked).count)/\(details.packingItems.count) packed)")
                }
                .listRowBackground(Color.appSurface)

                // Expenses
                Section {
                    ForEach(details.expenses) { expense in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(expense.description)
                                    .font(DS.Font.listItem)
                                    .foregroundColor(.appTextPrimary)
                                Text("Paid by \(expense.paidBy)")
                                    .font(DS.Font.caps)
                                    .foregroundColor(.appTextMuted)
                            }
                            Spacer()
                            Text(String(format: "$%.2f", expense.amount))
                                .font(DS.Font.listItem)
                                .foregroundColor(.appTextPrimary)
                        }
                    }
                    .onDelete { details.expenses.remove(atOffsets: $0) }

                    if showAddExpense {
                        VStack(spacing: 8) {
                            TextField("Description", text: $newExpenseDesc)
                            HStack {
                                TextField("Amount", text: $newExpenseAmount)
                                    .keyboardType(.decimalPad)
                                TextField("Paid by", text: $newExpensePaidBy)
                            }
                            Button("Add Expense") {
                                let desc = newExpenseDesc.trimmingCharacters(in: .whitespaces)
                                let amt  = Double(newExpenseAmount) ?? 0
                                if !desc.isEmpty {
                                    details.expenses.append(ExpenseItem(id: UUID(), description: desc, amount: amt, paidBy: newExpensePaidBy, date: Date()))
                                }
                                newExpenseDesc = ""; newExpenseAmount = ""; newExpensePaidBy = "Me"
                                showAddExpense = false
                            }
                            .foregroundColor(.appCTA)
                        }
                        .font(DS.Font.listItem)
                    }

                    Button("+ Add expense") { showAddExpense.toggle() }
                        .font(DS.Font.metadata)
                        .foregroundColor(.appCTA)

                } header: {
                    let total = details.expenses.reduce(0) { $0 + $1.amount }
                    Text(String(format: "Expenses · Total $%.2f", total))
                }
                .listRowBackground(Color.appSurface)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Travel Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.appTextMuted)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        festivalStore.saveTravelDetails(details, for: festivalID)
                        dismiss()
                    }
                    .font(DS.Font.listItem)
                    .foregroundColor(.appCTA)
                }
            }
            .onAppear {
                if let saved = festivalStore.travelDetails[festivalID] {
                    details = saved
                }
            }
        }
    }
}

#Preview {
    let festivals = FestivalStore()
    festivals.festivals = Festival.mockFestivals
    return TravelDetailsView(festivalID: UUID())
        .environmentObject(festivals)
        .preferredColorScheme(.dark)
}
