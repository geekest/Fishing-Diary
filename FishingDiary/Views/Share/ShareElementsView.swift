import SwiftUI

/// 分享第 2 步：选择出现在图上的元素，实时预览
struct ShareElementsView: View {
    let session: FishingSession
    let style: ShareStyleView.CardStyle
    @Binding var isRecordPresented: Bool

    @State private var config = ShareElementsConfig()
    @State private var navigateToPreview = false

    // 定义元素列表
    private struct Element {
        let emoji: String
        let label: String
        let value: String
        let keyPath: WritableKeyPath<ShareElementsConfig, Bool>
    }

    private var elements: [Element] {
        let w = session.weather
        return [
            Element(emoji: "🐟", label: "鱼种 + 体长",
                    value: "\(session.catches.first?.speciesName ?? "—") \(session.catches.first?.lengthCm.map { "\(Int($0))cm" } ?? "")",
                    keyPath: \.showFishAndLength),
            Element(emoji: "📍", label: "钓点定位",
                    value: session.locationName.isEmpty ? "未知" : session.locationName,
                    keyPath: \.showLocation),
            Element(emoji: "🌊", label: "潮汐",
                    value: w?.tide ?? "暂无",
                    keyPath: \.showTide),
            Element(emoji: "🧭", label: "气压",
                    value: w.map { "\(Int($0.pressure))hPa" } ?? "暂无",
                    keyPath: \.showPressure),
            Element(emoji: "💨", label: "风速风向",
                    value: w.map { "\($0.windDirection) \($0.windSpeed)m/s" } ?? "暂无",
                    keyPath: \.showWind),
            Element(emoji: "☀️", label: "紫外线 / 气温",
                    value: w.map { "UVI \($0.uvIndex) · \(Int($0.temperature))°C" } ?? "暂无",
                    keyPath: \.showUVAndTemp),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            // 实时预览卡（小）
            livePreview

            Divider()

            // 元素开关列表
            Text("勾选要出现在图上的元素 ↓")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, 8)

            List {
                ForEach(elements, id: \.label) { el in
                    HStack(spacing: 12) {
                        Text(el.emoji).font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(el.label).font(.subheadline)
                            Text(el.value).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { config[keyPath: el.keyPath] },
                            set: { config[keyPath: el.keyPath] = $0 }
                        )).labelsHidden()
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("展示元素")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Text("2/2").font(.caption).foregroundStyle(.secondary)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                navigateToPreview = true
            } label: {
                Text("出图预览 ›")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .navigationDestination(isPresented: $navigateToPreview) {
            PreviewExportView(session: session, config: config, isRecordPresented: $isRecordPresented)
        }
    }

    // MARK: - 实时预览
    private var livePreview: some View {
        HStack {
            Spacer()
            MinimalCardView(session: session, visibleElements: config, showWatermark: false)
                .frame(width: 120)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
            Spacer()
        }
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
    }
}

#Preview {
    NavigationStack {
        ShareElementsView(
            session: FishingSession(date: .now, locationName: "千岛湖"),
            style: .minimal,
            isRecordPresented: .constant(true)
        )
    }
    .modelContainer(for: [FishingSession.self, FishCatch.self], inMemory: true)
}
