import SwiftUI

struct MatchHistoryView: View {
    @StateObject private var store = MatchHistoryStore.shared
    @State private var recordToEdit: MatchRecord?
    @State private var recordToDelete: MatchRecord?
    @State private var showDeleteConfirmation = false
    @State private var selectedDate: String?
    @State private var isEditing = false
    @State private var selectedRecordIds: Set<UUID> = []
    @State private var showBatchDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        Text("历史统计")
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        overviewCards
                        CalendarHeatmapView(
                            records: store.records,
                            selectedDate: $selectedDate
                        )
                        matchListByDate
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear { store.refresh() }
        .sheet(item: $recordToEdit) { record in
            EditScoreSheet(record: record, store: store)
        }
        .alert("确认删除", isPresented: $showDeleteConfirmation) {
            Button("删除", role: .destructive) {
                if let record = recordToDelete {
                    withAnimation {
                        store.deleteRecord(id: record.id)
                    }
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            if let record = recordToDelete {
                Text("确定要删除 \(record.teamAName) vs \(record.teamBName) 的比赛记录吗？")
            }
        }
        .alert("确认删除", isPresented: $showBatchDeleteConfirm) {
            Button("删除\(selectedRecordIds.count)条记录", role: .destructive) {
                withAnimation {
                    for id in selectedRecordIds {
                        store.deleteRecord(id: id)
                    }
                    selectedRecordIds.removeAll()
                    isEditing = false
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要删除选中的\(selectedRecordIds.count)条比赛记录吗？此操作不可撤销。")
        }
    }

    // MARK: - Overview Cards (top row)

    private var overviewCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(title: "总场次", value: "\(store.totalMatches)", icon: "sportscourt", color: .orange)
                StatCard(
                    title: "胜率",
                    value: store.totalMatches > 0 ? "\(Int(store.winRate * 100))%" : "-",
                    icon: "trophy",
                    color: .yellow
                )
                StatCard(title: "胜/负", value: "\(store.totalWins)/\(store.totalLosses)", icon: "chart.bar", color: .green)
            }

            HStack(spacing: 12) {
                StatCard(
                    title: "连胜",
                    value: store.currentWinStreak > 0 ? "\(store.currentWinStreak)" : "-",
                    icon: "flame",
                    color: .red
                )
                StatCard(
                    title: "总时长",
                    value: formatMinutes(store.totalMinutes),
                    icon: "clock",
                    color: .cyan
                )
                StatCard(
                    title: "周均",
                    value: String(format: "%.1f场", store.avgMatchesPerWeek),
                    icon: "calendar",
                    color: .purple
                )
            }
        }
    }

    // MARK: - Match List by Date

    /// Filter recordsByDate to only the selected date, or show all
    private var filteredRecordsByDate: [(date: String, displayDate: String, records: [MatchRecord])] {
        if let selected = selectedDate {
            return store.recordsByDate.filter { $0.date == selected }
        }
        return store.recordsByDate
    }

    private var matchListByDate: some View {
        VStack(alignment: .leading, spacing: 16) {
            if store.records.isEmpty {
                emptyState
            } else {
                HStack {
                    Text(selectedDate != nil ? "当日记录" : "比赛记录")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    if selectedDate != nil && !isEditing {
                        Button {
                            withAnimation { selectedDate = nil }
                        } label: {
                            Text("查看全部")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.orange)
                        }
                    }

                    Button {
                        withAnimation {
                            isEditing.toggle()
                            if !isEditing { selectedRecordIds.removeAll() }
                        }
                    } label: {
                        Text(isEditing ? "完成" : "编辑")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.orange)
                    }
                }

                if selectedDate == nil && !isEditing {
                    Text("长按记录可编辑或删除")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.gray.opacity(0.6))
                }

                if filteredRecordsByDate.isEmpty && selectedDate != nil {
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.title2)
                            .foregroundColor(.gray.opacity(0.4))
                        Text("当天没有比赛记录")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                }

                ForEach(filteredRecordsByDate, id: \.date) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        // Date header
                        HStack {
                            Text(group.displayDate)
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .foregroundColor(.orange)

                            Spacer()

                            let wins = group.records.filter { $0.teamAWon }.count
                            let total = group.records.count
                            Text("\(wins)胜\(total - wins)负")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.gray)
                        }

                        ForEach(group.records) { record in
                            if isEditing {
                                HStack(spacing: 12) {
                                    Image(systemName: selectedRecordIds.contains(record.id) ? "checkmark.circle.fill" : "circle")
                                        .font(.system(.title3))
                                        .foregroundColor(selectedRecordIds.contains(record.id) ? .orange : .gray)

                                    MatchRowView(record: record)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        if selectedRecordIds.contains(record.id) {
                                            selectedRecordIds.remove(record.id)
                                        } else {
                                            selectedRecordIds.insert(record.id)
                                        }
                                    }
                                }
                            } else {
                                NavigationLink(destination: MatchDetailView(record: record)) {
                                    MatchRowView(record: record)
                                }
                                .contextMenu {
                                    Button {
                                        recordToEdit = record
                                    } label: {
                                        Label("编辑比分", systemImage: "pencil")
                                    }
                                    Button(role: .destructive) {
                                        recordToDelete = record
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("删除记录", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }

                // Batch action bar in edit mode
                if isEditing {
                    HStack {
                        Button {
                            withAnimation {
                                let allIds = Set(filteredRecordsByDate.flatMap { $0.records.map { $0.id } })
                                if selectedRecordIds.isSuperset(of: allIds) {
                                    selectedRecordIds.removeAll()
                                } else {
                                    selectedRecordIds.formUnion(allIds)
                                }
                            }
                        } label: {
                            let allIds = Set(filteredRecordsByDate.flatMap { $0.records.map { $0.id } })
                            Text(selectedRecordIds.isSuperset(of: allIds) ? "取消全选" : "全选")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.orange)
                        }

                        Spacer()

                        Button {
                            showBatchDeleteConfirm = true
                        } label: {
                            Text("删除(\(selectedRecordIds.count))")
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .foregroundColor(selectedRecordIds.isEmpty ? .gray : .red)
                        }
                        .disabled(selectedRecordIds.isEmpty)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            TeamAvatarView(isTeamA: true, size: 120)
                .opacity(0.5)

            Text("还没有比赛记录")
                .font(.system(.body, design: .rounded))
                .foregroundColor(.gray)

            Text("在 Apple Watch 上开始你的第一场比赛吧")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
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

// MARK: - Edit Score Sheet

struct EditScoreSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var record: MatchRecord
    let store: MatchHistoryStore

    // Editable game scores
    @State private var editableGames: [(scoreA: Int, scoreB: Int)] = []

    init(record: MatchRecord, store: MatchHistoryStore) {
        self.store = store
        self._record = State(initialValue: record)
        self._editableGames = State(initialValue: record.gameScores.map { ($0.scoreA, $0.scoreB) })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Match header
                        HStack {
                            Text(record.teamAName)
                                .foregroundColor(.orange)
                            Text("vs")
                                .foregroundColor(.gray)
                            Text(record.teamBName)
                                .foregroundColor(.cyan)
                        }
                        .font(.system(.headline, design: .rounded, weight: .medium))

                        // Editable game scores
                        ForEach(Array(editableGames.indices), id: \.self) { index in
                            VStack(spacing: 8) {
                                Text("第 \(index + 1) 局")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.gray)

                                HStack(spacing: 20) {
                                    // Team A score
                                    VStack(spacing: 4) {
                                        Text(record.teamAName)
                                            .font(.system(.caption2, design: .rounded))
                                            .foregroundColor(.orange)

                                        HStack(spacing: 12) {
                                            Button {
                                                if editableGames[index].scoreA > 0 {
                                                    editableGames[index].scoreA -= 1
                                                }
                                            } label: {
                                                Image(systemName: "minus.circle.fill")
                                                    .font(.title2)
                                                    .foregroundColor(.gray)
                                            }

                                            Text("\(editableGames[index].scoreA)")
                                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                                .frame(minWidth: 44)

                                            Button {
                                                editableGames[index].scoreA += 1
                                            } label: {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.title2)
                                                    .foregroundColor(.orange)
                                            }
                                        }
                                    }

                                    Text(":")
                                        .font(.system(.title2, design: .rounded))
                                        .foregroundColor(.gray)

                                    // Team B score
                                    VStack(spacing: 4) {
                                        Text(record.teamBName)
                                            .font(.system(.caption2, design: .rounded))
                                            .foregroundColor(.cyan)

                                        HStack(spacing: 12) {
                                            Button {
                                                if editableGames[index].scoreB > 0 {
                                                    editableGames[index].scoreB -= 1
                                                }
                                            } label: {
                                                Image(systemName: "minus.circle.fill")
                                                    .font(.title2)
                                                    .foregroundColor(.gray)
                                            }

                                            Text("\(editableGames[index].scoreB)")
                                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                                .frame(minWidth: 44)

                                            Button {
                                                editableGames[index].scoreB += 1
                                            } label: {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.title2)
                                                    .foregroundColor(.cyan)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Result preview
                        let gamesA = editableGames.filter { $0.scoreA > $0.scoreB }.count
                        let gamesB = editableGames.filter { $0.scoreB > $0.scoreA }.count
                        let winner = gamesA > gamesB ? record.teamAName : (gamesB > gamesA ? record.teamBName : "未分胜负")

                        VStack(spacing: 4) {
                            Text("局分 \(gamesA) : \(gamesB)")
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .foregroundColor(.white)
                            Text("\(winner) 胜")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.yellow)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .navigationTitle("编辑比分")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .foregroundColor(.gray)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveChanges()
                        dismiss()
                    }
                    .foregroundColor(.orange)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveChanges() {
        // Update game scores (keep history intact)
        var updatedRecord = record
        for i in editableGames.indices where i < updatedRecord.gameScores.count {
            updatedRecord.gameScores[i] = GameScore(
                scoreA: editableGames[i].scoreA,
                scoreB: editableGames[i].scoreB,
                history: updatedRecord.gameScores[i].history
            )
        }

        // Recalculate games won
        updatedRecord.gamesWonByA = editableGames.filter { $0.scoreA > $0.scoreB }.count
        updatedRecord.gamesWonByB = editableGames.filter { $0.scoreB > $0.scoreA }.count

        // Update winner
        if updatedRecord.gamesWonByA > updatedRecord.gamesWonByB {
            updatedRecord.winnerName = updatedRecord.teamAName
        } else if updatedRecord.gamesWonByB > updatedRecord.gamesWonByA {
            updatedRecord.winnerName = updatedRecord.teamBName
        } else {
            updatedRecord.winnerName = "未分胜负"
        }

        store.updateRecord(updatedRecord)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(.title2, design: .rounded))
                .foregroundColor(color)

            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundColor(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(title)
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Match Row

struct MatchRowView: View {
    let record: MatchRecord

    var body: some View {
        HStack(spacing: 12) {
            // Cat avatar: custom/orange for win, robe for loss
            TeamAvatarView(isTeamA: record.teamAWon, size: 50)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(record.teamAName)
                        .foregroundColor(record.teamAWon ? .orange : .white)
                    Text("vs")
                        .foregroundColor(.gray)
                    Text(record.teamBName)
                        .foregroundColor(record.teamAWon ? .white : .cyan)
                }
                .font(.system(.subheadline, design: .rounded, weight: .medium))

                HStack(spacing: 8) {
                    Text(record.startTime, format: .dateTime.hour().minute())
                    Text("\(record.elapsedMinutes)分钟")
                    if !record.isCompleted {
                        Text("未完赛")
                            .foregroundColor(.red)
                    }
                }
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.gray)
            }

            Spacer()

            // Score
            VStack(spacing: 2) {
                Text("\(record.gamesWonByA) : \(record.gamesWonByB)")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                Text("局")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.gray)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Match Detail View

struct MatchDetailView: View {
    let record: MatchRecord
    @State private var showShareSheet = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    winnerBanner
                    matchInfoChips
                    gameByGameSection
                    analysisSection
                    dateSection

                    // Share button
                    Button(action: { showShareSheet = true }) {
                        Label("分享战绩", systemImage: "square.and.arrow.up")
                            .font(.system(.body, design: .rounded))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .padding(.top, 10)
                }
                .padding()
            }
        }
        .navigationTitle("比赛详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showShareSheet) {
            if let image = ShareCardView(record: record).renderImage() {
                ShareSheetView(items: [image])
            }
        }
    }

    // MARK: - Winner Banner

    private var winnerBanner: some View {
        VStack(spacing: 8) {
            TeamAvatarView(isTeamA: record.teamAWon, size: 80)
                .overlay(
                    Circle().stroke(Color.yellow, lineWidth: 3)
                )

            if record.isCompleted {
                Text(record.winnerName + " 胜")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundColor(.yellow)
            } else {
                Text("未完赛")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundColor(.red)
            }

            Text("\(record.gamesWonByA) : \(record.gamesWonByB)")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.top, 10)
    }

    // MARK: - Info Chips

    private var matchInfoChips: some View {
        HStack(spacing: 20) {
            infoChip(icon: "clock", text: "\(record.elapsedMinutes) 分钟")
            infoChip(icon: "sportscourt", text: record.matchType.rawValue)
            infoChip(icon: "target", text: "\(record.winningScore) 分制")
        }
    }

    // MARK: - Game by Game

    private var gameByGameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("每局比分")
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white)

            ForEach(Array(record.gameScores.enumerated()), id: \.offset) { index, game in
                VStack(spacing: 0) {
                    HStack {
                        Text("第 \(index + 1) 局")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.gray)

                        Spacer()

                        Text("\(game.scoreA)")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundColor(game.scoreA > game.scoreB ? .orange : .white)

                        Text(":")
                            .font(.system(.title3, design: .rounded))
                            .foregroundColor(.gray)

                        Text("\(game.scoreB)")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundColor(game.scoreB > game.scoreA ? .cyan : .white)
                    }
                    .padding()

                    // Score progression mini chart if history available
                    if !game.history.isEmpty {
                        scoreProgressionChart(game: game)
                            .frame(height: 40)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    }
                }
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Analysis Section

    private var analysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("数据分析")
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                analysisCard(title: "我方最长连分", value: "\(record.longestRunA)", color: .orange)
                analysisCard(title: "对方最长连分", value: "\(record.longestRunB)", color: .cyan)
                analysisCard(title: "Deuce 次数", value: "\(record.totalDeuces)", color: .yellow)
                analysisCard(title: "逆转局数", value: "\(record.comebackGames)", color: .green)
            }

            // Serving stats if available
            if hasServingData {
                let (servePointsA, servePointsB, totalServeA, totalServeB) = servingStats
                VStack(alignment: .leading, spacing: 8) {
                    Text("发球得分")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.gray)

                    HStack(spacing: 20) {
                        VStack {
                            Text(record.teamAName)
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.orange)
                            Text("\(servePointsA)/\(totalServeA)")
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundColor(.white)
                            if totalServeA > 0 {
                                Text("\(Int(Double(servePointsA) / Double(totalServeA) * 100))%")
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity)

                        VStack {
                            Text(record.teamBName)
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.cyan)
                            Text("\(servePointsB)/\(totalServeB)")
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundColor(.white)
                            if totalServeB > 0 {
                                Text("\(Int(Double(servePointsB) / Double(totalServeB) * 100))%")
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Date Section

    private var dateSection: some View {
        VStack(spacing: 4) {
            Text("比赛时间")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.gray)
            Text(record.startTime, format: .dateTime.year().month().day().hour().minute())
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.top, 10)
    }

    // MARK: - Helpers

    private func infoChip(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(.caption, design: .rounded))
            Text(text)
                .font(.system(.caption, design: .rounded))
        }
        .foregroundColor(.white.opacity(0.8))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.1))
        .clipShape(Capsule())
    }

    private func analysisCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundColor(color)
            Text(title)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Score Progression Chart

    private func scoreProgressionChart(game: GameScore) -> some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let count = game.history.count
            guard count > 1 else { return AnyView(EmptyView()) }

            let maxScore = max(Double(game.scoreA), Double(game.scoreB), 1.0)
            let stepX = width / Double(count - 1)

            return AnyView(
                ZStack {
                    // Team A line (orange)
                    Path { path in
                        for (i, snap) in game.history.enumerated() {
                            let x = Double(i) * stepX
                            let y = height - (Double(snap.scoreA) / maxScore) * height
                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color.orange, lineWidth: 1.5)

                    // Team B line (cyan)
                    Path { path in
                        for (i, snap) in game.history.enumerated() {
                            let x = Double(i) * stepX
                            let y = height - (Double(snap.scoreB) / maxScore) * height
                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color.cyan, lineWidth: 1.5)
                }
            )
        }
    }

    // MARK: - Serving Stats

    private var hasServingData: Bool {
        record.gameScores.contains { game in
            game.history.count >= 2
        }
    }

    private var servingStats: (Int, Int, Int, Int) {
        var servePointsA = 0
        var servePointsB = 0
        var totalServeA = 0
        var totalServeB = 0

        for game in record.gameScores {
            guard game.history.count >= 2 else { continue }
            for i in 1..<game.history.count {
                let prev = game.history[i - 1]
                let curr = game.history[i]
                let teamAScored = curr.scoreA > prev.scoreA

                if prev.servingTeamIsA {
                    totalServeA += 1
                    if teamAScored { servePointsA += 1 }
                } else {
                    totalServeB += 1
                    if !teamAScored { servePointsB += 1 }
                }
            }
        }

        return (servePointsA, servePointsB, totalServeA, totalServeB)
    }
}

#Preview {
    MatchHistoryView()
        .preferredColorScheme(.dark)
}
