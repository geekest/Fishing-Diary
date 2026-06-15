import SwiftUI
import SwiftData

// MARK: - 渔获详情页
struct SessionDetailView: View {
    let session: FishingSession
    @State private var selectedCatch: FishCatch?
    @State private var navigateToShare = false
    @State private var showEditSheet = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    init(session: FishingSession, selectedCatch: FishCatch? = nil) {
        self.session = session
        let initial = selectedCatch ?? session.catches.sorted { $0.sortIndex < $1.sortIndex }.first
        _selectedCatch = State(initialValue: initial)
    }

    private var sortedCatches: [FishCatch] {
        session.catches.sorted { $0.sortIndex < $1.sortIndex }
    }

    private var dateText: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MM.dd · "
        return fmt.string(from: session.date)
    }

    var body: some View {
        ZStack {
            Theme.Colors.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    heroSection
                    contentSection
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        modelContext.delete(session)
                        dismiss()
                    } label: {
                        Label("删除记录", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.white)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomActions
                .padding(.horizontal, Theme.Space.lg)
                .padding(.bottom, 16)
                .padding(.top, Theme.Space.md)
                .background(Theme.Colors.bg)
        }
        .navigationDestination(isPresented: $navigateToShare) {
            ShareStyleView(session: session, isRecordPresented: .constant(false))
        }
        .sheet(isPresented: $showEditSheet) {
            EditSessionSheet(session: session, fishCatch: selectedCatch)
        }
    }

    // MARK: - 英雄照片区
    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            // 背景图（当前选中的鱼）
            Group {
                if let c = selectedCatch, let img = UIImage(data: c.cutoutImageData) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Theme.Colors.catchGradient(for: session.id)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .clipped()

            // 渐变蒙层
            LinearGradient(
                colors: [.clear, .clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )

            // 体长大数字 + 鱼种
            VStack(alignment: .leading, spacing: 4) {
                if let len = selectedCatch?.lengthCm {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(Int(len))")
                            .font(Theme.Font.displayNumber)
                            .foregroundStyle(.white)
                        Text("cm")
                            .font(Theme.Font.subhead)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }

                if let species = selectedCatch?.speciesName, !species.isEmpty {
                    Text(species)
                        .font(Theme.Font.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }

                // 学名（可扩展为真实数据）
                let latinName = latinName(for: selectedCatch?.speciesName ?? "")
                if !latinName.isEmpty {
                    Text(latinName)
                        .font(Theme.Font.microLabel)
                        .kerning(1.5)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, Theme.Space.lg)
            .padding(.bottom, Theme.Space.xl)

            // 右上角日期
            VStack {
                HStack {
                    Spacer()
                    Text(dateText + (session.locationName.isEmpty ? "" : session.locationName))
                        .font(Theme.Font.microLabel)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(.black.opacity(0.35))
                        .clipShape(Capsule())
                }
                .padding(.top, 56)
                .padding(.trailing, Theme.Space.lg)
                Spacer()
            }
        }
        .frame(height: 300)
    }

    // MARK: - 内容区
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.lg) {
            // 环境数据
            if let weather = session.weather {
                environmentSection(weather: weather)
            }

            // 钓点信息
            if !session.locationName.isEmpty {
                locationSection
            }

            // 渔获列表
            if !sortedCatches.isEmpty {
                catchesSection
            }
        }
        .padding(.horizontal, Theme.Space.lg)
        .padding(.top, Theme.Space.xl)
        .padding(.bottom, 80)
    }

    // MARK: - 环境数据网格
    private func environmentSection(weather: WeatherSnapshot) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            SectionLabel(text: "环境数据 · 自动抓取")

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Theme.Space.sm), count: 3),
                      spacing: Theme.Space.sm) {
                if weather.temperature > 0 {
                    EnvCell(value: "\(Int(weather.temperature))°C", label: "气温")
                }
                if weather.pressure > 0 {
                    EnvCell(value: "\(Int(weather.pressure))", label: "气压 hPa")
                }
                if weather.windSpeed > 0 {
                    EnvCell(value: "\(weather.windDirection) \(String(format: "%.1f", weather.windSpeed))", label: "风速")
                }
                if let tide = weather.tide, !tide.isEmpty {
                    EnvCell(value: tide, label: "潮汐")
                }
                if weather.uvIndex > 0 {
                    EnvCell(value: "UVI \(weather.uvIndex)", label: "紫外线")
                }
                if !weather.condition.isEmpty {
                    EnvCell(value: weather.condition, label: "天气")
                }
            }
        }
    }

    // MARK: - 钓点
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            SectionLabel(text: "钓点")

            HStack(spacing: Theme.Space.md) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.Colors.accent)
                VStack(alignment: .leading, spacing: 3) {
                    Text(session.locationName)
                        .font(Theme.Font.subhead)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.Colors.ink)
                    if let lat = session.latitude, let lon = session.longitude {
                        Text(String(format: "N%.4f° E%.4f°", lat, lon))
                            .font(Theme.Font.microLabel)
                            .foregroundStyle(Theme.Colors.ink3)
                    }
                }
                Spacer()
            }
            .padding(Theme.Space.md)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field))
            .shadowSoft()
        }
    }

    // MARK: - 渔获列表（本次出钓的全部鱼，可点选切换）
    private var catchesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            SectionLabel(text: "本次出钓 · \(sortedCatches.count) 尾")

            VStack(spacing: Theme.Space.sm) {
                ForEach(sortedCatches) { catch_ in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCatch = catch_
                        }
                    } label: {
                        catchRow(catch_, isSelected: selectedCatch?.id == catch_.id)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func catchRow(_ fishCatch: FishCatch, isSelected: Bool) -> some View {
        HStack(spacing: Theme.Space.md) {
            // 抠图
            Group {
                if let img = UIImage(data: fishCatch.cutoutImageData) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: "fish.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Theme.Colors.ink3)
                }
            }
            .frame(width: 64, height: 80)
            .background(Theme.Colors.accentSoft)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 5) {
                Text(fishCatch.speciesName.isEmpty ? "未知鱼种" : fishCatch.speciesName)
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Colors.ink)

                if let len = fishCatch.lengthCm {
                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                        Text("\(Int(len))")
                            .font(Theme.Font.data(20, weight: .medium))
                            .foregroundStyle(Theme.Colors.ink)
                        Text("cm")
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.Colors.ink2)
                    }
                }

                if let kg = fishCatch.weightKg {
                    Text(String(format: "%.2f kg", kg))
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Colors.ink2)
                }
            }

            Spacer()

            if isSelected {
                Text("查看中")
                    .font(Theme.Font.microLabel)
                    .foregroundStyle(Theme.Colors.accent)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink3)
            }
        }
        .padding(Theme.Space.md)
        .background(isSelected ? Theme.Colors.accentSoft : Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.field)
                .stroke(isSelected ? Theme.Colors.accent : Color.clear, lineWidth: 1.5)
        )
        .shadowSoft()
    }

    // MARK: - 底部操作
    private var bottomActions: some View {
        HStack(spacing: Theme.Space.md) {
            GhostButton(title: "编辑") {
                showEditSheet = true
            }
            .frame(maxWidth: 120)

            PrimaryButton(title: "✦ 生成分享图") {
                navigateToShare = true
            }
        }
    }

    // MARK: - 鱼种学名映射
    private func latinName(for species: String) -> String {
        let map: [String: String] = [
            "大口黑鲈": "MICROPTERUS SALMOIDES",
            "鳜鱼": "SINIPERCA CHUATSI",
            "翘嘴鲌": "ERYTHROCULTER ILISHAEFORMIS",
            "鲤鱼": "CYPRINUS CARPIO",
            "草鱼": "CTENOPHARYNGODON IDELLA",
            "鲫鱼": "CARASSIUS AURATUS",
            "黑鱼": "CHANNA ARGUS",
            "罗非鱼": "OREOCHROMIS NILOTICUS",
        ]
        return map[species] ?? ""
    }
}

// MARK: - 编辑 Sheet
struct EditSessionSheet: View {
    let session: FishingSession
    let fishCatch: FishCatch?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var speciesName: String = ""
    @State private var lengthCm: String = ""
    @State private var weightKg: String = ""
    @State private var notes: String = ""
    @FocusState private var focusedField: EditField?

    private enum EditField { case length, weight, notes }

    /// 待编辑的鱼（详情页当前选中的那尾，回退到第一尾）
    private var editingCatch: FishCatch? {
        fishCatch ?? session.catches.min(by: { $0.sortIndex < $1.sortIndex })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Space.md) {
                        formSection
                    }
                    .padding(.horizontal, Theme.Space.lg)
                    .padding(.top, Theme.Space.lg)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("编辑记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(Theme.Colors.accent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") { save() }
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.Colors.accent)
                }
            }
        }
        .onAppear {
            speciesName = editingCatch?.speciesName ?? ""
            lengthCm = editingCatch?.lengthCm.map { "\(Int($0))" } ?? ""
            weightKg = editingCatch?.weightKg.map { String(format: "%.2f", $0) } ?? ""
            notes = session.notes ?? ""
        }
    }

    private var formSection: some View {
        VStack(spacing: 0) {
            // 鱼种
            VStack(alignment: .leading, spacing: 5) {
                Text("鱼种".uppercased())
                    .font(Theme.Font.microLabel)
                    .kerning(0.5)
                    .foregroundStyle(Theme.Colors.ink3)
                TextField("鱼种名称", text: $speciesName)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Colors.ink)
            }
            .padding(Theme.Space.md)

            Divider().padding(.horizontal, Theme.Space.md)

            // 体长 + 重量
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("体长 cm".uppercased())
                        .font(Theme.Font.microLabel)
                        .kerning(0.5)
                        .foregroundStyle(Theme.Colors.ink3)
                    TextField("38", text: $lengthCm)
                        .font(Theme.Font.data(24, weight: .medium))
                        .foregroundStyle(Theme.Colors.ink)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .length)
                }
                .padding(Theme.Space.md)
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider().frame(height: 56)

                VStack(alignment: .leading, spacing: 5) {
                    Text("重量 kg".uppercased())
                        .font(Theme.Font.microLabel)
                        .kerning(0.5)
                        .foregroundStyle(Theme.Colors.ink3)
                    TextField("选填", text: $weightKg)
                        .font(Theme.Font.data(24, weight: .medium))
                        .foregroundStyle(Theme.Colors.ink)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .weight)
                }
                .padding(Theme.Space.md)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider().padding(.horizontal, Theme.Space.md)

            // 备注
            VStack(alignment: .leading, spacing: 5) {
                Text("备注".uppercased())
                    .font(Theme.Font.microLabel)
                    .kerning(0.5)
                    .foregroundStyle(Theme.Colors.ink3)
                TextField("记录这次钓鱼的故事…", text: $notes, axis: .vertical)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .lineLimit(3...5)
                    .focused($focusedField, equals: .notes)
            }
            .padding(Theme.Space.md)
        }
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .shadowSoft()
    }

    private func save() {
        if let catch_ = editingCatch {
            catch_.speciesName = speciesName.isEmpty ? catch_.speciesName : speciesName
            catch_.lengthCm = Double(lengthCm)
            catch_.weightKg = Double(weightKg)
        }
        session.notes = notes.isEmpty ? nil : notes
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        SessionDetailView(session: {
            let s = FishingSession(date: .now, locationName: "千岛湖 · 大坝南区")
            s.latitude = 29.6
            s.longitude = 119.0
            let w = WeatherSnapshot(
                temperature: 22, windSpeed: 3.2, windDirection: "SE",
                pressure: 1014, uvIndex: 5, condition: "多云",
                waterTemp: 18.5, moonPhase: "上弦", tide: "涨潮"
            )
            s.weatherData = try? JSONEncoder().encode(w)
            return s
        }())
    }
    .modelContainer(for: [FishingSession.self, FishCatch.self], inMemory: true)
}
