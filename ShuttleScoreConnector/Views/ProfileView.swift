import SwiftUI
import PhotosUI

struct ProfileView: View {
    @StateObject private var profile = ProfileStore.shared
    @StateObject private var store = MatchHistoryStore.shared
    @StateObject private var eloManager = ELOManager.shared
    @ObservedObject private var languageManager = LanguageManager.shared

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var showSettings = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Text(languageManager.profileTitle)
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gearshape.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.orange)
                        }
                    }

                    // Avatar + name
                    VStack(spacing: 8) {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            ZStack(alignment: .bottomTrailing) {
                                if let uiImage = profile.avatarImage {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 90, height: 90)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.orange, lineWidth: 3))
                                        .shadow(color: .orange.opacity(0.3), radius: 8)
                                } else {
                                    Image(profile.favoriteCat)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 90, height: 90)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.orange, lineWidth: 3))
                                        .shadow(color: .orange.opacity(0.3), radius: 8)
                                }

                                // Camera badge
                                Image(systemName: "camera.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.orange)
                                    .background(Circle().fill(Color.black).frame(width: 20, height: 20))
                            }
                        }
                        .onChange(of: selectedPhoto) { _, item in
                            Task {
                                if let data = try? await item?.loadTransferable(type: Data.self) {
                                    // Compress to reasonable size for UserDefaults
                                    if let uiImage = UIImage(data: data),
                                       let compressed = uiImage.jpegData(compressionQuality: 0.6) {
                                        profile.customAvatarData = compressed
                                    } else {
                                        profile.customAvatarData = data
                                    }
                                }
                            }
                        }

                        // Reset avatar button
                        if profile.customAvatarData != nil {
                            Button {
                                profile.customAvatarData = nil
                            } label: {
                                Label(languageManager.profileResetAvatar, systemImage: "arrow.uturn.backward")
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundColor(.gray)
                            }
                        }

                        // Editable username
                        Button {
                            editedName = profile.username
                            isEditingName = true
                        } label: {
                            HStack(spacing: 4) {
                                Text(profile.username)
                                    .font(.system(.title3, design: .rounded, weight: .bold))
                                    .foregroundColor(.white)
                                Image(systemName: "pencil")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .alert(languageManager.profileAlertTitle, isPresented: $isEditingName) {
                        TextField("输入昵称", text: $editedName)
                        Button(languageManager.profileCancel, role: .cancel) {}
                        Button(languageManager.profileConfirm) {
                            let trimmed = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty {
                                profile.username = trimmed
                            }
                        }
                    } message: {
                        Text(languageManager.profileAlertMessage)
                    }

                    // Stats row
                    HStack(spacing: 16) {
                        profileStat(title: languageManager.profileStatWinRate, value: store.totalMatches > 0 ? "\(Int(store.winRate * 100))%" : "-")
                        divider
                        profileStat(title: languageManager.profileStatMatches, value: "\(store.totalMatches)")
                        divider
                        profileStat(title: languageManager.profileStatDuration, value: formatMinutes(store.totalMinutes))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // ELO Rating card
                    HStack(spacing: 12) {
                        Image(systemName: eloManager.tierIcon(for: eloManager.myRating))
                            .font(.system(size: 28))
                            .foregroundColor(eloManager.tierColor(for: eloManager.myRating))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(languageManager.eloRating)
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.gray)
                            Text("\(eloManager.myRating)")
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundColor(.white)
                        }

                        Spacer()

                        Text(eloManager.ratingTier(for: eloManager.myRating))
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundColor(eloManager.tierColor(for: eloManager.myRating))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(eloManager.tierColor(for: eloManager.myRating).opacity(0.15))
                            .clipShape(Capsule())
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Favorite cat selection
                    VStack(alignment: .leading, spacing: 10) {
                        Text(languageManager.profileFavoriteCat)
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.white)

                        HStack(spacing: 16) {
                            ForEach(Array(zip(ProfileStore.availableCats, ProfileStore.catNames)), id: \.0) { cat, name in
                                catSelector(cat: cat, name: name)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Additional stats
                    VStack(alignment: .leading, spacing: 14) {
                        Text(languageManager.profileMoreData)
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.white)

                        detailRow(icon: "flame", title: languageManager.profileLongestWinStreak, value: "\(store.longestWinStreak) 场")
                        detailRow(icon: "trophy", title: languageManager.profileTotalWins, value: "\(store.totalWins) 场")
                        detailRow(icon: "sportscourt", title: languageManager.profileTotalMatches, value: "\(store.totalMatches) 场")
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    Text("ShuttleScore v1.0")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(.top, 4)
                }
                .padding(.horizontal, 16)
            }
        }
        .onAppear {
            store.refresh()
            eloManager.recalculateAll(from: store.records)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    private func catSelector(cat: String, name: String) -> some View {
        let isSelected = profile.favoriteCat == cat
        return Button {
            withAnimation(.spring(response: 0.3)) {
                profile.favoriteCat = cat
            }
        } label: {
            VStack(spacing: 6) {
                Image(cat)
                    .resizable()
                    .scaledToFit()
                    .frame(width: isSelected ? 60 : 50, height: isSelected ? 60 : 50)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.orange : Color.gray.opacity(0.3), lineWidth: isSelected ? 3 : 1)
                    )
                    .shadow(color: isSelected ? .orange.opacity(0.4) : .clear, radius: 6)
                Text(name)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(isSelected ? .orange : .gray)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.caption2)
                    .foregroundColor(isSelected ? .orange : .gray.opacity(0.3))
            }
        }
    }

    private var divider: some View {
        Rectangle().fill(Color.gray.opacity(0.3)).frame(width: 1, height: 36)
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
                .font(.system(.callout, design: .rounded))
                .foregroundColor(.orange)
                .frame(width: 28)
            Text(title)
                .font(.system(.callout, design: .rounded))
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .font(.system(.callout, design: .rounded, weight: .medium))
                .foregroundColor(.gray)
        }
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes)分" }
        return "\(minutes / 60)时\(minutes % 60)分"
    }
}

#Preview {
    ProfileView()
        .preferredColorScheme(.dark)
}
