import SwiftUI

struct OpponentPickerView: View {
    @Binding var selectedName: String
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = OpponentStore.shared
    @State private var inputName: String = ""

    var body: some View {
        List {
            Section {
                HStack(spacing: 6) {
                    TextField("输入名字", text: $inputName)
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
                Text("新对手")
                    .font(.system(.caption2, design: .rounded))
            }

            Section {
                if store.opponents.isEmpty {
                    Text("还没有对手记录，打完比赛后自动保存")
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
                Text("历史对手")
                    .font(.system(.caption2, design: .rounded))
            }
        }
        .navigationTitle("选择对手")
    }
}
