import SwiftUI

/// 极简数据卡模板（MVP 唯一免费模板，3:4 画幅）
/// 可通过 ImageRenderer 直接渲染为 UIImage
struct MinimalCardView: View {
    let session: FishingSession
    let visibleElements: ShareElementsConfig
    var showWatermark: Bool = false  // 付费后去水印
    var style: ShareStyleView.CardStyle = .minimal
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
            templateContent(in: geo.size)
        }
        .aspectRatio(ratio, contentMode: .fit)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }

    @ViewBuilder
    private func templateContent(in size: CGSize) -> some View {
        switch style {
        case .minimal:
            minimalTemplate(in: size)
        case .tech:
            techTemplate(in: size)
        case .sticker:
            stickerTemplate(in: size)
        case .film:
            filmTemplate(in: size)
        }
    }

    private func minimalTemplate(in size: CGSize) -> some View {
        ZStack(alignment: .bottomLeading) {
            background(in: size)
            stickerLayer(in: size)
            LinearGradient(
                colors: [.clear, .clear, .black.opacity(0.75)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                mainContent(in: size)
                if showWatermark { watermarkBadge(in: size) }
            }
            .padding(size.width * 0.06)

            if showWatermark { topWatermark(in: size) }
        }
    }

    private func techTemplate(in size: CGSize) -> some View {
        let metrics = CardMetrics(size: size)

        return ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color(hex: "06111D"), Color(hex: "123B4A"), Color(hex: "041016")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            background(in: size)
                .opacity(0.22)
                .saturation(0.65)
            stickerLayer(in: size)
                .opacity(0.88)
            LinearGradient(colors: [.clear, .black.opacity(0.72)], startPoint: .center, endPoint: .bottom)

            VStack(alignment: .leading, spacing: metrics.contentSpacing * 1.4) {
                HStack {
                    Text("FISHING DATA")
                        .font(.system(size: metrics.metaFont * 1.2, weight: .semibold, design: .monospaced))
                        .tracking(metrics.metaTracking * 2)
                    Spacer()
                    Text(session.date.formatted(.dateTime.month(.twoDigits).day(.twoDigits)))
                        .font(.system(size: metrics.metaFont, weight: .medium, design: .monospaced))
                }
                .foregroundStyle(Color(hex: "7FE9FF"))

                Spacer()

                if visibleElements.showFishAndLength, let catch_ = firstCatch {
                    Text(catch_.speciesName.isEmpty ? "UNKNOWN CATCH" : catch_.speciesName.uppercased())
                        .font(.system(size: metrics.subtitleFont * 1.4, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.88))
                    HStack(alignment: .lastTextBaseline, spacing: metrics.numberSpacing) {
                        Text("\(Int(catch_.lengthCm ?? 0))")
                            .font(.system(size: metrics.lengthFont * 1.15, weight: .black, design: .monospaced))
                            .foregroundStyle(.white)
                        Text("CM")
                            .font(.system(size: metrics.unitFont, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(hex: "7FE9FF"))
                    }
                }

                Divider().overlay(Color(hex: "7FE9FF").opacity(0.55))
                envDataRow(in: metrics)
            }
            .padding(size.width * 0.06)
        }
    }

    private func stickerTemplate(in size: CGSize) -> some View {
        let metrics = CardMetrics(size: size)

        return ZStack(alignment: .bottomLeading) {
            Color(hex: "EFE4C8")
            Circle()
                .fill(Color(hex: "F9C74F").opacity(0.55))
                .frame(width: size.width * 0.65)
                .offset(x: size.width * 0.46, y: -size.height * 0.34)
            RoundedRectangle(cornerRadius: size.width * 0.03)
                .fill(.white.opacity(0.78))
                .rotationEffect(.degrees(-4))
                .padding(size.width * 0.08)

            if let sticker = fishSticker {
                Image(uiImage: sticker)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.width * 0.9, height: size.height * 0.72)
                    .offset(x: size.width * 0.09, y: -size.height * 0.08)
            } else {
                stickerLayer(in: size)
            }

            VStack(alignment: .leading, spacing: metrics.contentSpacing * 1.2) {
                HStack {
                    Text("今日战果")
                        .font(.system(size: metrics.subtitleFont * 1.6, weight: .black))
                    Spacer()
                    Text(session.date.formatted(.dateTime.month(.twoDigits).day(.twoDigits)))
                        .font(.system(size: metrics.metaFont, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(Color(hex: "3C3422"))

                Spacer()

                if visibleElements.showFishAndLength, let catch_ = firstCatch {
                    Text(catch_.speciesName.isEmpty ? "未知渔获" : catch_.speciesName)
                        .font(.system(size: metrics.subtitleFont * 1.25, weight: .bold))
                        .foregroundStyle(Color(hex: "3C3422").opacity(0.78))
                    HStack(alignment: .lastTextBaseline, spacing: metrics.numberSpacing) {
                        Text("\(Int(catch_.lengthCm ?? 0))")
                            .font(.system(size: metrics.lengthFont, weight: .black))
                            .foregroundStyle(Color(hex: "1F6F5C"))
                        Text("cm")
                            .font(.system(size: metrics.unitFont, weight: .heavy))
                            .foregroundStyle(Color(hex: "3C3422"))
                    }
                }

                envDataRow(in: metrics)
                    .foregroundStyle(Color(hex: "3C3422"))
            }
            .padding(size.width * 0.07)
        }
    }

    private func filmTemplate(in size: CGSize) -> some View {
        let metrics = CardMetrics(size: size)

        return ZStack(alignment: .bottomLeading) {
            Color(hex: "191511")
            background(in: size)
                .padding(size.width * 0.07)
                .saturation(0.78)
                .contrast(1.12)
            stickerLayer(in: size)
                .padding(size.width * 0.04)
            RoundedRectangle(cornerRadius: 1)
                .stroke(.white.opacity(0.82), lineWidth: size.width * 0.012)
                .padding(size.width * 0.055)
            LinearGradient(colors: [.clear, .black.opacity(0.76)], startPoint: .center, endPoint: .bottom)

            VStack(alignment: .leading, spacing: metrics.contentSpacing) {
                HStack {
                    Text("FISHING DIARY")
                    Spacer()
                    Text(session.date.formatted(.dateTime.year().month(.twoDigits).day(.twoDigits)))
                }
                .font(.system(size: metrics.metaFont, weight: .medium, design: .monospaced))
                .tracking(metrics.metaTracking)
                .foregroundStyle(Color(hex: "F3E4C7"))

                Spacer()

                if visibleElements.showFishAndLength, let catch_ = firstCatch {
                    Text(catch_.speciesName.isEmpty ? "未知钓点" : catch_.speciesName)
                        .font(.system(size: metrics.subtitleFont * 1.2, weight: .semibold))
                        .foregroundStyle(Color(hex: "F3E4C7"))
                    HStack(alignment: .lastTextBaseline, spacing: metrics.numberSpacing) {
                        Text("\(Int(catch_.lengthCm ?? 0))")
                            .font(.system(size: metrics.lengthFont * 0.95, weight: .bold, design: .serif))
                            .foregroundStyle(.white)
                        Text("cm")
                            .font(.system(size: metrics.unitFont, weight: .medium, design: .serif))
                            .foregroundStyle(Color(hex: "F3E4C7"))
                    }
                }

                Divider().overlay(Color(hex: "F3E4C7").opacity(0.45))
                envDataRow(in: metrics)
                    .foregroundStyle(Color(hex: "F3E4C7"))
            }
            .padding(size.width * 0.08)
        }
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
