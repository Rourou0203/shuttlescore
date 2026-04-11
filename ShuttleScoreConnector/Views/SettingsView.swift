import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var languageManager = LanguageManager.shared

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Text(languageManager.settingsTitle)
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.gray)
                    }
                }
                .padding(16)

                ScrollView {
                    VStack(spacing: 16) {
                        // Language setting
                        VStack(alignment: .leading, spacing: 12) {
                            Text(languageManager.settingsLanguage)
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.white)

                            VStack(spacing: 8) {
                                languageOption(label: languageManager.settingsFollowSystem, tag: "system", isSelected: languageManager.currentLanguage == "system")
                                languageOption(label: languageManager.settingsChinese, tag: "zh-Hans", isSelected: languageManager.currentLanguage == "zh-Hans")
                                languageOption(label: languageManager.settingsEnglish, tag: "en", isSelected: languageManager.currentLanguage == "en")
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    private func languageOption(label: String, tag: String, isSelected: Bool) -> some View {
        Button(action: {
            languageManager.currentLanguage = tag
        }) {
            HStack {
                Text(label)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 18))
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.orange.opacity(0.15) : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    SettingsView()
}
