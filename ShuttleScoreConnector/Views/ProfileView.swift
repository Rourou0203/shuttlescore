import SwiftUI

struct ProfileView: View {
    @StateObject private var profile = ProfileStore.shared
    @StateObject private var store = MatchHistoryStore.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Avatar section
                        VStack(spacing: 12) {
                            Image(profile.favoriteCat)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.orange, lineWidth: 3))
                                .shadow(color: .orange.opacity(0.3), radius: 10)

                            Text("羽毛球小将")
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 10)

                        // Stats row
                        HStack(spacing: 16) {
                            profileStat(title: "胜率", value: store.totalMatches > 0 ? "\(Int(store.winRate * 100))%" : "-")
                            divider
                            profileStat(title: "比赛数", value: "\(store.totalMatches)")
                            divider
                            profileStat(title: "总时长", value: formatMinutes(store.totalMinutes))
                        }
                        .padding()
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Favorite cat selection
                        VStack(alignment: .leading, spacing: 14) {
                            Text("本命猫")
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.white)

                            HStack(spacing: 20) {
                                ForEach(Array(zip(ProfileStore.availableCats, ProfileStore.catNames)), id: \.0) { cat, name in
                                    catSelector(cat: cat, name: name)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding()
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Additional stats
                        VStack(alignment: .leading, spacing: 14) {
                            Text("更多数据")
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.white)

                            detailRow(icon: "flame", title: "最长连胜", value: "\(store.longestWinStreak) 场")
                            detailRow(icon: "trophy", title: "总胜场", value: "\(store.totalWins) 场")
                            detailRow(icon: "sportscourt", title: "总比赛", value: "\(store.totalMatches) 场")
                        }
                        .padding()
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Version
                        Text("ShuttleScore v1.0")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.gray.opacity(0.5))
                            .padding(.top, 10)
                    }
                    .padding()
                }
            }
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear { store.refresh() }
        }
    }

    private func catSelector(cat: String, name: String) -> some View {
        let isSelected = profile.favoriteCat == cat
        return Button {
            withAnimation(.spring(response: 0.3)) {
                profile.favoriteCat = cat
            }
        } label: {
            VStack(spacing: 8) {
                Image(cat)
                    .resizable()
                    .scaledToFit()
                    .frame(width: isSelected ? 70 : 55, height: isSelected ? 70 : 55)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.orange : Color.gray.opacity(0.3), lineWidth: isSelected ? 3 : 1)
                    )
                    .shadow(color: isSelected ? .orange.opacity(0.4) : .clear, radius: 8)

                Text(name)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(isSelected ? .orange : .gray)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Image(systemName: "circle")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.3))
                }
            }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 1, height: 40)
    }

    private func profileStat(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundColor(.white)
            Text(title)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }

    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(.body, design: .rounded))
                .foregroundColor(.orange)
                .frame(width: 30)

            Text(title)
                .font(.system(.body, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            Text(value)
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundColor(.gray)
        }
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)分"
        }
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours)时\(mins)分"
    }
}

#Preview {
    ProfileView()
        .preferredColorScheme(.dark)
}
