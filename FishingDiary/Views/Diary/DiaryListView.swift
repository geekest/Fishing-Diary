import SwiftUI
import SwiftData
import ImageIO

// MARK: - 日记时间线（主页）
struct DiaryListView: View {
    @Query(sort: \FishingSession.date, order: .reverse)
    private var sessions: [FishingSession]

    @State private var filterSpecies: String? = nil
    @AppStorage("diaryGridMode") private var isGrid = false

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
                    withAnimation(.easeInOut(duration: 0.2)) { isGrid.toggle() }
                } label: {
                    Image(systemName: isGrid ? "rectangle.grid.1x2" : "square.grid.2x2")
                        .foregroundStyle(Theme.Colors.ink2)
                }
            }
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
            VStack(alignment: .leading, spacing: 0) {
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

            if isGrid {
                doubleColumn(items)
            } else {
                singleColumn(items)
            }
        }
    }

    // MARK: - 单列（大卡）
    private func singleColumn(_ items: [CatchEntry]) -> some View {
        ForEach(items) { entry in
            NavigationLink(destination: SessionDetailView(session: entry.session, selectedCatch: entry.fish)) {
                CatchCard(session: entry.session, fishCatch: entry.fish)
            }
            .buttonStyle(.plain)
            .padding(.bottom, Theme.Space.md)
        }
    }

    // MARK: - 双列瀑布流（小红书式）
    private func doubleColumn(_ items: [CatchEntry]) -> some View {
        let columns = split(items)
        return HStack(alignment: .top, spacing: Theme.Space.md) {
            masonryColumn(columns.left)
            masonryColumn(columns.right)
        }
        .padding(.bottom, Theme.Space.md)
    }

    private func masonryColumn(_ column: [CatchEntry]) -> some View {
        LazyVStack(spacing: Theme.Space.md) {
            ForEach(column) { entry in
                NavigationLink(destination: SessionDetailView(session: entry.session, selectedCatch: entry.fish)) {
                    GridCatchCard(session: entry.session, fishCatch: entry.fish)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    /// 按图片比例做贪心分配，保证两列高度尽量均衡（瀑布流）
    private func split(_ items: [CatchEntry]) -> (left: [CatchEntry], right: [CatchEntry]) {
        var left: [CatchEntry] = []
        var right: [CatchEntry] = []
        var leftHeight: CGFloat = 0
        var rightHeight: CGFloat = 0
        for entry in items {
            let aspect = MasonryHelper.aspect(id: entry.fish.id, data: entry.fish.cutoutImageData)
            let estimated = aspect + 0.5   // 图片比例 + 文字区常量
            if leftHeight <= rightHeight {
                left.append(entry)
                leftHeight += estimated
            } else {
                right.append(entry)
                rightHeight += estimated
            }
        }
        return (left, right)
    }
}

// MARK: - 图片比例缓存（仅读图头，不解码整图）
private enum MasonryHelper {
    private static var cache: [UUID: CGFloat] = [:]

    /// 返回 高/宽，失败回退 1.0
    static func aspect(id: UUID, data: Data) -> CGFloat {
        if let hit = cache[id] { return hit }
        let value = compute(data)
        cache[id] = value
        return value
    }

    private static func compute(_ data: Data) -> CGFloat {
        guard !data.isEmpty,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let w = (props[kCGImagePropertyPixelWidth] as? NSNumber)?.doubleValue,
              let h = (props[kCGImagePropertyPixelHeight] as? NSNumber)?.doubleValue,
              w > 0 else { return 1.0 }
        return CGFloat(h / w)
    }
}

#Preview {
    NavigationStack {
        DiaryListView()
    }
    .modelContainer(for: [FishingSession.self, FishCatch.self], inMemory: true)
}
