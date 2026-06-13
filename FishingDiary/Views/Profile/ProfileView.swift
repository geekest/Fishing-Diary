import SwiftUI
import SwiftData

/// 我的页面：统计 / 购买状态 / 设置
struct ProfileView: View {
    @Query private var sessions: [FishingSession]
    @EnvironmentObject var purchaseService: PurchaseService

    @AppStorage("userName") private var userName: String = "钓鱼人"

    // MARK: - 统计聚合
    private var totalCatch: Int { sessions.reduce(0) { $0 + $1.catches.count } }
    private var speciesCount: Int { Set(sessions.flatMap { $0.catches.map(\.speciesName) }.filter { !$0.isEmpty }).count }
    private var fishingDays: Int { Set(sessions.map { Calendar.current.startOfDay(for: $0.date) }).count }
    private var longestCm: Int {
        sessions.flatMap { $0.catches }.compactMap(\.lengthCm).max().map { Int($0) } ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 头部：头像 + 用户名
                profileHeader

                // 订阅状态条
                subscriptionBadge

                Divider().padding(.vertical, 8)

                // 统计四格
                statsBar

                Divider().padding(.vertical, 8)

                // 设置列表
                settingsSections
            }
        }
        .navigationTitle("我的")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - 头部
    private var profileHeader: some View {
        HStack(spacing: 14) {
            // 头像占位
            ZStack {
                Circle().fill(Color.accentColor.opacity(0.15)).frame(width: 56, height: 56)
                Image(systemName: "person.fill").font(.title2).foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(userName).font(.headline)
                Text("钓龄 \(fishingDays / 30 > 12 ? "\(fishingDays / 365) 年" : "\(fishingDays) 天") · \(Locale.current.region?.identifier ?? "")").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()

            Button {
                // TODO: 跳转设置页
            } label: {
                Image(systemName: "gearshape").font(.title3).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
    }

    // MARK: - 订阅状态
    private var subscriptionBadge: some View {
        HStack(spacing: 12) {
            if purchaseService.isPurchased {
                Label("永久会员", systemImage: "checkmark.seal.fill")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentColor)
                Text("·").foregroundStyle(.secondary)
                Text("无限高清导出").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text("¥68 ✓").font(.caption).fontWeight(.semibold).foregroundStyle(Color.accentColor)
            } else {
                Label("免费版", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("解锁分享导出 ›")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }

    // MARK: - 统计四格
    private var statsBar: some View {
        HStack {
            statCell(value: "\(totalCatch)", label: "总渔获")
            Divider().frame(height: 32)
            statCell(value: "\(speciesCount)", label: "鱼种")
            Divider().frame(height: 32)
            statCell(value: "\(fishingDays)", label: "出钓天")
            Divider().frame(height: 32)
            statCell(value: longestCm > 0 ? "\(longestCm)" : "—", label: "最长cm")
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title2).fontWeight(.bold)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 设置分组
    private var settingsSections: some View {
        VStack(spacing: 16) {
            settingsGroup(items: [
                ("☁ iCloud 恢复存档", "恢复 ›"),
                ("⤓ 导出我的数据", "›"),
                ("♺ 恢复购买", "›"),
                ("⚙ 设置 · 单位 / 隐私", "›"),
            ])

            settingsGroup(items: [
                ("♡ 给钓鱼日记好评", "›"),
                ("✉ 联系开发者", "›"),
                ("ⓘ 关于 · v1.0.0", "›"),
            ])
        }
        .padding(.horizontal)
    }

    private func settingsGroup(items: [(String, String)]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                HStack {
                    Text(item.0).font(.subheadline)
                    Spacer()
                    Text(item.1).font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
                .onTapGesture {
                    handleSettingsTap(item.0)
                }

                if i < items.count - 1 {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func handleSettingsTap(_ label: String) {
        if label.contains("恢复购买") {
            Task { await purchaseService.restore() }
        }
        // TODO: 其他设置项跳转
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(PurchaseService())
    }
    .modelContainer(for: [FishingSession.self, FishCatch.self], inMemory: true)
}
