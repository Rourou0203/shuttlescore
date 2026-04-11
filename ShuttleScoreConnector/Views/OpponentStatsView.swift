import SwiftUI

// MARK: - Data Model

struct OpponentStat: Identifiable {
    var id: String { opponentName }
    var opponentName: String
    var totalMatches: Int
    var wins: Int
    var losses: Int
    var winRate: Double
    var recentResults: [Bool]  // last 5 results (true = win)
    var lastPlayedDate: Date
    var matchRecords: [MatchRecord]
}

// MARK: - Sort Option

enum OpponentSortOption: String, CaseIterable {
    case matches
    case winRate
    case recent
}

// MARK: - Opponent Stats View

struct OpponentStatsView: View {
    @StateObject private var store = MatchHistoryStore.shared
    @StateObject private var opponentStore = PhoneOpponentStore.shared
    @StateObject private var eloManager = ELOManager.shared
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var expandedOpponent: String?
    @State private var newOpponentName: String = ""
    @State private var sortOption: OpponentSortOption = .matches

    private var opponentStats: [OpponentStat] {
        let grouped = Dictionary(grouping: store.records) { $0.teamBName }

        let stats = grouped.map { name, records in
            let wins = records.filter { $0.teamAWon }.count
            let losses = records.count - wins
            let winRate = records.isEmpty ? 0 : Double(wins) / Double(records.count)

            let sorted = records.sorted { $0.startTime > $1.startTime }
            let recent = Array(sorted.prefix(5).map { $0.teamAWon })

            return OpponentStat(
                opponentName: name,
                totalMatches: records.count,
                wins: wins,
                losses: losses,
                winRate: winRate,
                recentResults: recent,
                lastPlayedDate: sorted.first?.startTime ?? Date(),
                matchRecords: sorted
            )
        }

        // Apply sorting
        switch sortOption {
        case .matches:
            return stats.sorted { $0.totalMatches > $1.totalMatches }
        case .winRate:
            return stats.sorted { $0.winRate > $1.winRate }
        case .recent:
            return stats.sorted { $0.lastPlayedDate > $1.lastPlayedDate }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        Text(languageManager.opponentsTitle)
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // MARK: - Add opponent
                        VStack(spacing: 10) {
                            HStack(spacing: 10) {
                                TextField(languageManager.opponentsEnterName, text: $newOpponentName)
                                    .textFieldStyle(.plain)
                                    .font(.system(.body, design: .rounded))
                                    .padding(10)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .foregroundColor(.white)

                                // Random buddy button
                                Button(action: generateRandomBuddy) {
                                    Image(systemName: "dice.fill")
                                        .font(.system(.body))
                                        .foregroundColor(.black)
                                        .padding(10)
                                        .background(Color.orange)
                                        .clipShape(Circle())
                                }

                                Button(action: {
                                    opponentStore.add(newOpponentName)
                                    newOpponentName = ""
                                }) {
                                    Text(languageManager.opponentsAdd)
                                        .font(.system(.subheadline, design: .rounded))
                                        .fontWeight(.medium)
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(Color.orange)
                                        .clipShape(Capsule())
                                }
                                .disabled(newOpponentName.trimmingCharacters(in: .whitespaces).isEmpty)
                                .opacity(newOpponentName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                            }

                            // Saved opponents list
                            if !opponentStore.opponents.isEmpty {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(languageManager.opponentsSaved)
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundColor(.gray)
                                        .padding(.bottom, 6)

                                    ForEach(Array(opponentStore.opponents.enumerated()), id: \.offset) { index, name in
                                        HStack {
                                            Image(systemName: "person.fill")
                                                .font(.caption)
                                                .foregroundColor(.cyan.opacity(0.7))
                                            Text(name)
                                                .font(.system(.subheadline, design: .rounded))
                                                .foregroundColor(.white)
                                            Spacer()
                                            Button(action: {
                                                withAnimation { opponentStore.remove(at: index) }
                                            }) {
                                                Image(systemName: "trash")
                                                    .font(.caption)
                                                    .foregroundColor(.red.opacity(0.7))
                                            }
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        if index < opponentStore.opponents.count - 1 {
                                            Divider().background(Color.gray.opacity(0.2))
                                        }
                                    }
                                }
                                .background(Color.white.opacity(0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .padding(.vertical, 4)

                        if opponentStats.isEmpty {
                            emptyState
                        } else {
                            // Summary
                            HStack(spacing: 12) {
                                StatCard(
                                    title: languageManager.opponentsCount,
                                    value: "\(opponentStats.count)",
                                    icon: "person.2",
                                    color: .cyan
                                )
                                StatCard(
                                    title: languageManager.opponentsTopRival,
                                    value: opponentStats.first?.opponentName ?? "-",
                                    icon: "flame",
                                    color: .orange
                                )
                            }

                            // MARK: - Sort Picker
                            Picker("", selection: $sortOption) {
                                Text(languageManager.opponentSortByMatches).tag(OpponentSortOption.matches)
                                Text(languageManager.opponentSortByWinRate).tag(OpponentSortOption.winRate)
                                Text(languageManager.opponentSortByRecent).tag(OpponentSortOption.recent)
                            }
                            .pickerStyle(.segmented)

                            // Opponent list
                            ForEach(opponentStats) { stat in
                                VStack(spacing: 0) {
                                    opponentRow(stat: stat)
                                        .onTapGesture {
                                            withAnimation(.easeInOut(duration: 0.25)) {
                                                if expandedOpponent == stat.opponentName {
                                                    expandedOpponent = nil
                                                } else {
                                                    expandedOpponent = stat.opponentName
                                                }
                                            }
                                        }

                                    if expandedOpponent == stat.opponentName {
                                        opponentDetail(stat: stat)
                                            .transition(.opacity.combined(with: .move(edge: .top)))
                                    }
                                }
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            store.refresh()
            eloManager.recalculateAll(from: store.records)
        }
    }

    // MARK: - Random Buddy Generator

    private func generateRandomBuddy() {
        let prefix = languageManager.randomBuddy
        let hashPrefix = "\(prefix) #"

        // Count today's random buddies from match records
        let todayRecords = store.records.filter { Calendar.current.isDateInToday($0.startTime) }
        let todayBuddyCount = todayRecords.filter { $0.teamBName.hasPrefix(hashPrefix) }.count

        // Also check saved opponents for today-pattern names
        let savedBuddyCount = opponentStore.opponents.filter { $0.hasPrefix(hashPrefix) }.count

        let nextNumber = max(todayBuddyCount, savedBuddyCount) + 1
        newOpponentName = "\(hashPrefix)\(nextNumber)"
    }

    // MARK: - Opponent Row

    private func opponentRow(stat: OpponentStat) -> some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(stat.opponentName)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.white)

                    HStack(spacing: 6) {
                        Text(languageManager.formatMatchCount(stat.totalMatches))
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.gray)

                        // ELO badge
                        if let eloScore = eloManager.opponentRatings[stat.opponentName] {
                            Text("\(eloScore)")
                                .font(.system(.caption2, design: .rounded, weight: .medium))
                                .foregroundColor(eloManager.tierColor(for: eloScore))
                        }
                    }
                }

                Spacer()

                // Win/Loss numbers
                HStack(spacing: 4) {
                    Text("\(stat.wins)")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundColor(.green)
                    Text(":")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.gray)
                    Text("\(stat.losses)")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundColor(.red)
                }

                Image(systemName: expandedOpponent == stat.opponentName ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.5))
                    .padding(.leading, 4)
            }

            // Win rate progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.red.opacity(0.3))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green)
                        .frame(width: geo.size.width * stat.winRate, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding()
    }

    // MARK: - Opponent Detail (expanded)

    private func opponentDetail(stat: OpponentStat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider().background(Color.gray.opacity(0.3))

            // Fun comment
            Text(funComment(for: stat))
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.yellow)
                .padding(.horizontal, 16)

            // ELO detail
            if let eloScore = eloManager.opponentRatings[stat.opponentName] {
                HStack(spacing: 8) {
                    Image(systemName: eloManager.tierIcon(for: eloScore))
                        .foregroundColor(eloManager.tierColor(for: eloScore))
                    Text("\(languageManager.eloRating): \(eloScore)")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundColor(.white)
                    Text(eloManager.ratingTier(for: eloScore))
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(eloManager.tierColor(for: eloScore))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(eloManager.tierColor(for: eloScore).opacity(0.15))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 16)
            }

            // Radar chart
            RadarChartView(stat: stat, records: store.records)
                .padding(.horizontal, 16)

            // Recent 5 results
            HStack(spacing: 6) {
                Text(languageManager.opponentsRecent)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.gray)

                ForEach(Array(stat.recentResults.enumerated()), id: \.offset) { _, won in
                    Circle()
                        .fill(won ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                }

                Spacer()

                Text(languageManager.formatOpponentWinRate(stat.winRate))
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundColor(stat.winRate >= 0.5 ? .green : .red)
            }
            .padding(.horizontal, 16)

            // Recent match records (last 5)
            ForEach(Array(stat.matchRecords.prefix(5))) { record in
                NavigationLink(destination: MatchDetailView(record: record)) {
                    HStack {
                        Circle()
                            .fill(record.teamAWon ? Color.green : Color.red)
                            .frame(width: 6, height: 6)

                        Text(record.startTime, format: .dateTime.month().day())
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.gray)

                        Spacer()

                        Text("\(record.gamesWonByA) : \(record.gamesWonByB)")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundColor(.white)

                        Text(record.teamAWon ? languageManager.opponentsW : languageManager.opponentsL)
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundColor(record.teamAWon ? .green : .red)

                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundColor(.gray.opacity(0.4))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                }
            }

            if stat.matchRecords.count > 5 {
                Text(languageManager.formatTotalMatches(stat.matchRecords.count))
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.gray.opacity(0.6))
                    .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 12)
    }

    // MARK: - Fun Comment

    private func funComment(for stat: OpponentStat) -> String {
        let name = stat.opponentName
        let rate = stat.winRate

        if languageManager.language == "zh" {
            if rate >= 0.8 {
                return "你是\(name)的克星！\u{1F3F8}"
            } else if rate >= 0.6 {
                return "对\(name)保持优势 \u{1F4AA}"
            } else if rate == 0.5 {
                return "势均力敌的对手 \u{2694}\u{FE0F}"
            } else if rate >= 0.3 {
                return "\(name)实力不俗 \u{1F525}"
            } else {
                return "总有一天会赢ta！加油 \u{1F431}"
            }
        } else {
            if rate >= 0.8 {
                return "You dominate \(name)! \u{1F3F8}"
            } else if rate >= 0.6 {
                return "Ahead vs \(name) \u{1F4AA}"
            } else if rate == 0.5 {
                return "Evenly matched \u{2694}\u{FE0F}"
            } else if rate >= 0.3 {
                return "\(name) is tough \u{1F525}"
            } else {
                return "You'll get them! \u{1F431}"
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.4))

            Text(languageManager.opponentsNoRecords)
                .font(.system(.body, design: .rounded))
                .foregroundColor(.gray)

            Text(languageManager.opponentsPlayToSee)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Radar Chart View

struct RadarChartView: View {
    let stat: OpponentStat
    let records: [MatchRecord]
    @ObservedObject private var languageManager = LanguageManager.shared

    private var radarData: [Double] {
        let opponentRecords = records.filter { $0.teamBName == stat.opponentName }
        guard !opponentRecords.isEmpty else { return [0, 0, 0, 0, 0] }

        // 1. Win rate (0-1)
        let winRate = stat.winRate

        // 2. Average duration normalized (30 min = 1.0)
        let avgMinutes = Double(opponentRecords.reduce(0) { $0 + $1.elapsedMinutes }) / Double(opponentRecords.count)
        let durationNorm = min(avgMinutes / 30.0, 1.0)

        // 3. Comeback count normalized (5 = 1.0)
        let totalComebacks = opponentRecords.reduce(0) { $0 + $1.comebackGames }
        let comebackNorm = min(Double(totalComebacks) / 5.0, 1.0)

        // 4. Deuce count normalized (10 = 1.0)
        let totalDeuces = opponentRecords.reduce(0) { $0 + $1.totalDeuces }
        let deuceNorm = min(Double(totalDeuces) / 10.0, 1.0)

        // 5. Best scoring run normalized (10 = 1.0)
        let bestRun = opponentRecords.reduce(0) { max($0, $1.longestRunA) }
        let runNorm = min(Double(bestRun) / 10.0, 1.0)

        return [winRate, durationNorm, comebackNorm, deuceNorm, runNorm]
    }

    private var labels: [String] {
        [
            languageManager.radarWinRate,
            languageManager.radarDuration,
            languageManager.radarComeback,
            languageManager.radarDeuce,
            languageManager.radarBestRun
        ]
    }

    var body: some View {
        VStack {
            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let radius: CGFloat = min(geo.size.width, geo.size.height) / 2 - 30
                let data = radarData
                let count = 5
                let angleStep = 2 * Double.pi / Double(count)

                ZStack {
                    // Grid lines (3 levels)
                    ForEach([0.33, 0.66, 1.0], id: \.self) { level in
                        Path { path in
                            for i in 0...count {
                                let angle = Double(i % count) * angleStep - Double.pi / 2
                                let x = center.x + CGFloat(cos(angle)) * radius * CGFloat(level)
                                let y = center.y + CGFloat(sin(angle)) * radius * CGFloat(level)
                                if i == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    }

                    // Axis lines
                    ForEach(0..<count, id: \.self) { i in
                        Path { path in
                            let angle = Double(i) * angleStep - Double.pi / 2
                            path.move(to: center)
                            path.addLine(to: CGPoint(
                                x: center.x + CGFloat(cos(angle)) * radius,
                                y: center.y + CGFloat(sin(angle)) * radius
                            ))
                        }
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    }

                    // Data polygon (filled)
                    Path { path in
                        for i in 0...count {
                            let idx = i % count
                            let angle = Double(idx) * angleStep - Double.pi / 2
                            let value = CGFloat(data[idx])
                            let x = center.x + CGFloat(cos(angle)) * radius * value
                            let y = center.y + CGFloat(sin(angle)) * radius * value
                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .fill(Color.orange.opacity(0.25))

                    // Data polygon (stroke)
                    Path { path in
                        for i in 0...count {
                            let idx = i % count
                            let angle = Double(idx) * angleStep - Double.pi / 2
                            let value = CGFloat(data[idx])
                            let x = center.x + CGFloat(cos(angle)) * radius * value
                            let y = center.y + CGFloat(sin(angle)) * radius * value
                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color.orange, lineWidth: 2)

                    // Data points
                    ForEach(0..<count, id: \.self) { i in
                        let angle = Double(i) * angleStep - Double.pi / 2
                        let value = CGFloat(data[i])
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 6, height: 6)
                            .position(
                                x: center.x + CGFloat(cos(angle)) * radius * value,
                                y: center.y + CGFloat(sin(angle)) * radius * value
                            )
                    }

                    // Labels
                    ForEach(0..<count, id: \.self) { i in
                        let angle = Double(i) * angleStep - Double.pi / 2
                        let labelRadius = radius + 20
                        Text(labels[i])
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(.gray)
                            .position(
                                x: center.x + CGFloat(cos(angle)) * labelRadius,
                                y: center.y + CGFloat(sin(angle)) * labelRadius
                            )
                    }
                }
            }
            .frame(width: 200, height: 200)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    OpponentStatsView()
        .preferredColorScheme(.dark)
}
