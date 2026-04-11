import SwiftUI

struct OpponentPickerView: View {
    @Binding var selectedName: String
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var langMgr = WatchLanguageManager.shared
    @ObservedObject private var store = OpponentStore.shared
    @State private var inputName: String = ""

    /// Check Watch-side MatchStore for today's random buddy count
    private var nextBuddyNumber: Int {
        let prefix = langMgr.randomBuddy
        let hashPrefix = "\(prefix) #"
        let savedCount = store.opponents.filter { $0.hasPrefix(hashPrefix) }.count
        return savedCount + 1
    }

    var body: some View {
        List {
            // Quick random buddy button
            Section {
                Button {
                    let prefix = langMgr.randomBuddy
                    let name = "\(prefix) #\(nextBuddyNumber)"
                    store.add(name)
                    selectedName = name
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "dice.fill")
                            .foregroundStyle(.orange)
                        Text("\(langMgr.randomBuddy) #\(nextBuddyNumber)")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.orange)
                    }
                }
                .listRowBackground(Color.orange.opacity(0.15))
            }

            Section {
                HStack(spacing: 6) {
                    TextField(langMgr.opponentInputPlaceholder, text: $inputName)
                        .font(.system(.body, design: .rounded))
                    Button {
                        let trimmed = inputName.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        store.add(trimmed)
                        selectedName = trimmed
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.cyan)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text(langMgr.opponentNew)
                    .font(.system(.caption2, design: .rounded))
            }

            Section {
                if store.opponents.isEmpty {
                    Text(langMgr.opponentEmpty)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.gray)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(Array(store.opponents.enumerated()), id: \.offset) { index, name in
                        Button {
                            selectedName = name
                            dismiss()
                        } label: {
                            HStack {
                                Text(name)
                                    .font(.system(.body, design: .rounded))
                                    .foregroundStyle(.white)
                                Spacer()
                                if name == selectedName {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.orange)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet.sorted(by: >) {
                            store.remove(at: index)
                        }
                    }
                }
            } header: {
                Text(langMgr.opponentHistory)
                    .font(.system(.caption2, design: .rounded))
            }
        }
        .navigationTitle(langMgr.opponentTitle)
    }
}
