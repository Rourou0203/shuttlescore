import SwiftUI

struct LiveScoreView: View {
    @ObservedObject private var session = PhoneSessionManager.shared
    @State private var showPhoneSetup = false
    @State private var phoneMatch: PhoneMatchState?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if session.isConnected {
                connectedContent
            } else {
                waitingContent
            }
        }
        .sheet(isPresented: $showPhoneSetup) {
            PhoneSetupView { matchState in
                phoneMatch = matchState
                showPhoneSetup = false
            }
        }
        .fullScreenCover(item: $phoneMatch) { match in
            PhoneScoreboardView(match: match)
        }
    }

    private var waitingContent: some View {
        VStack(spacing: 24) {
            Image("cat_scarf")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.orange.opacity(0.5), lineWidth: 2))

            Text("等待手表连接...")
                .font(.system(.title3, design: .rounded))
                .foregroundColor(.gray)

            ProgressView()
                .tint(.orange)
                .scaleEffect(1.2)

            Text("请在 Apple Watch 上开始比赛")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.gray.opacity(0.7))

            // 手机独立计分入口
            VStack(spacing: 8) {
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.horizontal, 60)

                Text("没有 Apple Watch?")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.gray.opacity(0.6))

                Button(action: { showPhoneSetup = true }) {
                    Label("手机计分", systemImage: "iphone")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
            .padding(.top, 20)
        }
    }

    private var connectedContent: some View {
        GeometryReader { geo in
            let avatarSize = geo.size.width * 0.2
            let scoreFontSize = min(geo.size.width * 0.2, 90)

            VStack(spacing: 0) {
                // Match status overlay
                if session.matchStatus == "terminated" {
                    statusBanner(icon: "exclamationmark.triangle.fill", text: "比赛已中止",
                        subtitle: "\(session.teamAName) \(session.scoreA) - \(session.scoreB) \(session.teamBName)", color: .red)
                } else if session.matchStatus == "ended" {
                    statusBanner(icon: "flag.checkered", text: "比赛已结束",
                        subtitle: "局分 \(session.gameA) : \(session.gameB)", color: .green)
                } else if session.matchStatus == "idle" {
                    statusBanner(icon: "clock.fill", text: "等待开始比赛",
                        subtitle: "请在手表上开始新比赛", color: .orange)
                }

                // Game score header
                HStack(spacing: 8) {
                    Text("局分")
                        .font(.system(.title3, design: .rounded))
                        .foregroundColor(.gray)
                    Text("\(session.gameA) : \(session.gameB)")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.top, 16)

                // Match info row
                HStack {
                    Text("第\(session.gameIndex + 1)局")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.gray)
                    Spacer()
                    if session.isMatchOver {
                        Text("比赛结束")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    } else if session.isGameOver {
                        Text("本局结束")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.medium)
                            .foregroundColor(.yellow)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 4)

                Spacer()

                // Main score display
                HStack(spacing: 0) {
                    VStack(spacing: 16) {
                        TeamAvatarView(isTeamA: true, size: avatarSize)
                        Text(session.teamAName)
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.orange)
                        Text("\(session.scoreA)")
                            .font(.system(size: scoreFontSize, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                    }
                    .frame(maxWidth: .infinity)

                    Text("VS")
                        .font(.system(.title3, design: .rounded))
                        .foregroundColor(.gray.opacity(0.6))
                        .frame(width: 44)

                    VStack(spacing: 16) {
                        TeamAvatarView(isTeamA: false, size: avatarSize)
                        Text(session.teamBName)
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.cyan)
                        Text("\(session.scoreB)")
                            .font(.system(size: scoreFontSize, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)

                Spacer()

                // Serving indicator
                if session.matchStatus == "playing" || session.matchStatus == "idle" {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 8, height: 8)
                        Text("\(session.servingTeamIsA ? session.teamAName : session.teamBName)发球 - \(session.court)")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.yellow)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Color.yellow.opacity(0.1))
                    .clipShape(Capsule())
                    .padding(.bottom, 20)
                }
            }
        }
    }

    private func statusBanner(icon: String, text: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(.caption))
                Text(text).font(.system(.subheadline, design: .rounded)).fontWeight(.semibold)
            }
            .foregroundColor(color)
            Text(subtitle)
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(color.opacity(0.8))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.1))
    }
}

#Preview {
    LiveScoreView()
        .preferredColorScheme(.dark)
}
