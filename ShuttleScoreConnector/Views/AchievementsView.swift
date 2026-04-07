import SwiftUI

struct AchievementsView: View {
    @StateObject private var store = MatchHistoryStore.shared
    @State private var achievements: [Achievement] = []

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    Text("成就")
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

                        Text("已解锁成就")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)

                    // Achievement grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(achievements) { achievement in
                            AchievementCard(achievement: achievement)
                        }
                    }
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
}

struct AchievementCard: View {
    let achievement: Achievement

    private var catImage: String {
        switch achievement.id {
        case "first_match": return "cat_orange"
        case "gold_cat": return "cat_orange"
        case "win_streak": return "cat_robe"
        case "flash_win": return "cat_scarf"
        case "legend": return "cat_orange"
        default: return "cat_orange"
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Image(catImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .saturation(achievement.isUnlocked ? 1 : 0)
                    .opacity(achievement.isUnlocked ? 1 : 0.3)

                if !achievement.isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.gray)
                }
            }

            Image(systemName: achievement.icon)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(achievement.isUnlocked ? .yellow : .gray)

            Text(achievement.title)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundColor(achievement.isUnlocked ? .white : .gray)

            Text(achievement.description)
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(
            achievement.isUnlocked
                ? Color.orange.opacity(0.1)
                : Color.white.opacity(0.04)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    achievement.isUnlocked ? Color.orange.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
    }
}

#Preview {
    AchievementsView()
        .preferredColorScheme(.dark)
}
