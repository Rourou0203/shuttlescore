import Foundation
import SwiftUI

class ProfileStore: ObservableObject {
    static let shared = ProfileStore()

    private let favCatKey = "favorite_cat"

    @Published var favoriteCat: String {
        didSet {
            UserDefaults.standard.set(favoriteCat, forKey: favCatKey)
        }
    }

    @Published var username: String {
        didSet {
            UserDefaults.standard.set(username, forKey: "user_name")
        }
    }

    @Published var customAvatarData: Data? {
        didSet {
            if let data = customAvatarData {
                UserDefaults.standard.set(data, forKey: "user_avatar")
            } else {
                UserDefaults.standard.removeObject(forKey: "user_avatar")
            }
        }
    }

    var avatarImage: UIImage? {
        guard let data = customAvatarData else { return nil }
        return UIImage(data: data)
    }

    static let availableCats = ["cat_orange", "cat_robe", "cat_scarf"]
    static let catNames = ["橘猫", "长袍猫", "围巾猫"]

    init() {
        self.favoriteCat = UserDefaults.standard.string(forKey: favCatKey) ?? "cat_orange"
        self.username = UserDefaults.standard.string(forKey: "user_name") ?? "羽毛球小将"
        self.customAvatarData = UserDefaults.standard.data(forKey: "user_avatar")
    }
}

// MARK: - Unified avatar view that uses custom avatar for team A when available

struct TeamAvatarView: View {
    let isTeamA: Bool
    let size: CGFloat

    var body: some View {
        if isTeamA, let uiImage = ProfileStore.shared.avatarImage {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            Image(isTeamA ? "cat_orange" : "cat_robe")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(Circle())
        }
    }
}
