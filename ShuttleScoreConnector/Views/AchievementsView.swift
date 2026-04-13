import SwiftUI

struct AchievementsView: View {
    @StateObject private var store = MatchHistoryStore.shared
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var achievements: [Achievement] = []

    private var bronzeAchievements: [Achievement] {
        achievements.filter { $0.tier == .bronze }
    }
    private var silverAchievements: [Achievement] {
        achievements.filter { $0.tier == .silver }
    }
    private var goldAchievements: [Achievement] {
        achievements.filter { $0.tier == .gold }
    }

    var body: some View {
        ZStack {
            Color.brandBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    Text(languageManager.achievementsTitle)
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Header
                    VStack(spacing: 8) {
                        TeamAvatarView(isTeamA: true, size: 100)
                            .overlay(Circle().stroke(Color.orange.opacity(0.5), lineWidth: 2))

                        let unlocked = achievements.filter(\.isUnlocked).count
                        Text("\(unlocked) / \(achievements.count)")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundColor(.white)

                        Text(languageManager.achievementsUnlocked)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.brandSecondary)
                    }
                    .frame(maxWidth: .infinity)

                    // Tier sections
                    tierSection(
                        title: languageManager.achievementBronze,
                        achievements: bronzeAchievements,
                        tier: .bronze
                    )

                    tierSection(
                        title: languageManager.achievementSilver,
                        achievements: silverAchievements,
                        tier: .silver
                    )

                    tierSection(
                        title: languageManager.achievementGold,
                        achievements: goldAchievements,
                        tier: .gold
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .onAppear {
            store.refresh()
            achievements = AchievementManager.evaluate(with: store)
        }
    }

    @ViewBuilder
    private func tierSection(title: String, achievements: [Achievement], tier: AchievementTier) -> some View {
        let unlocked = achievements.filter(\.isUnlocked).count

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: tierIcon(for: tier))
                    .foregroundColor(tierColor(for: tier))
                    .font(.system(.body, design: .rounded, weight: .semibold))

                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(tierColor(for: tier))

                Spacer()

                Text("\(unlocked)/\(achievements.count)")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundColor(.brandSecondary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(achievements) { achievement in
                    AchievementCard(achievement: achievement)
                }
            }
        }
    }

    private func tierIcon(for tier: AchievementTier) -> String {
        switch tier {
        case .bronze: return "shield"
        case .silver: return "shield.fill"
        case .gold: return "crown.fill"
        }
    }

    private func tierColor(for tier: AchievementTier) -> Color {
        switch tier {
        case .bronze: return Color(red: 0.8, green: 0.5, blue: 0.2)
        case .silver: return Color(red: 0.75, green: 0.75, blue: 0.78)
        case .gold: return Color(red: 1.0, green: 0.84, blue: 0)
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    @ObservedObject private var languageManager = LanguageManager.shared

    private var tierColor: Color {
        switch achievement.tier {
        case .bronze: return Color(red: 0.8, green: 0.5, blue: 0.2)
        case .silver: return Color(red: 0.75, green: 0.75, blue: 0.78)
        case .gold: return Color(red: 1.0, green: 0.84, blue: 0)
        }
    }

    private var progressFraction: Double {
        guard achievement.maxProgress > 0 else { return 0 }
        return Double(achievement.currentProgress) / Double(achievement.maxProgress)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Icon
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? tierColor.opacity(0.15) : Color.white.opacity(0.04))
                    .frame(width: 52, height: 52)

                Image(systemName: achievement.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(achievement.isUnlocked ? tierColor : .brandSecondary.opacity(0.4))

                if !achievement.isUnlocked {
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 52, height: 52)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.brandSecondary.opacity(0.6))
                }
            }

            // Title
            Text(languageManager.language == "zh" ? achievement.title : achievement.titleEn)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundColor(achievement.isUnlocked ? .white : .brandSecondary)
                .lineLimit(1)

            // Description
            Text(languageManager.language == "zh" ? achievement.description : achievement.descriptionEn)
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundColor(.brandSecondary.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(minHeight: 24)

            // Progress bar
            VStack(spacing: 3) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))

                        Capsule()
                            .fill(achievement.isUnlocked ? tierColor : tierColor.opacity(0.5))
                            .frame(width: geometry.size.width * progressFraction)
                    }
                }
                .frame(height: 4)

                Text("\(achievement.currentProgress)/\(achievement.maxProgress)")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(achievement.isUnlocked ? tierColor : .brandSecondary.opacity(0.5))
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .background(
            achievement.isUnlocked
                ? tierColor.opacity(0.08)
                : Color.white.opacity(0.03)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    achievement.isUnlocked ? tierColor.opacity(0.4) : Color.white.opacity(0.06),
                    lineWidth: achievement.isUnlocked ? 1.5 : 0.5
                )
        )
        .shadow(
            color: achievement.isUnlocked ? tierColor.opacity(0.15) : .clear,
            radius: 6, x: 0, y: 2
        )
    }
}

#Preview {
    AchievementsView()
        .preferredColorScheme(.dark)
}
