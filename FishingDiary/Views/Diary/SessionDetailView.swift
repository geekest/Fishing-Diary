import SwiftUI
import SwiftData
import MapKit
import PhotosUI

// MARK: - 渔获详情页
struct SessionDetailView: View {
    let session: FishingSession
    @State private var selectedCatch: FishCatch?
    @State private var navigateToShare = false
    @State private var showEditSheet = false
    @State private var showMapDetail = false
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

    /// 钓点坐标（无坐标时为 nil，回退文字卡片）
    private var coordinate: CLLocationCoordinate2D? {
        guard let lat = session.latitude, let lon = session.longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
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
        .fullScreenCover(isPresented: $showMapDetail) {
            if let coord = coordinate {
                MapDetailView(coordinate: coord, name: session.locationName)
            }
        }
        .hidesFloatingTabBar()
    }

    // MARK: - 英雄照片区
    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            // 背景图（当前选中的鱼）—— 用 Color.clear 定宽容器，避免 scaledToFill 撑宽整页
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .overlay {
                    if let c = selectedCatch, let img = UIImage(data: c.cutoutImageData) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Theme.Colors.catchGradient(for: session.id)
                    }
                }
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

            if let coord = coordinate {
                mapCard(coord)
            } else {
                locationTextCard
            }
        }
    }

    /// 地图卡片（点击进入全屏地图）
    private func mapCard(_ coord: CLLocationCoordinate2D) -> some View {
        ZStack(alignment: .bottomLeading) {
            Map(initialPosition: .region(SpotMap.region(for: coord)), interactionModes: []) {
                Annotation("", coordinate: coord) {
                    SpotMarkerView()
                }
            }
            .frame(height: 160)
            .allowsHitTesting(false)

            // 底部地名条
            HStack(spacing: 6) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(Theme.Colors.accent)
                Text(session.locationName.isEmpty ? "未知钓点" : session.locationName)
                    .font(Theme.Font.subhead)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Colors.ink)
                Spacer()
                Text("查看地图 ›")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Colors.accent)
            }
            .padding(.horizontal, Theme.Space.md)
            .padding(.vertical, Theme.Space.sm)
            .background(.ultraThinMaterial)
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.field)
                .stroke(Theme.Colors.hairline, lineWidth: 1)
        )
        .shadowSoft()
        .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.field))
        .onTapGesture { showMapDetail = true }
    }

    /// 无坐标时的文字卡片回退
    private var locationTextCard: some View {
        HStack(spacing: Theme.Space.md) {
            Image(systemName: "mappin.circle.fill")
                .font(.title2)
                .foregroundStyle(Theme.Colors.accent)
            VStack(alignment: .leading, spacing: 3) {
                Text(session.locationName.isEmpty ? "未知钓点" : session.locationName)
                    .font(Theme.Font.subhead)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Colors.ink)
                Text("本次记录未带定位")
                    .font(Theme.Font.microLabel)
                    .foregroundStyle(Theme.Colors.ink3)
            }
            Spacer()
        }
        .padding(Theme.Space.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field))
        .shadowSoft()
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
                    Text(String(format: "%.1f kg", kg))
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

    // MARK: - 底部操作（编辑 / 生成分享图 / 更多，三者等大）
    private var bottomActions: some View {
        HStack(spacing: Theme.Space.md) {
            Button {
                showEditSheet = true
            } label: {
                actionLabel(icon: "slider.horizontal.3", label: "编辑", highlighted: false)
            }
            .buttonStyle(ScaleButtonStyle())

            Button {
                navigateToShare = true
            } label: {
                actionLabel(icon: "sparkles", label: "生成分享图", highlighted: true)
            }
            .buttonStyle(ScaleButtonStyle())

            // 更多：用 Menu，弹层锚定在按钮上（不再飞到顶部）
            Menu {
                Button(role: .destructive) {
                    modelContext.delete(session)
                    try? modelContext.save()
                    dismiss()
                } label: {
                    Label("删除记录", systemImage: "trash")
                }
            } label: {
                actionLabel(icon: "ellipsis", label: "更多", highlighted: false)
            }
        }
    }

    private func actionLabel(icon: String, label: String, highlighted: Bool) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 18))
            Text(label)
                .font(Theme.Font.caption)
        }
        .foregroundStyle(highlighted ? Theme.Colors.accent : Theme.Colors.ink2)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(highlighted ? Theme.Colors.accentSoft : Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.field)
                .stroke(highlighted ? Theme.Colors.accent.opacity(0.35) : Theme.Colors.hairline, lineWidth: 1)
        )
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

// MARK: - 单尾鱼的可编辑模型
struct FishEditModel: Identifiable {
    let id: UUID            // 对应 FishCatch.id
    var species: String
    var length: String
    var weight: String
    var method: String
    var image: UIImage?     // 展示用（抠图/原图），换图后更新
    var newOriginal: UIImage?   // 换图后的新原图（待保存）
    var newCutout: UIImage?     // 换图后的新抠图（待保存）
}

// MARK: - 编辑 Sheet（图片 / 鱼获信息 / 环境）
struct EditSessionSheet: View {
    let session: FishingSession
    let fishCatch: FishCatch?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var fishEdits: [FishEditModel] = []
    @State private var locationName: String = ""
    @State private var conditionText: String = ""
    @State private var temperatureText: String = ""
    @State private var pressureText: String = ""
    @State private var windDirText: String = ""
    @State private var windSpeedText: String = ""
    @State private var waterTempText: String = ""
    @State private var tideText: String = ""
    @State private var moonPhaseText: String = ""
    @State private var uvText: String = ""
    @State private var notes: String = ""

    private let methodOptions = ["路亚", "台钓", "矶钓", "筏钓", "其他"]
    private let moonOptions = ["新月", "上弦", "满月", "下弦"]

    @State private var showPicker = false
    @State private var pickingFishID: UUID? = nil
    @State private var pickerItem: PhotosPickerItem? = nil
    @State private var processingFishID: UUID? = nil

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
        .onAppear(perform: populate)
        .photosPicker(isPresented: $showPicker, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            loadReplacement(item)
        }
    }

    // MARK: - 初始化表单
    private func populate() {
        fishEdits = session.catches
            .sorted { $0.sortIndex < $1.sortIndex }
            .map { c in
                FishEditModel(
                    id: c.id,
                    species: c.speciesName,
                    length: c.lengthCm.map { trimNumber($0) } ?? "",
                    weight: c.weightKg.map { String(format: "%.1f", $0) } ?? "",
                    method: c.fishingMethod,
                    image: UIImage(data: c.cutoutImageData)
                )
            }
        locationName = session.locationName
        notes = session.notes ?? ""
        if let w = session.weather {
            conditionText = w.condition
            temperatureText = w.temperature > 0 ? "\(Int(w.temperature))" : ""
            pressureText = w.pressure > 0 ? "\(Int(w.pressure))" : ""
            windDirText = w.windDirection
            windSpeedText = w.windSpeed > 0 ? String(format: "%.1f", w.windSpeed) : ""
            waterTempText = w.waterTemp.map { trimNumber($0) } ?? ""
            tideText = w.tide ?? ""
            moonPhaseText = w.moonPhase ?? ""
            uvText = w.uvIndex > 0 ? "\(w.uvIndex)" : ""
        }
    }

    // MARK: - 换图 + 自动重新抠图
    private func loadReplacement(_ item: PhotosPickerItem) {
        guard let fishID = pickingFishID else { return }
        processingFishID = fishID
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let original = UIImage(data: data) else {
                await MainActor.run { processingFishID = nil }
                return
            }
            let normalized = original.normalizedUp()
            let cutout = await SubjectCutoutService.liftSubject(from: normalized)
            await MainActor.run {
                if let idx = fishEdits.firstIndex(where: { $0.id == fishID }) {
                    fishEdits[idx].newOriginal = normalized
                    fishEdits[idx].newCutout = cutout ?? normalized
                    fishEdits[idx].image = cutout ?? normalized
                }
                processingFishID = nil
                pickerItem = nil
            }
        }
    }

    private var formSection: some View {
        VStack(spacing: Theme.Space.xl) {
            fishEditSection
            environmentEditSection
            notesEditSection
        }
    }

    // MARK: - 鱼获编辑
    private var fishEditSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            SectionLabel(text: "渔获 · \(fishEdits.count) 尾")
            ForEach($fishEdits) { $edit in
                fishEditCard($edit)
            }
        }
    }

    private func fishEditCard(_ edit: Binding<FishEditModel>) -> some View {
        HStack(spacing: Theme.Space.md) {
            // 图片（点击换图）
            Button {
                pickingFishID = edit.wrappedValue.id
                showPicker = true
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.Colors.accentSoft)
                        .frame(width: 64, height: 80)
                    if let img = edit.wrappedValue.image {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 76)
                    } else {
                        Image(systemName: "photo")
                            .foregroundStyle(Theme.Colors.ink3)
                    }
                    if processingFishID == edit.wrappedValue.id {
                        RoundedRectangle(cornerRadius: 10).fill(.black.opacity(0.35))
                            .frame(width: 64, height: 80)
                        ProgressView().tint(.white)
                    }
                }
                .overlay(alignment: .bottom) {
                    Text("换图")
                        .font(Theme.Font.microLabel)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 2)
                        .background(.black.opacity(0.45))
                }
                .frame(width: 64, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            VStack(spacing: Theme.Space.sm) {
                TextField("鱼种", text: edit.species)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Colors.ink)
                Divider()
                HStack(spacing: Theme.Space.md) {
                    HStack(spacing: 4) {
                        TextField("体长", text: edit.length)
                            .font(Theme.Font.data(18, weight: .medium))
                            .keyboardType(.decimalPad)
                            .frame(width: 52)
                        Text("cm").font(Theme.Font.caption).foregroundStyle(Theme.Colors.ink3)
                    }
                    HStack(spacing: 4) {
                        TextField("重量", text: edit.weight)
                            .font(Theme.Font.data(18, weight: .medium))
                            .keyboardType(.decimalPad)
                            .frame(width: 52)
                        Text("kg").font(Theme.Font.caption).foregroundStyle(Theme.Colors.ink3)
                    }
                    Spacer()
                }
                methodPicker(edit)
            }
        }
        .padding(Theme.Space.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field))
        .shadowSoft()
    }

    private func methodPicker(_ edit: Binding<FishEditModel>) -> some View {
        Menu {
            Button("未填写") { edit.wrappedValue.method = "" }
            ForEach(methodOptions, id: \.self) { method in
                Button(method) { edit.wrappedValue.method = method }
            }
        } label: {
            HStack {
                Text("钓法")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Colors.ink2)
                Spacer()
                Text(edit.wrappedValue.method.isEmpty ? "未填写" : edit.wrappedValue.method)
                    .font(Theme.Font.caption)
                    .foregroundStyle(edit.wrappedValue.method.isEmpty ? Theme.Colors.ink3 : Theme.Colors.accent)
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.ink3)
            }
        }
        .padding(.top, 2)
    }

    // MARK: - 环境编辑
    private var environmentEditSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            SectionLabel(text: "环境数据")
            VStack(spacing: 0) {
                editRow("钓点", text: $locationName)
                Divider().padding(.leading, Theme.Space.md)
                editRow("天气", text: $conditionText)
                Divider().padding(.leading, Theme.Space.md)
                editRow("气温 °C", text: $temperatureText, keyboard: .numbersAndPunctuation)
                Divider().padding(.leading, Theme.Space.md)
                editRow("气压 hPa", text: $pressureText, keyboard: .numberPad)
                Divider().padding(.leading, Theme.Space.md)
                editRow("风向", text: $windDirText)
                Divider().padding(.leading, Theme.Space.md)
                editRow("风速 m/s", text: $windSpeedText, keyboard: .decimalPad)
                Divider().padding(.leading, Theme.Space.md)
                editRow("水温 °C", text: $waterTempText, keyboard: .decimalPad)
                Divider().padding(.leading, Theme.Space.md)
                editRow("潮汐", text: $tideText)
                Divider().padding(.leading, Theme.Space.md)
                enumEditRow("月相", selection: $moonPhaseText, options: moonOptions)
                Divider().padding(.leading, Theme.Space.md)
                editRow("紫外线 UVI", text: $uvText, keyboard: .numberPad)
            }
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field))
            .shadowSoft()
        }
    }

    private func editRow(_ label: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        HStack(spacing: Theme.Space.md) {
            Text(label)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Colors.ink2)
                .frame(width: 96, alignment: .leading)
            TextField("未填写", text: text)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Colors.ink)
                .keyboardType(keyboard)
        }
        .padding(.horizontal, Theme.Space.md)
        .padding(.vertical, 14)
    }

    private func enumEditRow(_ label: String, selection: Binding<String>, options: [String]) -> some View {
        HStack(spacing: Theme.Space.md) {
            Text(label)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Colors.ink2)
                .frame(width: 96, alignment: .leading)
            Spacer()
            Menu {
                Button("未填写") { selection.wrappedValue = "" }
                ForEach(options, id: \.self) { option in
                    Button(option) { selection.wrappedValue = option }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selection.wrappedValue.isEmpty ? "未填写" : selection.wrappedValue)
                        .font(Theme.Font.body)
                        .foregroundStyle(selection.wrappedValue.isEmpty ? Theme.Colors.ink3 : Theme.Colors.ink)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.ink3)
                }
            }
        }
        .padding(.horizontal, Theme.Space.md)
        .padding(.vertical, 14)
    }

    // MARK: - 备注编辑
    private var notesEditSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            SectionLabel(text: "备注")
            TextField("记录这次钓鱼的故事…", text: $notes, axis: .vertical)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Colors.ink)
                .lineLimit(3...6)
                .padding(Theme.Space.md)
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field))
                .shadowSoft()
        }
    }

    private func save() {
        let byID = Dictionary(session.catches.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })

        for edit in fishEdits {
            guard let c = byID[edit.id] else { continue }
            c.speciesName = edit.species.trimmingCharacters(in: .whitespacesAndNewlines)
            c.lengthCm = normalizedDouble(edit.length)
            c.weightKg = normalizedDouble(edit.weight).map { ($0 * 10).rounded() / 10 }   // 统一一位小数
            c.fishingMethod = edit.method
            if let orig = edit.newOriginal, let d = orig.jpegData(compressionQuality: 0.8) {
                c.originalImageData = d
            }
            if let cut = edit.newCutout, let d = cut.pngData() {
                c.cutoutImageData = d
            }
            if edit.newOriginal != nil || edit.newCutout != nil {
                SubjectCutoutService.clearCardCache(id: c.id)
            }
        }

        // 封面用第一尾的图
        if let first = session.catches.min(by: { $0.sortIndex < $1.sortIndex }) {
            session.coverImageData = first.cutoutImageData
        }

        session.locationName = locationName.trimmingCharacters(in: .whitespacesAndNewlines)
        session.fishingMethod = fishEdits.first(where: { !$0.method.isEmpty })?.method ?? ""

        // 环境数据：有任意填写或原本就有才写入
        let weatherFields = [temperatureText, pressureText, windSpeedText, windDirText, conditionText, waterTempText, tideText, moonPhaseText, uvText]
        if session.weather != nil || weatherFields.contains(where: { !$0.isEmpty }) {
            var w = session.weather ?? WeatherSnapshot(
                temperature: 0, windSpeed: 0, windDirection: "", pressure: 0,
                uvIndex: 0, condition: "", waterTemp: nil, moonPhase: nil, tide: nil
            )
            w.temperature = normalizedDouble(temperatureText) ?? 0
            w.pressure = normalizedDouble(pressureText) ?? 0
            w.windSpeed = normalizedDouble(windSpeedText) ?? 0
            w.windDirection = windDirText.trimmingCharacters(in: .whitespacesAndNewlines)
            w.condition = conditionText.trimmingCharacters(in: .whitespacesAndNewlines)
            w.waterTemp = normalizedDouble(waterTempText)
            w.tide = normalizedOptionalText(tideText)
            w.moonPhase = normalizedOptionalText(moonPhaseText)
            w.uvIndex = Int(uvText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            session.weather = w
        }

        session.notes = normalizedOptionalText(notes)
        try? modelContext.save()
        dismiss()
    }

    private func normalizedDouble(_ value: String) -> Double? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed)
    }

    private func trimNumber(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(format: "%.1f", value)
    }

    private func normalizedOptionalText(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

// MARK: - 地图区域 + 醒目标记
private enum SpotMap {
    static func region(for coord: CLLocationCoordinate2D) -> MKCoordinateRegion {
        MKCoordinateRegion(center: coord,
                           span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
    }
}

private struct SpotMarkerView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.Colors.accent)
                .frame(width: 34, height: 34)
                .overlay(Circle().stroke(.white, lineWidth: 3))
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
            Image(systemName: "fish.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - 全屏地图详情
struct MapDetailView: View {
    let coordinate: CLLocationCoordinate2D
    let name: String
    @Environment(\.dismiss) private var dismiss
    @State private var position: MapCameraPosition

    init(coordinate: CLLocationCoordinate2D, name: String) {
        self.coordinate = coordinate
        self.name = name
        _position = State(initialValue: .region(SpotMap.region(for: coordinate)))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map(position: $position) {
                    Annotation("", coordinate: coordinate) {
                        SpotMarkerView()
                    }
                }
                .ignoresSafeArea(edges: .bottom)

                infoCard
                    .padding(Theme.Space.lg)
            }
            .navigationTitle("钓点位置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        openInAppleMaps()
                    } label: {
                        Label("在地图打开", systemImage: "arrow.up.right.square")
                    }
                }
            }
        }
    }

    private var infoCard: some View {
        HStack(spacing: Theme.Space.md) {
            Image(systemName: "mappin.circle.fill")
                .font(.title2)
                .foregroundStyle(Theme.Colors.accent)
            VStack(alignment: .leading, spacing: 3) {
                Text(name.isEmpty ? "未知钓点" : name)
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Colors.ink)
                Text(String(format: "N%.4f°  E%.4f°", coordinate.latitude, coordinate.longitude))
                    .font(Theme.Font.microLabel)
                    .foregroundStyle(Theme.Colors.ink3)
            }
            Spacer()
        }
        .padding(Theme.Space.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .shadowCard()
    }

    private func openInAppleMaps() {
        let placemark = MKPlacemark(coordinate: coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = name.isEmpty ? "钓点" : name
        item.openInMaps()
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
