import SwiftUI

/// 极简数据卡模板（MVP 唯一免费模板，3:4 画幅）
/// 可通过 ImageRenderer 直接渲染为 UIImage
struct MinimalCardView: View {
    let session: FishingSession
    let visibleElements: ShareElementsConfig
    var showWatermark: Bool = false  // 付费后去水印

    private var firstCatch: FishCatch? { session.catches.min(by: { $0.sortIndex < $1.sortIndex }) }
    private var weather: WeatherSnapshot? { session.weather }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                // 背景图（鱼的抠图或纯色）
                background(in: geo.size)

                // 渐变蒙层
                LinearGradient(
                    colors: [.clear, .clear, .black.opacity(0.75)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // 主内容
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                    mainContent
                    if showWatermark { watermarkBadge }
                }
                .padding(geo.size.width * 0.06)

                // 顶部水印（未付费）
                if showWatermark { topWatermark }
            }
        }
        .aspectRatio(3.0/4.0, contentMode: .fit)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }

    // MARK: - 背景
    private func background(in size: CGSize) -> some View {
        Group {
            if let data = session.coverImageData, let img = UIImage(data: data) {
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

    // MARK: - 主内容区（左下角）
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 顶部标签
            Text("钓鱼日记 · \(session.date.formatted(.dateTime.month(.twoDigits).day(.twoDigits)))")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
                .tracking(1)

            // 核心数据
            if visibleElements.showFishAndLength, let catch_ = firstCatch {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    if let len = catch_.lengthCm {
                        Text("\(Int(len))")
                            .font(.system(size: 64, weight: .bold, design: .default))
                            .foregroundStyle(.white)
                        Text("cm")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                Text("\(catch_.speciesName.isEmpty ? "—" : catch_.speciesName) · \(session.locationName.isEmpty ? "未知钓点" : session.locationName)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
            }

            // 分割线
            if hasEnvData {
                Divider().overlay(.white.opacity(0.3))
                    .padding(.vertical, 4)

                // 环境数据条
                envDataRow
            }
        }
    }

    // MARK: - 环境数据行
    private var envDataRow: some View {
        HStack(spacing: 16) {
            if visibleElements.showTide, let tide = weather?.tide {
                envCell(value: tideShort(tide), label: "TIDE")
            }
            if visibleElements.showPressure, let p = weather?.pressure {
                envCell(value: "\(Int(p))", label: "hPa")
            }
            if visibleElements.showWind, let w = weather {
                envCell(value: "\(w.windDirection)\(w.windSpeed.clean)m", label: "WIND")
            }
            if visibleElements.showUVAndTemp, let w = weather {
                envCell(value: "UVI\(w.uvIndex)·\(Int(w.temperature))°", label: "ENV")
            }
            if visibleElements.showLocation, !session.locationName.isEmpty {
                envCell(value: session.locationName, label: "LOC")
            }
        }
    }

    private func envCell(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(1)
        }
    }

    private var hasEnvData: Bool {
        visibleElements.showTide || visibleElements.showPressure ||
        visibleElements.showWind || visibleElements.showUVAndTemp
    }

    // MARK: - 水印
    private var topWatermark: some View {
        VStack {
            HStack {
                Spacer()
                ForEach(0..<4, id: \.self) { _ in
                    Text("钓鱼日记")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.25))
                        .padding(.horizontal, 8)
                }
            }
            .rotationEffect(.degrees(-15))
            .padding(.top, 40)
            Spacer()
        }
    }

    private var watermarkBadge: some View {
        Text("钓鱼日记")
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .foregroundStyle(.white.opacity(0.4))
            .tracking(2)
            .padding(.top, 8)
    }

    private func tideShort(_ tide: String) -> String {
        tide.contains("涨") ? "涨潮" : tide.contains("退") ? "退潮" : tide
    }
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
