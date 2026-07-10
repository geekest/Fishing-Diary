import SwiftUI
import SwiftData
import ImageIO
import UIKit

// MARK: - 日记时间线（主页）
struct DiaryListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \FishingSession.date, order: .reverse)
    private var sessions: [FishingSession]

    @State private var filterSpecies: String? = nil
    @State private var dateFilter: DiaryDateFilter = .all
    @AppStorage("diaryGridMode") private var isGrid = false

    private var filteredSessions: [FishingSession] {
        sessions.filter { dateFilter.contains($0.date) }
    }

    private var allSpecies: [String] {
        Array(Set(filteredSessions.flatMap { $0.speciesNames }.filter { !$0.isEmpty })).sorted()
    }

    private var availableYears: [Int] {
        Array(Set(sessions.map { Calendar.current.component(.year, from: $0.date) })).sorted(by: >)
    }

    private var availableMonths: [Date] {
        uniqueDates(matching: [.year, .month])
    }

    private var availableDays: [Date] {
        uniqueDates(matching: [.year, .month, .day])
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
        for session in filteredSessions {
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
                dateFilterMenu
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

            PrimaryButton(title: "生成演示记录") {
                insertSampleData()
            }
            .padding(.horizontal, Theme.Space.xl)

            Text("仅写入本机，可在详情页继续编辑。")
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.Colors.ink3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - 列表内容
    private var listContent: some View {
        VStack(spacing: 0) {
            // 筛选 chip 行（固定头部，独立于卡片滚动区，避免与卡片点击区重叠）
            if !allSpecies.isEmpty {
                filterChips
                    .padding(.horizontal, Theme.Space.lg)
                    .padding(.top, Theme.Space.sm)
                    .padding(.bottom, Theme.Space.sm)
            }

            // 月份分组列表（可滚动）
            if displayEntries.isEmpty {
                noResultState
            } else {
                ScrollView {
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
    }

    // MARK: - 日期筛选菜单
    private var dateFilterMenu: some View {
        Menu {
            Button {
                dateFilter = .all
                filterSpecies = nil
            } label: {
                Label("全部日期", systemImage: dateFilter == .all ? "checkmark" : "calendar")
            }

            if !availableDays.isEmpty {
                Section("按日期") {
                    ForEach(availableDays, id: \.self) { day in
                        Button {
                            dateFilter = .day(day)
                            filterSpecies = nil
                        } label: {
                            Label(dayLabel(day), systemImage: dateFilter.isSameDay(day) ? "checkmark" : "calendar.day.timeline.left")
                        }
                    }
                }
            }

            if !availableMonths.isEmpty {
                Section("按月份") {
                    ForEach(availableMonths, id: \.self) { month in
                        Button {
                            dateFilter = .month(month)
                            filterSpecies = nil
                        } label: {
                            Label(monthLabel(month), systemImage: dateFilter.isSameMonth(month) ? "checkmark" : "calendar")
                        }
                    }
                }
            }

            if !availableYears.isEmpty {
                Section("按年份") {
                    ForEach(availableYears, id: \.self) { year in
                        Button {
                            dateFilter = .year(year)
                            filterSpecies = nil
                        } label: {
                            Label("\(year) 年", systemImage: dateFilter == .year(year) ? "checkmark" : "calendar")
                        }
                    }
                }
            }
        } label: {
            Text("\(dateFilter.title) ▾")
                .font(Theme.Font.subhead)
                .foregroundStyle(Theme.Colors.ink2)
        }
    }

    // MARK: - 无筛选结果
    private var noResultState: some View {
        VStack(spacing: Theme.Space.md) {
            Spacer(minLength: 80)
            Text("没有匹配的渔获")
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.Colors.ink)
            Text("可以切换日期或鱼种筛选再看看")
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Colors.ink2)
            Button("查看全部日期") {
                dateFilter = .all
                filterSpecies = nil
            }
            .font(Theme.Font.subhead)
            .foregroundStyle(Theme.Colors.accent)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, Theme.Space.lg)
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

    private func uniqueDates(matching components: Set<Calendar.Component>) -> [Date] {
        let calendar = Calendar.current
        var seen = Set<String>()
        return sessions.compactMap { session in
            let values = calendar.dateComponents(components, from: session.date)
            guard let date = calendar.date(from: values) else { return nil }
            let key = dateKey(for: date, components: components)
            return seen.insert(key).inserted ? date : nil
        }
        .sorted(by: >)
    }

    private func dateKey(for date: Date, components: Set<Calendar.Component>) -> String {
        let fmt = DateFormatter()
        fmt.calendar = Calendar.current
        fmt.dateFormat = components.contains(.day) ? "yyyy-MM-dd" : "yyyy-MM"
        return fmt.string(from: date)
    }

    private func monthLabel(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy年M月"
        return fmt.string(from: date)
    }

    private func dayLabel(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy年M月d日"
        return fmt.string(from: date)
    }

    private func insertSampleData() {
        let calendar = Calendar.current
        let sampleImageData = sampleFishImageData()

        let weather = WeatherSnapshot(
            temperature: 24,
            windSpeed: 3.2,
            windDirection: "东南",
            pressure: 1012,
            uvIndex: 4,
            condition: "多云",
            waterTemp: 21,
            moonPhase: "上弦月",
            tide: "涨潮"
        )
        let weatherData = try? JSONEncoder().encode(weather)

        let firstCatch = FishCatch(
            speciesName: "翘嘴",
            lengthCm: 42,
            weightKg: 0.9,
            fishingMethod: "路亚",
            cutoutImageData: sampleImageData,
            originalImageData: sampleImageData,
            sortIndex: 0
        )
        let secondCatch = FishCatch(
            speciesName: "鲈鱼",
            lengthCm: 36,
            weightKg: 0.7,
            fishingMethod: "路亚",
            cutoutImageData: sampleImageData,
            originalImageData: sampleImageData,
            sortIndex: 1
        )
        let firstSession = FishingSession(
            date: calendar.date(byAdding: .day, value: -1, to: .now) ?? .now,
            locationName: "千岛湖 · 大坝南",
            latitude: 29.61,
            longitude: 119.03,
            catches: [firstCatch, secondCatch],
            weatherData: weatherData,
            coverImageData: sampleImageData,
            notes: "傍晚窗口期明显，亮片慢收更稳定。",
            fishingMethod: "路亚"
        )

        let thirdCatch = FishCatch(
            speciesName: "鲫鱼",
            lengthCm: 24,
            weightKg: 0.3,
            fishingMethod: "台钓",
            cutoutImageData: sampleImageData,
            originalImageData: sampleImageData,
            sortIndex: 0
        )
        let secondSession = FishingSession(
            date: calendar.date(byAdding: .day, value: -8, to: .now) ?? .now,
            locationName: "城市河道 · 老桥边",
            latitude: 30.24,
            longitude: 120.16,
            catches: [thirdCatch],
            weatherData: weatherData,
            coverImageData: sampleImageData,
            notes: "水色偏浑，换小钩后入口更干脆。",
            fishingMethod: "台钓"
        )

        [firstCatch, secondCatch, thirdCatch].forEach(modelContext.insert)
        modelContext.insert(firstSession)
        modelContext.insert(secondSession)
        try? modelContext.save()
    }

    private func sampleFishImageData() -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 640, height: 640))
        let image = renderer.image { context in
            UIColor(red: 0.90, green: 0.95, blue: 0.91, alpha: 1).setFill()
            context.cgContext.fill(CGRect(x: 0, y: 0, width: 640, height: 640))

            UIColor(red: 0.12, green: 0.40, blue: 0.34, alpha: 1).setFill()
            UIBezierPath(ovalIn: CGRect(x: 142, y: 238, width: 300, height: 140)).fill()

            let tail = UIBezierPath()
            tail.move(to: CGPoint(x: 438, y: 306))
            tail.addLine(to: CGPoint(x: 536, y: 232))
            tail.addLine(to: CGPoint(x: 536, y: 380))
            tail.close()
            tail.fill()

            UIColor.white.setFill()
            UIBezierPath(ovalIn: CGRect(x: 216, y: 278, width: 24, height: 24)).fill()
            UIColor.black.setFill()
            UIBezierPath(ovalIn: CGRect(x: 224, y: 286, width: 9, height: 9)).fill()
        }
        return image.pngData() ?? Data()
    }
}

// MARK: - 日期筛选条件
private enum DiaryDateFilter: Equatable {
    case all
    case year(Int)
    case month(Date)
    case day(Date)

    var title: String {
        let fmt = DateFormatter()
        switch self {
        case .all:
            return "全部日期"
        case .year(let year):
            return "\(year) 年"
        case .month(let date):
            fmt.dateFormat = "yyyy年M月"
            return fmt.string(from: date)
        case .day(let date):
            fmt.dateFormat = "M月d日"
            return fmt.string(from: date)
        }
    }

    func contains(_ date: Date) -> Bool {
        let calendar = Calendar.current
        switch self {
        case .all:
            return true
        case .year(let year):
            return calendar.component(.year, from: date) == year
        case .month(let month):
            return calendar.isDate(date, equalTo: month, toGranularity: .month)
        case .day(let day):
            return calendar.isDate(date, inSameDayAs: day)
        }
    }

    func isSameMonth(_ date: Date) -> Bool {
        guard case .month(let month) = self else { return false }
        return Calendar.current.isDate(month, equalTo: date, toGranularity: .month)
    }

    func isSameDay(_ date: Date) -> Bool {
        guard case .day(let day) = self else { return false }
        return Calendar.current.isDate(day, inSameDayAs: date)
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
