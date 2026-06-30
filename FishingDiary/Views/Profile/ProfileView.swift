import SwiftUI
import SwiftData

// MARK: - 我的页
struct ProfileView: View {
    @Query private var sessions: [FishingSession]
    @EnvironmentObject var purchaseService: PurchaseService
    @AppStorage("userName") private var userName: String = "钓鱼人"

    private let speciesDexTotal = 60

    // MARK: 统计聚合
    private var totalCatch: Int { sessions.reduce(0) { $0 + $1.catches.count } }
    private var speciesCount: Int {
        Set(sessions.flatMap { $0.catches.map(\.speciesName) }.filter { !$0.isEmpty }).count
    }
    private var fishingDays: Int {
        Set(sessions.map { Calendar.current.startOfDay(for: $0.date) }).count
    }
    private var longestCm: Int {
        sessions.flatMap { $0.catches }.compactMap(\.lengthCm).max().map { Int($0) } ?? 0
    }

    // 已钓鱼种（去重），使用每尾鱼自身的抠图而非 Session 封面图
    private var caughtSpecies: [(name: String, imageData: Data?)] {
        var seen = Set<String>()
        return sessions
            .flatMap { s in s.catches.map { (name: $0.speciesName, imageData: Data?($0.cutoutImageData)) } }
            .filter { !$0.name.isEmpty && seen.insert($0.name).inserted }
    }

    // 里程碑定义
    private struct Milestone {
        let icon: String
        let name: String
        let desc: String
        let isGold: Bool
        let progress: Double    // 0...1，1 = 达成
    }

    private var milestones: [Milestone] {
        [
            Milestone(icon: "✦", name: "首次渔获", desc: "记录第一条渔获",
                      isGold: totalCatch >= 1, progress: totalCatch >= 1 ? 1 : 0),
            Milestone(icon: "⬡", name: "十尾达成", desc: "累计钓获满 10 尾",
                      isGold: totalCatch >= 10, progress: min(Double(totalCatch) / 10, 1)),
            Milestone(icon: "◎", name: "百尾达成", desc: "累计钓获满 100 尾",
                      isGold: totalCatch >= 100, progress: min(Double(totalCatch) / 100, 1)),
            Milestone(icon: "◷", name: "夜钓达人", desc: "完成 10 次出钓（\(fishingDays)/10）",
                      isGold: fishingDays >= 10, progress: min(Double(fishingDays) / 10, 1)),
            Milestone(icon: "★", name: "图鉴收集者", desc: "收录 5 种不同鱼种",
                      isGold: speciesCount >= 5, progress: min(Double(speciesCount) / 5, 1)),
        ]
    }

    var body: some View {
        ZStack {
            Theme.Colors.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.Space.xl) {
                    // 头像区
                    profileHeader
                        .padding(.top, Theme.Space.md)

                    // 订阅状态条
                    subscriptionBadge

                    // 墨底统计四格
                    statsBar

                    // 鱼种图鉴
                    speciesDex

                    // 里程碑
                    milestonesSection

                    // 设置列表
                    settingsList
                }
                .padding(.horizontal, Theme.Space.lg)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("我的")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - 头像区
    private var profileHeader: some View {
        HStack(spacing: Theme.Space.md) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.accentSoft)
                    .frame(width: 64, height: 64)
                Image(systemName: "person.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.Colors.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(userName)
                    .font(Theme.Font.title)
                    .foregroundStyle(Theme.Colors.ink)
                Text("出钓 \(fishingDays) 天 · 钓鱼人")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Colors.ink2)
            }

            Spacer()

            Button {
                // TODO: 设置页
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.Colors.ink3)
            }
        }
    }

    // MARK: - 订阅状态条
    private var subscriptionBadge: some View {
        HStack(spacing: Theme.Space.md) {
            if purchaseService.isPurchased {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Theme.Colors.accent)
                Text("永久会员").font(Theme.Font.subhead).fontWeight(.semibold).foregroundStyle(Theme.Colors.accent)
                Text("·").foregroundStyle(Theme.Colors.ink3)
                Text("无限高清导出").font(Theme.Font.subhead).foregroundStyle(Theme.Colors.ink2)
                Spacer()
                Text("¥68 ✓").font(Theme.Font.microLabel).foregroundStyle(Theme.Colors.accent)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundStyle(Theme.Colors.gold)
                Text("解锁高清导出").font(Theme.Font.subhead).fontWeight(.semibold).foregroundStyle(Theme.Colors.gold)
                Spacer()
                Text("解锁 ›").font(Theme.Font.subhead).foregroundStyle(Theme.Colors.gold)
            }
        }
        .padding(.horizontal, Theme.Space.md)
        .padding(.vertical, Theme.Space.md)
        .background(purchaseService.isPurchased ? Theme.Colors.accentSoft : Theme.Colors.gold.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field))
    }

    // MARK: - 墨底统计四格
    private var statsBar: some View {
        HStack(spacing: 0) {
            statCell(value: "\(totalCatch)", label: "总渔获")
            statDivider
            statCell(value: "\(speciesCount)", label: "鱼种")
            statDivider
            statCell(value: "\(fishingDays)", label: "出钓天")
            statDivider
            statCell(value: longestCm > 0 ? "\(longestCm)" : "—", label: "最长cm")
        }
        .padding(.vertical, Theme.Space.lg)
        .background(Theme.Colors.ink)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 5) {
            Text(value)
                .font(Theme.Font.data(22, weight: .medium))
                .foregroundStyle(.white)
            Text(label.uppercased())
                .font(Theme.Font.microLabel)
                .kerning(0.5)
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.12))
            .frame(width: 1, height: 32)
    }

    // MARK: - 鱼种图鉴
    private var speciesDex: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            HStack {
                SectionLabel(text: "鱼种图鉴")
                Spacer()
                Text("\(caughtSpecies.count) / \(speciesDexTotal) 已解锁 ›")
                    .font(Theme.Font.microLabel)
                    .foregroundStyle(Theme.Colors.ink2)
            }

            if caughtSpecies.isEmpty {
                Text("暂无收录鱼种，开始钓鱼吧")
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Colors.ink3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, Theme.Space.sm)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Theme.Space.sm), count: 5),
                          spacing: Theme.Space.sm) {
                    ForEach(Array(caughtSpecies.enumerated()), id: \.offset) { _, species in
                        dexCell(species: species)
                    }
                    // 填充未解锁格子（最多展示 10 格）
                    let remaining = max(0, 10 - caughtSpecies.count)
                    ForEach(0..<min(remaining, 5), id: \.self) { _ in
                        lockedDexCell
                    }
                }
            }
        }
    }

    private func dexCell(species: (name: String, imageData: Data?)) -> some View {
        VStack(spacing: 3) {
            ZStack {
                if let data = species.imageData,
                   let raw = UIImage(data: data),
                   let img = raw.withWhiteStroke(width: 3) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .padding(4)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Theme.Colors.accentSoft)
                    Text("🐟").font(.title3)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)

            Text(species.name)
                .font(.system(size: 8))
                .foregroundStyle(Theme.Colors.ink2)
                .lineLimit(1)
        }
    }

    private var lockedDexCell: some View {
        VStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.Colors.bg2)
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Text("?")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.Colors.ink3)
                }
            Text("未解锁")
                .font(.system(size: 8))
                .foregroundStyle(Theme.Colors.ink3)
        }
    }

    // MARK: - 里程碑
    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            HStack {
                SectionLabel(text: "里程碑")
                Text("🏆").font(.caption)
                Spacer()
                Text("全部 ›").font(Theme.Font.microLabel).foregroundStyle(Theme.Colors.ink2)
            }

            VStack(spacing: 0) {
                ForEach(Array(milestones.enumerated()), id: \.offset) { i, ms in
                    milestoneRow(ms)
                    if i < milestones.count - 1 {
                        Divider().padding(.leading, 52)
                    }
                }
            }
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field))
            .shadowSoft()
        }
    }

    private func milestoneRow(_ ms: Milestone) -> some View {
        HStack(spacing: Theme.Space.md) {
            // 徽章
            ZStack {
                Circle()
                    .fill(ms.isGold ? Theme.Colors.gold.opacity(0.15) : Theme.Colors.bg2)
                    .frame(width: 36, height: 36)
                Text(ms.icon)
                    .font(.system(size: 15))
                    .foregroundStyle(ms.isGold ? Theme.Colors.gold : Theme.Colors.ink3)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(ms.name)
                    .font(Theme.Font.subhead)
                    .fontWeight(.semibold)
                    .foregroundStyle(ms.isGold ? Theme.Colors.ink : Theme.Colors.ink2)
                Text(ms.desc)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Colors.ink3)

                // 进度条（未达成时显示）
                if !ms.isGold && ms.progress > 0 {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.Colors.bg2).frame(height: 3)
                            Capsule()
                                .fill(Theme.Colors.accent)
                                .frame(width: geo.size.width * ms.progress, height: 3)
                        }
                    }
                    .frame(height: 3)
                    .padding(.top, 2)
                }
            }

            Spacer()

            if ms.isGold {
                Text("已达成")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Colors.gold)
            }
        }
        .padding(.horizontal, Theme.Space.md)
        .padding(.vertical, 13)
    }

    // MARK: - 设置列表
    private var settingsList: some View {
        VStack(spacing: Theme.Space.md) {
            settingsGroup(items: [
                ("icloud", "iCloud 恢复存档", "恢复 ›"),
                ("arrow.down.doc", "导出我的数据", "›"),
                ("arrow.counterclockwise", "恢复购买", "›"),
                ("gearshape", "设置 · 单位 / 隐私", "›"),
            ])
            settingsGroup(items: [
                ("heart", "给钓鱼日记好评", "›"),
                ("envelope", "联系开发者", "›"),
                ("info.circle", "关于 · v1.0.0", "›"),
            ])
        }
    }

    private func settingsGroup(items: [(String, String, String)]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                Button {
                    handleSettingsTap(item.1)
                } label: {
                    HStack(spacing: Theme.Space.md) {
                        Image(systemName: item.0)
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.Colors.accent)
                            .frame(width: 22)
                        Text(item.1)
                            .font(Theme.Font.subhead)
                            .foregroundStyle(Theme.Colors.ink)
                        Spacer()
                        Text(item.2)
                            .font(Theme.Font.subhead)
                            .foregroundStyle(Theme.Colors.ink3)
                    }
                    .padding(.horizontal, Theme.Space.md)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if i < items.count - 1 {
                    Divider().padding(.leading, 54)
                }
            }
        }
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field))
        .shadowSoft()
    }

    private func handleSettingsTap(_ label: String) {
        if label.contains("恢复购买") {
            Task { await purchaseService.restore() }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(PurchaseService())
    }
    .modelContainer(for: [FishingSession.self, FishCatch.self], inMemory: true)
}
