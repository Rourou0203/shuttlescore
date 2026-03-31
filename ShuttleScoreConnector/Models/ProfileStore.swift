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

    static let availableCats = ["cat_orange", "cat_robe", "cat_scarf"]
    static let catNames = ["橘猫", "长袍猫", "围巾猫"]

    init() {
        self.favoriteCat = UserDefaults.standard.string(forKey: favCatKey) ?? "cat_orange"
    }
}
