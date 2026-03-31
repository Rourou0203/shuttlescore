# 羽毛球计分器 Watch App - 项目上下文

## 项目概况
Apple Watch 原生羽毛球计分 App，SwiftUI，watchOS 11.0+。
目标：打球时单手操作，3秒内完成计分，不用掏手机。

## 目录结构
```
~/clawd/projects/shuttlescore-watch/
  ShuttleScore.xcodeproj        # Xcode 项目（xcodegen 生成）
  project.yml                   # xcodegen 配置
  mockup.html                   # UI 原型图
  ShuttleScore Watch App/
    ShuttleScoreApp.swift
    Info.plist                  # 注意：必须有 WKWatchOnly=true，否则 simctl 安装失败
    Assets.xcassets/
      AppIcon.appiconset/       # 橘猫打羽毛球图标
      CatIcon.imageset/         # 首页用的橘猫图
    Models/
      MatchState.swift          # 比赛状态、GameState、MatchType
      MatchStore.swift          # 存档（UserDefaults），含历史记录
      MatchRecord.swift         # 历史记录数据模型
      ScoringEngine.swift       # 计分逻辑、撤销、纠错
    Views/
      HomeView.swift            # 首页
      MatchSetupView.swift      # 赛前设置
      ScoreboardView.swift      # 计分主界面
      GameSummaryView.swift     # 局末总结
      MatchSummaryView.swift    # 赛末总结
      HistoryView.swift         # 今日历史记录
      CalendarView.swift        # 按日期浏览历史
```

## 当前状态（2026-03-29）✅ 全部完成

### 已实现功能
- [x] 首页：CatIcon logo（100x100），快速开始/新建比赛/继续上场/历史记录
- [x] 快速开始：用上次设置直接开赛，跳过设置页（橙色大按钮）
- [x] 赛前设置：单双打、队伍名称、局数（1/3/5）、先发球方、胜利分数（11/15/21/自定义）、中场换边提醒（可选，默认关）
- [x] 计分界面：左右点击加分，发球方黄点，发球区显示，局数比分
- [x] Digital Crown 向下转 = 撤销上一分
- [x] 长按对方分数 0.5s = 纠错（把最后一分转给正确的队），绿色气泡确认
- [x] 震动反馈（普通得分/换发球/局末/赛末），直接调用无DispatchQueue包装
- [x] 局末：换边提示 + 猫爪装饰，开始下一局
- [x] 赛末：胜负总结，用时，回首页
- [x] 中场换边提醒：决胜局11分时弹出（需在设置里开启）
- [x] 退出比赛：三选项（继续比赛/保存并退出/放弃本场），中途退出也能保存记录
- [x] 今日记录：当天比赛列表，显示时间/比分/胜者
- [x] 历史记录：按日期分组，保留30天，支持未完成比赛记录
- [x] 数据持久化：UserDefaults，比赛结束自动存历史，错误日志打印
- [x] 上次设置记忆：MatchStore.MatchSettings 存储/读取上次比赛配置

### 计分规则
- 胜利分数可配置（默认21）
- 领先2分制，封顶为 winningScore+9
- BWF规则：得分方获得/保持发球权；下一局由输局方先发

## 本地启动
```bash
# 编译
cd ~/clawd/projects/shuttlescore-watch
xcodebuild -project ShuttleScore.xcodeproj \
  -scheme "ShuttleScore Watch App" \
  -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" \
  build

# 安装到模拟器（UDID: AAD521E6-1968-482C-B98A-1A2B6B424152）
xcrun simctl boot AAD521E6-1968-482C-B98A-1A2B6B424152 2>/dev/null || true
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/ShuttleScore-*/Build/Products/Debug-watchsimulator -name "*.app" | head -1)
xcrun simctl install AAD521E6-1968-482C-B98A-1A2B6B424152 "$APP_PATH"
xcrun simctl launch AAD521E6-1968-482C-B98A-1A2B6B424152 com.clawd.shuttlescore
open -a Simulator
```

## 已知限制
- 无 iPhone 配套 App
- 无 Apple Watch Complication
- 无 iCloud 同步

## 断点恢复规则
进入项目后读本文件了解进度，再读 WORKLOG.md（如存在）。
