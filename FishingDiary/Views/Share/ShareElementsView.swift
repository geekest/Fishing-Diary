import SwiftUI

// MARK: - 出图第 2 步：展示元素配置
struct ShareElementsView: View {
    let session: FishingSession
    let style: ShareStyleView.CardStyle
    let ratio: ShareStyleView.CardRatio
    @Binding var isRecordPresented: Bool

    @State private var config = ShareElementsConfig()
    @State private var navigateToPreview = false

    private struct ElementItem: Identifiable {
        let id = UUID()
        let emoji: String
        let label: String
        let value: String
        let keyPath: WritableKeyPath<ShareElementsConfig, Bool>
    }

    private var elements: [ElementItem] {
        let w = session.weather
        let firstCatch = session.catches.sorted { $0.sortIndex < $1.sortIndex }.first
        return [
            ElementItem(emoji: "🐟", label: "鱼种 + 体长",
                        value: "\(firstCatch?.speciesName ?? "—") \(firstCatch?.lengthCm.map { "\(Int($0))cm" } ?? "")",
                        keyPath: \.showFishAndLength),
            ElementItem(emoji: "📍", label: "钓点定位",
                        value: session.locationName.isEmpty ? "未知" : session.locationName,
                        keyPath: \.showLocation),
            ElementItem(emoji: "🌊", label: "潮汐",
                        value: w?.tide ?? "暂无",
                        keyPath: \.showTide),
            ElementItem(emoji: "🧭", label: "气压",
                        value: w.map { "\(Int($0.pressure)) hPa" } ?? "暂无",
                        keyPath: \.showPressure),
            ElementItem(emoji: "💨", label: "风速 / 风向",
                        value: w.map { "\($0.windDirection) \($0.windSpeed)m/s" } ?? "暂无",
                        keyPath: \.showWind),
            ElementItem(emoji: "☀️", label: "紫外线 / 气温",
                        value: w.map { "UVI \($0.uvIndex) · \(Int($0.temperature))°C" } ?? "暂无",
                        keyPath: \.showUVAndTemp),
        ]
    }

    var body: some View {
        ZStack {
            Theme.Colors.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.xl) {
                    // 实时预览
                    livePreviewSection

                    // 元素 toggle 列表
                    elementsSection
                }
                .padding(.horizontal, Theme.Space.lg)
                .padding(.vertical, Theme.Space.md)
                .padding(.bottom, 80)
            }
        }
        .navigationTitle("展示元素")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 6) {
                    Circle().fill(Theme.Colors.ink3).frame(width: 6, height: 6)
                    Circle().fill(Theme.Colors.accent).frame(width: 6, height: 6)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "出图预览 ›") {
                navigateToPreview = true
            }
            .padding(.horizontal, Theme.Space.lg)
            .padding(.bottom, 8)
            .background(Theme.Colors.bg)
        }
        .navigationDestination(isPresented: $navigateToPreview) {
            PreviewExportView(session: session, config: config, ratio: ratio, isRecordPresented: $isRecordPresented)
        }
    }

    // MARK: - 实时预览区
    private var livePreviewSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            HStack {
                SectionLabel(text: "实时预览 · 开关即刷新")
                Spacer()
            }

            HStack {
                Spacer()
                MinimalCardView(session: session, visibleElements: config, showWatermark: false, ratio: ratio.aspectRatio)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadowCard()
                    .animation(.easeInOut(duration: 0.2), value: config.showFishAndLength)
                    .animation(.easeInOut(duration: 0.2), value: config.showLocation)
                    .animation(.easeInOut(duration: 0.2), value: config.showTide)
                    .animation(.easeInOut(duration: 0.2), value: config.showPressure)
                    .animation(.easeInOut(duration: 0.2), value: config.showWind)
                    .animation(.easeInOut(duration: 0.2), value: config.showUVAndTemp)
                Spacer()
            }
        }
    }

    // MARK: - 元素列表
    private var elementsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            SectionLabel(text: "勾选要出现在图上的 ↓")

            VStack(spacing: 0) {
                ForEach(Array(elements.enumerated()), id: \.element.id) { i, el in
                    elementRow(el)
                    if i < elements.count - 1 {
                        Divider().padding(.leading, 54)
                    }
                }
            }
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field))
            .shadowSoft()
        }
    }

    private func elementRow(_ el: ElementItem) -> some View {
        HStack(spacing: Theme.Space.md) {
            Text(el.emoji)
                .font(.title3)
                .frame(width: 30)
                .padding(.leading, Theme.Space.xs)

            VStack(alignment: .leading, spacing: 2) {
                Text(el.label)
                    .font(Theme.Font.subhead)
                    .fontWeight(.medium)
                    .foregroundStyle(Theme.Colors.ink)
                Text(el.value)
                    .font(Theme.Font.microLabel)
                    .foregroundStyle(Theme.Colors.ink2)
                    .lineLimit(1)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { config[keyPath: el.keyPath] },
                set: { config[keyPath: el.keyPath] = $0 }
            ))
            .labelsHidden()
            .tint(Theme.Colors.accent)
        }
        .padding(.horizontal, Theme.Space.md)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        ShareElementsView(
            session: FishingSession(date: .now, locationName: "千岛湖"),
            style: .minimal,
            ratio: .threeByFour,
            isRecordPresented: .constant(true)
        )
    }
    .modelContainer(for: [FishingSession.self, FishCatch.self], inMemory: true)
}
