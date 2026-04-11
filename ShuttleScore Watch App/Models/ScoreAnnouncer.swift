import Foundation
import AVFoundation

class ScoreAnnouncer {
    static let shared = ScoreAnnouncer()

    private let synthesizer = AVSpeechSynthesizer()

    private init() {}

    /// Announce the current score after a point is scored.
    /// - Parameters:
    ///   - scoreA: Team A's current score
    ///   - scoreB: Team B's current score
    ///   - servingTeamIsA: Whether team A is currently serving
    ///   - serviceChanged: Whether the serve just changed hands
    func announce(scoreA: Int, scoreB: Int, servingTeamIsA: Bool, serviceChanged: Bool) {
        let lang = WatchLanguageManager.shared.language
        let text: String
        let locale: String

        let servingScore = servingTeamIsA ? scoreA : scoreB
        let receivingScore = servingTeamIsA ? scoreB : scoreA

        if lang == "zh" {
            let base = "\(chineseNumber(servingScore))比\(chineseNumber(receivingScore))"
            text = serviceChanged ? "\(base)，换发球" : base
            locale = "zh-CN"
        } else {
            let base = "\(servingScore) serving \(receivingScore)"
            text = serviceChanged ? "\(base), service over" : base
            locale = "en-US"
        }

        // Stop any ongoing speech before announcing new score
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: locale)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.8

        synthesizer.speak(utterance)
    }

    // MARK: - Chinese Number Helpers

    private func chineseNumber(_ n: Int) -> String {
        let digits = ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
        if n <= 10 { return digits[n] }
        if n < 20 { return "十\(digits[n - 10])" }
        let tens = n / 10
        let ones = n % 10
        if ones == 0 { return "\(digits[tens])十" }
        return "\(digits[tens])十\(digits[ones])"
    }
}
