import SwiftUI

// MARK: - 填写渔获信息
struct FishFormView: View {
    @Binding var isRecordPresented: Bool
    @EnvironmentObject var recordSession: RecordSession
    @AppStorage("defaultWeightUnit") private var defaultWeightUnitRaw = WeightUnit.kg.rawValue

    @State private var navigateToEnv = false
    @State private var showSpeciesPicker = false
    @State private var showRecut = false
    @FocusState private var focusedField: Field?

    private enum Field { case length, weight, notes }

    private let methodOptions = ["路亚", "台钓", "矶钓", "筏钓", "其他"]

    private var currentIndex: Int { recordSession.currentFishIndex }
    private var total: Int { recordSession.fishForms.count }
    private var currentRaw: UIImage? { recordSession.rawImages[safe: currentIndex] }

    // 重量单位切换（kg / 斤）
    private var unitToggle: some View {
        HStack(spacing: 0) {
            ForEach(WeightUnit.allCases, id: \.self) { unit in
                let selected = currentForm.wrappedValue.weightUnit == unit
                Button {
                    currentForm.wrappedValue.weightUnit = unit
                } label: {
                    Text(unit.rawValue)
                        .font(Theme.Font.microLabel)
                        .fontWeight(selected ? .semibold : .regular)
                        .foregroundStyle(selected ? .white : Theme.Colors.ink2)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background(selected ? Theme.Colors.accent : Color.clear)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Theme.Colors.bg2)
        .clipShape(Capsule())
    }

    private var currentForm: Binding<FishForm> {
        Binding(
            get: { recordSession.fishForms[safe: currentIndex] ?? defaultFishForm() },
            set: { recordSession.fishForms[currentIndex] = $0 }
        )
    }

    private func defaultFishForm() -> FishForm {
        var form = FishForm()
        form.weightUnit = WeightUnit(rawValue: defaultWeightUnitRaw) ?? .kg
        return form
    }

    var body: some View {
        ZStack {
            Theme.Colors.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.Space.lg) {
                    // 多鱼管理横向条
                    fishBar
                        .padding(.top, Theme.Space.sm)

                    // 抠图预览条
                    cutoutStrip

                    // 表单卡片
                    formCard

                    // 提示文字
                    Text("钓点由 GPS 自动记录，不用手填。")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Colors.ink2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Theme.Space.lg)
                }
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("填写渔获")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Text("第 \(currentIndex + 1) 尾")
                    .font(Theme.Font.microLabel)
                    .foregroundStyle(Theme.Colors.ink2)
            }
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "下一步 · 环境数据") {
                navigateToEnv = true
            }
            .padding(.horizontal, Theme.Space.lg)
            .padding(.bottom, 8)
            .background(Theme.Colors.bg)
        }
        .navigationDestination(isPresented: $navigateToEnv) {
            EnvDataView(isRecordPresented: $isRecordPresented)
        }
        .sheet(isPresented: $showSpeciesPicker) {
            SpeciesPickerSheet(
                selectedSpecies: currentForm.speciesName,
                isPresented: $showSpeciesPicker
            )
            .presentationDetents([.medium, .large])
        }
        .fullScreenCover(isPresented: $showRecut) {
            if let img = currentRaw {
                CropViewControllerWrapper(image: img) { cropped in
                    showRecut = false
                    if recordSession.cutoutImages.indices.contains(currentIndex) {
                        recordSession.cutoutImages[currentIndex] = cropped
                    }
                } onCancel: {
                    showRecut = false
                }
                .ignoresSafeArea()
            }
        }
    }

    // MARK: - 多鱼横向管理条
    private var fishBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Space.md) {
                ForEach(0..<total, id: \.self) { i in
                    fishThumb(index: i)
                }
                // 添加按钮
                Button {
                    addAnotherFish()
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Theme.Colors.accent, style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                                .frame(width: 48, height: 48)
                            Image(systemName: "plus")
                                .foregroundStyle(Theme.Colors.accent)
                                .font(.system(size: 18, weight: .medium))
                        }
                        Text("添加")
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.Colors.accent)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.Space.lg)
        }
    }

    private func fishThumb(index: Int) -> some View {
        let isActive = index == currentIndex
        let images = recordSession.effectiveImages
        let img = images[safe: index]

        return Button {
            recordSession.currentFishIndex = index
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isActive ? Theme.Colors.accentSoft : Theme.Colors.bg2)
                        .frame(width: 48, height: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isActive ? Theme.Colors.accent : Theme.Colors.hairline, lineWidth: isActive ? 2 : 1)
                        )

                    if let img = img {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 46, height: 46)
                            .clipShape(RoundedRectangle(cornerRadius: 9))
                    } else {
                        Text("🐟")
                            .font(.title3)
                            .opacity(isActive ? 1 : 0.4)
                    }
                }
                Text(isActive ? "正在填" : "第 \(index + 1) 尾")
                    .font(Theme.Font.caption)
                    .foregroundStyle(isActive ? Theme.Colors.accent : Theme.Colors.ink3)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 抠图预览条
    private var cutoutStrip: some View {
        HStack(spacing: Theme.Space.md) {
            let images = recordSession.effectiveImages
            Group {
                if let img = images[safe: currentIndex] {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.Colors.bg2)
                        .frame(width: 56, height: 72)
                        .overlay(
                            Image(systemName: "fish.fill")
                                .foregroundStyle(Theme.Colors.ink3)
                        )
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("已抠图")
                    .font(Theme.Font.subhead)
                    .fontWeight(.medium)
                    .foregroundStyle(Theme.Colors.ink)
                Text("来自上一步")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Colors.ink2)
            }

            Spacer()

            Button {
                showRecut = true
            } label: {
                Text("重抠 ↺")
                    .font(Theme.Font.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Theme.Colors.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.Colors.accentSoft)
                    .clipShape(Capsule())
            }
            .disabled(currentRaw == nil)
        }
        .padding(Theme.Space.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .shadowSoft()
        .padding(.horizontal, Theme.Space.lg)
    }

    // MARK: - 表单卡片
    private var formCard: some View {
        VStack(spacing: 0) {
            // 鱼种字段（点击弹 Sheet）
            Button {
                focusedField = nil
                showSpeciesPicker = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("鱼种".uppercased())
                            .font(Theme.Font.microLabel)
                            .kerning(0.5)
                            .foregroundStyle(Theme.Colors.ink3)
                        Text(currentForm.wrappedValue.speciesName.isEmpty ? "点击选择鱼种" : currentForm.wrappedValue.speciesName)
                            .font(Theme.Font.body)
                            .fontWeight(currentForm.wrappedValue.speciesName.isEmpty ? .regular : .semibold)
                            .foregroundStyle(currentForm.wrappedValue.speciesName.isEmpty ? Theme.Colors.ink3 : Theme.Colors.accent)
                    }
                    Spacer()
                    Text("更换 ›")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Colors.ink3)
                }
                .padding(Theme.Space.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider()
                .padding(.horizontal, Theme.Space.md)

            // 钓法选择
            VStack(alignment: .leading, spacing: 8) {
                Text("钓法".uppercased())
                    .font(Theme.Font.microLabel)
                    .kerning(0.5)
                    .foregroundStyle(Theme.Colors.ink3)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Space.sm) {
                        ForEach(methodOptions, id: \.self) { method in
                            let isSelected = currentForm.wrappedValue.fishingMethod == method
                            Button {
                                currentForm.wrappedValue.fishingMethod = isSelected ? "" : method
                            } label: {
                                Text(method)
                                    .font(Theme.Font.caption)
                                    .fontWeight(isSelected ? .semibold : .regular)
                                    .foregroundStyle(isSelected ? .white : Theme.Colors.ink2)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(isSelected ? Theme.Colors.accent : Theme.Colors.bg2)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(Theme.Space.md)

            Divider()
                .padding(.horizontal, Theme.Space.md)

            // 体长 + 重量（并排）
            HStack(spacing: 0) {
                // 体长（必填）
                VStack(alignment: .leading, spacing: 5) {
                    Text("体长 cm".uppercased())
                        .font(Theme.Font.microLabel)
                        .kerning(0.5)
                        .foregroundStyle(Theme.Colors.ink3)
                    TextField("必填", text: currentForm.lengthCm)
                        .font(Theme.Font.data(24, weight: .medium))
                        .foregroundStyle(Theme.Colors.ink)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .length)
                }
                .padding(Theme.Space.md)
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .frame(height: 56)

                // 重量（选填，可切换单位 kg / 斤）
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text("重量".uppercased())
                            .font(Theme.Font.microLabel)
                            .kerning(0.5)
                            .foregroundStyle(Theme.Colors.ink3)
                        Spacer()
                        unitToggle
                    }
                    TextField("选填", text: currentForm.weightValue)
                        .font(Theme.Font.data(24, weight: .medium))
                        .foregroundStyle(Theme.Colors.ink)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .weight)
                }
                .padding(Theme.Space.md)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()
                .padding(.horizontal, Theme.Space.md)

            // 备注
            VStack(alignment: .leading, spacing: 5) {
                Text("备注".uppercased())
                    .font(Theme.Font.microLabel)
                    .kerning(0.5)
                    .foregroundStyle(Theme.Colors.ink3)
                TextField("选填，记录这次钓鱼的故事…", text: currentForm.notes, axis: .vertical)
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
        .padding(.horizontal, Theme.Space.lg)
    }

    // MARK: - 添加下一尾鱼
    private func addAnotherFish() {
        recordSession.fishForms.append(defaultFishForm())
        if let img = recordSession.rawImages[safe: currentIndex] {
            recordSession.rawImages.append(img)
            recordSession.cutoutImages.append(recordSession.cutoutImages[safe: currentIndex] ?? nil)
        }
        recordSession.currentFishIndex = recordSession.fishForms.count - 1
    }
}

#Preview {
    NavigationStack {
        FishFormView(isRecordPresented: .constant(true))
            .environmentObject({
                let r = RecordSession()
                r.fishForms = [FishForm()]
                return r
            }())
    }
    .modelContainer(for: [FishingSession.self, FishCatch.self], inMemory: true)
}
