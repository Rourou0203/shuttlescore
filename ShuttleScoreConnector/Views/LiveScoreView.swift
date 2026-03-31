import SwiftUI

struct LiveScoreView: View {
    @ObservedObject private var session = PhoneSessionManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                // Referee cat background decoration
                Image("cat_scarf")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                    .opacity(0.06)
                    .offset(y: 60)

                if session.isConnected {
                    connectedContent
                } else {
                    waitingContent
                }
            }
            .navigationTitle("实时比分")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
        }
    }

    private var connectedContent: some View {
        VStack(spacing: 20) {
            // Game score
            HStack {
                Text("局分")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.gray)
                Text("\(session.gameA) : \(session.gameB)")
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.top, 20)

            // Match info
            HStack {
                Text("第\(session.gameIndex + 1)局")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.gray)
                Spacer()
                if session.isMatchOver {
                    Text("比赛结束")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.orange)
                } else if session.isGameOver {
                    Text("本局结束")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.yellow)
                }
            }
            .padding(.horizontal, 24)

            // Main score display
            HStack(spacing: 0) {
                // Team A
                VStack(spacing: 12) {
                    Image("cat_orange")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())

                    Text(session.teamAName)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.orange)

                    Text("\(session.scoreA)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity)

                // Divider
                VStack {
                    Text("VS")
                        .font(.system(.title3, design: .rounded))
                        .foregroundColor(.gray)
                }
                .frame(width: 50)

                // Team B
                VStack(spacing: 12) {
                    Image("cat_robe")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())

                    Text(session.teamBName)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.cyan)

                    Text("\(session.scoreB)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)

            // Serving indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 8, height: 8)
                Text("\(session.servingTeamIsA ? session.teamAName : session.teamBName)发球 - \(session.court)")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.yellow)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color.yellow.opacity(0.1))
            .clipShape(Capsule())

            Spacer()
        }
    }
}

#Preview {
    LiveScoreView()
        .preferredColorScheme(.dark)
}
