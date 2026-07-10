import SwiftUI

/// 极简数据卡模板（MVP 唯一免费模板，3:4 画幅）
/// 可通过 ImageRenderer 直接渲染为 UIImage
struct MinimalCardView: View {
    let session: FishingSession
    let visibleElements: ShareElementsConfig
    var showWatermark: Bool = false  // 付费后去水印
    var ratio: CGFloat = 3.0/4.0

    private var firstCatch: FishCatch? { session.catches.min(by: { $0.sortIndex < $1.sortIndex }) }
    private var weather: WeatherSnapshot? { session.weather }

    /// 模糊背景图（原图）
    private var blurredBackground: UIImage? {
        if let c = firstCatch, !c.originalImageData.isEmpty {
            return SubjectCutoutService.cardBackground(id: c.id, originalData: c.originalImageData)
        }
        if let data = session.coverImageData { return UIImage(data: data) }
        return nil
    }

    /// 白描边贴纸（抠图加白描边）
    private var fishSticker: UIImage? {
        guard let c = firstCatch, !c.cutoutImageData.isEmpty else { return nil }
        return SubjectCutoutService.cardSticker(id: c.id, cutoutData: c.cutoutImageData)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                // 模糊背景
                background(in: geo.size)

                // 白描边鱼贴纸（浮于背景之上）
                stickerLayer(in: geo.size)

                // 渐变蒙层
                LinearGradient(
                    colors: [.clear, .clear, .black.opacity(0.75)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // 主内容
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                    mainContent(in: geo.size)
                    if showWatermark { watermarkBadge(in: geo.size) }
                }
                .padding(geo.size.width * 0.06)

                // 顶部水印（未付费）
                if showWatermark { topWatermark(in: geo.size) }
            }
        }
        .aspectRatio(ratio, contentMode: .fit)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }

    // MARK: - 背景
    private func background(in size: CGSize) -> some View {
        Group {
            if let img = blurredBackground {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
            } else {
                // 无图时用深绿渐变
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.25, blue: 0.15), Color(red: 0.02, green: 0.12, blue: 0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    // MARK: - 白描边贴纸层
    @ViewBuilder
    private func stickerLayer(in size: CGSize) -> some View {
        if let sticker = fishSticker {
            Image(uiImage: sticker)
                .resizable()
                .scaledToFit()
                .frame(width: size.width, height: size.height, alignment: .top)
        }
    }

    // MARK: - 主内容区（左下角）
    private func mainContent(in size: CGSize) -> some View {
        let metrics = CardMetrics(size: size)

        return VStack(alignment: .leading, spacing: metrics.contentSpacing) {
            // 顶部标签
            Text("钓鱼日记 · \(session.date.formatted(.dateTime.month(.twoDigits).day(.twoDigits)))")
                .font(.system(size: metrics.metaFont, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
                .tracking(metrics.metaTracking)

            // 核心数据
            if visibleElements.showFishAndLength, let catch_ = firstCatch {
                HStack(alignment: .lastTextBaseline, spacing: metrics.numberSpacing) {
                    if let len = catch_.lengthCm {
                        Text("\(Int(len))")
                            .font(.system(size: metrics.lengthFont, weight: .bold, design: .default))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text("cm")
                            .font(.system(size: metrics.unitFont, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                Text("\(catch_.speciesName.isEmpty ? "—" : catch_.speciesName) · \(session.locationName.isEmpty ? "未知钓点" : session.locationName)")
                    .font(.system(size: metrics.subtitleFont, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }

            // 分割线
            if hasEnvData {
                Divider().overlay(.white.opacity(0.3))
                    .padding(.vertical, metrics.dividerPadding)

                // 环境数据条
                envDataRow(in: metrics)
            }
        }
    }

    // MARK: - 环境数据行
    private func envDataRow(in metrics: CardMetrics) -> some View {
        HStack(spacing: metrics.envSpacing) {
            if visibleElements.showTide, let tide = weather?.tide {
                envCell(value: tideShort(tide), label: "TIDE", metrics: metrics)
            }
            if visibleElements.showPressure, let p = weather?.pressure {
                envCell(value: "\(Int(p))", label: "hPa", metrics: metrics)
            }
            if visibleElements.showWind, let w = weather {
                envCell(value: "\(w.windDirection)\(w.windSpeed.clean)m", label: "WIND", metrics: metrics)
            }
            if visibleElements.showUVAndTemp, let w = weather {
                envCell(value: "UVI\(w.uvIndex)·\(Int(w.temperature))°", label: "ENV", metrics: metrics)
            }
            if visibleElements.showLocation, !session.locationName.isEmpty {
                envCell(value: session.locationName, label: "LOC", metrics: metrics)
            }
        }
    }

    private func envCell(value: String, label: String, metrics: CardMetrics) -> some View {
        VStack(alignment: .leading, spacing: metrics.envLabelSpacing) {
            Text(value)
                .font(.system(size: metrics.envValueFont, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.45)
            Text(label)
                .font(.system(size: metrics.envLabelFont, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(metrics.envTracking)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var hasEnvData: Bool {
        visibleElements.showTide || visibleElements.showPressure ||
        visibleElements.showWind || visibleElements.showUVAndTemp
    }

    // MARK: - 水印
    private func topWatermark(in size: CGSize) -> some View {
        let metrics = CardMetrics(size: size)

        return VStack {
            HStack {
                Spacer()
                ForEach(0..<4, id: \.self) { _ in
                    Text("钓鱼日记")
                        .font(.system(size: metrics.watermarkFont))
                        .foregroundStyle(.white.opacity(0.25))
                        .padding(.horizontal, metrics.watermarkPadding)
                }
            }
            .rotationEffect(.degrees(-15))
            .padding(.top, metrics.topWatermarkPadding)
            Spacer()
        }
    }

    private func watermarkBadge(in size: CGSize) -> some View {
        let metrics = CardMetrics(size: size)

        return Text("钓鱼日记")
            .font(.system(size: metrics.envLabelFont, weight: .medium, design: .monospaced))
            .foregroundStyle(.white.opacity(0.4))
            .tracking(metrics.envTracking * 2)
            .padding(.top, metrics.contentSpacing)
    }

    private func tideShort(_ tide: String) -> String {
        tide.contains("涨") ? "涨潮" : tide.contains("退") ? "退潮" : tide
    }
}

private struct CardMetrics {
    let width: CGFloat

    init(size: CGSize) {
        self.width = max(size.width, 1)
    }

    var metaFont: CGFloat { width * 0.028 }
    var metaTracking: CGFloat { width * 0.0025 }
    var lengthFont: CGFloat { width * 0.18 }
    var unitFont: CGFloat { width * 0.052 }
    var subtitleFont: CGFloat { width * 0.036 }
    var envValueFont: CGFloat { width * 0.032 }
    var envLabelFont: CGFloat { width * 0.02 }
    var watermarkFont: CGFloat { width * 0.026 }
    var contentSpacing: CGFloat { width * 0.014 }
    var numberSpacing: CGFloat { width * 0.008 }
    var dividerPadding: CGFloat { width * 0.008 }
    var envSpacing: CGFloat { width * 0.028 }
    var envLabelSpacing: CGFloat { width * 0.004 }
    var envTracking: CGFloat { width * 0.002 }
    var watermarkPadding: CGFloat { width * 0.02 }
    var topWatermarkPadding: CGFloat { width * 0.1 }
}

private extension Double {
    var clean: String { self.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(self))" : String(format: "%.1f", self) }
}

#Preview {
    MinimalCardView(
        session: {
            let s = FishingSession(date: .now, locationName: "千岛湖")
            return s
        }(),
        visibleElements: ShareElementsConfig(),
        showWatermark: true
    )
    .frame(width: 300)
    .padding()
}
