import SwiftUI
import SwiftData

// MARK: - 日记时间线（主页）
struct DiaryListView: View {
    @Query(sort: \FishingSession.date, order: .reverse)
    private var sessions: [FishingSession]

    @State private var filterSpecies: String? = nil

    private var allSpecies: [String] {
        Array(Set(sessions.flatMap { $0.speciesNames }.filter { !$0.isEmpty })).sorted()
    }

    /// 时间线展示单元：一尾鱼 + 其所属的出钓
    private struct CatchEntry: Identifiable {
        let session: FishingSession
        let fish: FishCatch
        var id: UUID { fish.id }
    }

    /// 把所有出钓展开成「每尾鱼」一条，按出钓时间倒序、同次内按记录顺序
    private var displayEntries: [CatchEntry] {
        var entries: [CatchEntry] = []
        for session in sessions {
            let catches = session.catches.sorted { $0.sortIndex < $1.sortIndex }
            for fish in catches {
                if let species = filterSpecies, fish.speciesName != species { continue }
                entries.append(CatchEntry(session: session, fish: fish))
            }
        }
        return entries
    }

    private var grouped: [(String, [CatchEntry])] {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy年MM月"
        let dict = Dictionary(grouping: displayEntries) { fmt.string(from: $0.session.date) }
        return dict.sorted { $0.key > $1.key }
    }

    var body: some View {
        ZStack {
            Theme.Colors.bg.ignoresSafeArea()

            if sessions.isEmpty {
                emptyState
            } else {
                listContent
            }
        }
        .navigationTitle("钓鱼日记")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // TODO: 年份筛选
                } label: {
                    Text("2026 ▾")
                        .font(Theme.Font.subhead)
                        .foregroundStyle(Theme.Colors.ink2)
                }
            }
        }
    }

    // MARK: - 空态
    private var emptyState: some View {
        VStack(spacing: Theme.Space.lg) {
            Text("🎣")
                .font(.system(size: 64))
                .opacity(0.4)

            Text("还没有渔获记录")
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.Colors.ink)

            Text("出竿第一天，先把今天的渔获记下来吧。\n记录永远免费。")
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Colors.ink2)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - 列表内容
    private var listContent: some View {
        ScrollView {
            // 筛选 chip 行
            if !allSpecies.isEmpty {
                filterChips
                    .padding(.horizontal, Theme.Space.lg)
                    .padding(.top, Theme.Space.sm)
                    .padding(.bottom, Theme.Space.xs)
            }

            // 月份分组列表
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
                ForEach(grouped, id: \.0) { month, items in
                    monthSection(month: month, items: items)
                }
            }
            .padding(.horizontal, Theme.Space.lg)
            .padding(.bottom, 100) // 给 tab bar 留空间
        }
    }

    // MARK: - 筛选 Chip 行
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Space.sm) {
                ChipButton(title: "全部", isSelected: filterSpecies == nil) {
                    filterSpecies = nil
                }
                ForEach(allSpecies, id: \.self) { species in
                    ChipButton(title: species, isSelected: filterSpecies == species) {
                        filterSpecies = filterSpecies == species ? nil : species
                    }
                }
            }
        }
    }

    // MARK: - 月份 Section
    private func monthSection(month: String, items: [CatchEntry]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            SectionLabel(text: "\(month) · \(items.count) 尾")
                .padding(.top, Theme.Space.xl)
                .padding(.bottom, Theme.Space.xs)

            ForEach(items) { entry in
                NavigationLink(destination: SessionDetailView(session: entry.session, selectedCatch: entry.fish)) {
                    CatchCard(session: entry.session, fishCatch: entry.fish)
                }
                .buttonStyle(.plain)
                .padding(.bottom, Theme.Space.md)
            }
        }
    }
}

#Preview {
    NavigationStack {
        DiaryListView()
    }
    .modelContainer(for: [FishingSession.self, FishCatch.self], inMemory: true)
}
