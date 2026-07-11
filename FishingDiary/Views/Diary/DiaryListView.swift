import SwiftUI
import SwiftData
import ImageIO

// MARK: - 日记时间线（主页）
struct DiaryListView: View {
    @Query(sort: \FishingSession.date, order: .reverse)
    private var sessions: [FishingSession]

    @State private var filterSpecies: String? = nil
    @State private var dateFilter: DiaryDateFilter = .all
    @State private var showsDateFilter = false
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

    private var calendarDays: [Date] {
        guard let newest = availableDays.first, let oldest = availableDays.last else { return [] }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: oldest)
        let end = calendar.startOfDay(for: newest)
        let dayCount = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return (0...dayCount).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: end)
        }
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
                dateFilterButton
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

    // MARK: - 日期筛选入口
    private var dateFilterButton: some View {
        Button {
            showsDateFilter = true
        } label: {
            Text("\(dateFilter.title) ▾")
                .font(Theme.Font.subhead)
                .foregroundStyle(Theme.Colors.ink2)
        }
        .popover(isPresented: $showsDateFilter) {
            dateFilterPanel
                .presentationCompactAdaptation(.sheet)
        }
    }

    private var dateFilterPanel: some View {
        VStack(alignment: .leading, spacing: Theme.Space.lg) {
            HStack {
                Text("筛选日期")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Colors.ink)
                Spacer()
                Button("完成") {
                    showsDateFilter = false
                }
                .font(Theme.Font.subhead)
                .foregroundStyle(Theme.Colors.accent)
            }

            Button {
                dateFilter = .all
                filterSpecies = nil
            } label: {
                HStack(spacing: Theme.Space.sm) {
                    Image(systemName: dateFilter == .all ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(dateFilter == .all ? Theme.Colors.accent : Theme.Colors.ink3)
                    Text("全部日期")
                        .font(Theme.Font.subhead)
                        .foregroundStyle(Theme.Colors.ink)
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            if !availableDays.isEmpty {
                filterSectionTitle("按日期")
                dayCalendarStrip
            }

            if !availableMonths.isEmpty {
                filterSectionTitle("按月份")
                wheelOrSingleOption(
                    title: "月份",
                    values: availableMonths,
                    selection: selectedMonthBinding,
                    label: monthLabel
                )
            }

            if !availableYears.isEmpty {
                filterSectionTitle("按年份")
                wheelOrSingleOption(
                    title: "年份",
                    values: availableYears,
                    selection: selectedYearBinding,
                    label: { "\($0) 年" }
                )
            }
        }
        .padding(Theme.Space.lg)
        .frame(width: 340)
        .background(Theme.Colors.surface)
    }

    private func filterSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(Theme.Font.caption)
            .foregroundStyle(Theme.Colors.ink3)
    }

    private var dayCalendarStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Space.sm) {
                ForEach(calendarDays, id: \.self) { day in
                    dayCalendarCell(day)
                }
            }
            .padding(.vertical, Theme.Space.xs)
        }
    }

    private func dayCalendarCell(_ day: Date) -> some View {
        let hasRecord = hasSession(on: day)
        let isSelected = dateFilter.isSameDay(day)
        return Button {
            guard hasRecord else { return }
            dateFilter = .day(day)
            filterSpecies = nil
        } label: {
            VStack(spacing: 6) {
                Text(weekdayLabel(day))
                    .font(Theme.Font.microLabel)
                    .foregroundStyle(isSelected ? .white.opacity(0.85) : Theme.Colors.ink3)
                Text(dayNumberLabel(day))
                    .font(Theme.Font.headline)
                    .foregroundStyle(isSelected ? .white : (hasRecord ? Theme.Colors.ink : Theme.Colors.ink3))
                Circle()
                    .fill(hasRecord ? (isSelected ? .white : Theme.Colors.accent) : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(width: 58, height: 72)
            .background(isSelected ? Theme.Colors.accent : Theme.Colors.bg2)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .opacity(hasRecord ? 1 : 0.55)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(dayLabel(day))
        .disabled(!hasRecord)
    }

    private func wheelOrSingleOption<Value: Hashable>(
        title: String,
        values: [Value],
        selection: Binding<Value>,
        label: @escaping (Value) -> String
    ) -> some View {
        Group {
            if values.count > 1 {
                Picker(title, selection: selection) {
                    ForEach(values, id: \.self) { value in
                        Text(label(value)).tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 112)
                .clipped()
            } else if let value = values.first {
                Button {
                    selection.wrappedValue = value
                } label: {
                    HStack {
                        Text(label(value))
                            .font(Theme.Font.subhead)
                            .foregroundStyle(Theme.Colors.ink)
                        Spacer()
                        Image(systemName: "checkmark")
                            .foregroundStyle(Theme.Colors.accent)
                    }
                    .padding(.horizontal, Theme.Space.md)
                    .padding(.vertical, Theme.Space.sm)
                    .background(Theme.Colors.bg2)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .onChange(of: selection.wrappedValue) { _, _ in
            filterSpecies = nil
        }
    }

    private var selectedMonthBinding: Binding<Date> {
        Binding(
            get: {
                if case .month(let month) = dateFilter,
                   let availableMonth = availableMonths.first(where: { Calendar.current.isDate($0, equalTo: month, toGranularity: .month) }) {
                    return availableMonth
                }
                return availableMonths.first ?? .now
            },
            set: { dateFilter = .month($0) }
        )
    }

    private var selectedYearBinding: Binding<Int> {
        Binding(
            get: {
                if case .year(let year) = dateFilter, availableYears.contains(year) {
                    return year
                }
                return availableYears.first ?? Calendar.current.component(.year, from: .now)
            },
            set: { dateFilter = .year($0) }
        )
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

    private func hasSession(on date: Date) -> Bool {
        availableDays.contains { Calendar.current.isDate($0, inSameDayAs: date) }
    }

    private func weekdayLabel(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "zh_CN")
        fmt.dateFormat = "E"
        return fmt.string(from: date)
    }

    private func dayNumberLabel(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d"
        return fmt.string(from: date)
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
