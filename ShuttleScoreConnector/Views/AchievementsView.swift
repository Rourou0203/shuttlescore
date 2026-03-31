import SwiftUI

struct AchievementsView: View {
    @StateObject private var store = MatchHistoryStore.shared
    @State private var achievements: [Achievement] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Header
                        VStack(spacing: 8) {
                            Image("cat_orange")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.orange.opacity(0.5), lineWidth: 2))

                            let unlocked = achievements.filter(\.isUnlocked).count
                            Text("\(unlocked) / \(achievements.count)")
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundColor(.white)

                            Text("已解锁成就")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 10)

                        // Achievement grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            ForEach(achievements) { achievement in
                                AchievementCard(achievement: achievement)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("成就")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                store.refresh()
                achievements = AchievementManager.evaluate(with: store)
            }
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
                    .frame(width: 50, height: 50)
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
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
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
