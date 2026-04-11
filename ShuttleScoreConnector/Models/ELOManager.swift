import Foundation
import SwiftUI

class ELOManager: ObservableObject {
    static let shared = ELOManager()

    private let myRatingKey = "elo_my_rating"
    private let opponentRatingsKey = "elo_opponent_ratings"
    private let kFactor: Double = 32

    @Published var myRating: Int = 1000
    @Published var opponentRatings: [String: Int] = [:]

    private init() {
        myRating = UserDefaults.standard.integer(forKey: myRatingKey)
        if myRating == 0 { myRating = 1000 }

        if let data = UserDefaults.standard.data(forKey: opponentRatingsKey),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            opponentRatings = decoded
        }
    }

    // MARK: - Recalculate from scratch

    /// Recalculate all ELO ratings from match history in chronological order
    func recalculateAll(from records: [MatchRecord]) {
        // Reset
        var myR: Double = 1000
        var oppR: [String: Double] = [:]

        // Sort chronologically (oldest first)
        let sorted = records.sorted { $0.startTime < $1.startTime }

        for record in sorted {
            let opponent = record.teamBName
            let rb = oppR[opponent] ?? 1000

            // Expected win probability
            let ea = 1.0 / (1.0 + pow(10.0, (rb - myR) / 400.0))
            let eb = 1.0 - ea

            // Actual result: 1 = win, 0 = loss
            let sa: Double = record.teamAWon ? 1.0 : 0.0
            let sb: Double = 1.0 - sa

            // Update ratings
            myR += kFactor * (sa - ea)
            let newOppR = rb + kFactor * (sb - eb)
            oppR[opponent] = newOppR
        }

        // Persist
        myRating = Int(round(myR))
        opponentRatings = oppR.mapValues { Int(round($0)) }
        save()
    }

    // MARK: - Rating Tier

    func ratingTier(for rating: Int) -> String {
        let lang = LanguageManager.shared
        if rating < 900 { return lang.eloBronze }
        if rating < 1100 { return lang.eloSilver }
        if rating < 1300 { return lang.eloGold }
        if rating < 1500 { return lang.eloPlatinum }
        return lang.eloDiamond
    }

    func tierColor(for rating: Int) -> Color {
        if rating < 900 { return Color(red: 0.8, green: 0.5, blue: 0.2) }   // Bronze
        if rating < 1100 { return Color(red: 0.75, green: 0.75, blue: 0.8) } // Silver
        if rating < 1300 { return Color(red: 1.0, green: 0.84, blue: 0.0) }  // Gold
        if rating < 1500 { return Color(red: 0.9, green: 0.9, blue: 1.0) }   // Platinum
        return Color(red: 0.7, green: 0.9, blue: 1.0)                        // Diamond
    }

    func tierIcon(for rating: Int) -> String {
        if rating < 900 { return "shield" }
        if rating < 1100 { return "shield.fill" }
        if rating < 1300 { return "star.fill" }
        if rating < 1500 { return "crown" }
        return "crown.fill"
    }

    // MARK: - Persistence

    private func save() {
        UserDefaults.standard.set(myRating, forKey: myRatingKey)
        if let data = try? JSONEncoder().encode(opponentRatings) {
            UserDefaults.standard.set(data, forKey: opponentRatingsKey)
        }
    }
}
