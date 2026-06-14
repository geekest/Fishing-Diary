import SwiftUI

// MARK: - 渔获卡片（首页核心组件）
struct CatchCard: View {
    let session: FishingSession

    private var dateText: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MM.dd"
        return fmt.string(from: session.date)
    }

    private var locationText: String {
        session.locationName.isEmpty ? "未知钓点" : session.locationName
    }

    private var primaryCatch: FishCatch? {
        session.catches.sorted(by: { $0.sortIndex < $1.sortIndex }).first
    }

    private var lengthText: String {
        guard let len = primaryCatch?.lengthCm else { return "" }
        return "\(Int(len)) cm"
    }

    private var speciesText: String {
        let names = session.speciesNames
        return names.isEmpty ? "未知鱼种" : names.joined(separator: " · ")
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部照片区
            photoArea

            // 下方信息区
            infoArea
        }
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .shadowCard()
    }

    // MARK: - 照片区（16:9）
    private var photoArea: some View {
        // 由宽度推导高度的 16:9 盒子（高度有界，避免在 ScrollView 中无限撑高）
        Color.clear
            .aspectRatio(16/9, contentMode: .fit)
            .overlay {
                photoBackground
                    .scaledToFill()
            }
            .clipped()
            .overlay {
                // 底部渐变蒙层
                LinearGradient(
                    colors: [.clear, .black.opacity(0.55)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            // 左上日期 pill
            .overlay(alignment: .topLeading) {
                pillTag(dateText)
                    .padding(Theme.Space.md)
            }
            // 右上钓法 pill
            .overlay(alignment: .topTrailing) {
                pillTag("路亚")
                    .padding(Theme.Space.md)
            }
            // 右下体长
            .overlay(alignment: .bottomTrailing) {
                if !lengthText.isEmpty {
                    Text(lengthText)
                        .font(Theme.Font.data(20, weight: .medium))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 1)
                        .padding(Theme.Space.md)
                }
            }
    }

    @ViewBuilder
    private var photoBackground: some View {
        if let data = session.coverImageData, let img = UIImage(data: data) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
        } else {
            Theme.Colors.catchGradient(for: session.id)
        }
    }

    private func pillTag(_ text: String) -> some View {
        Text(text)
            .font(Theme.Font.microLabel)
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.black.opacity(0.38))
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
    }

    // MARK: - 信息区
    private var infoArea: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            // 鱼种名 + chevron
            HStack(alignment: .center) {
                Text(speciesText)
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Colors.ink)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink3)
            }

            // 钓点
            HStack(spacing: 4) {
                Image(systemName: "mappin")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.Colors.ink3)
                Text(locationText)
                    .font(Theme.Font.subhead)
                    .foregroundStyle(Theme.Colors.ink2)
                    .lineLimit(1)
            }

            // 环境 chip 行
            if let weather = session.weather {
                envChips(weather: weather)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 11)
        .padding(.bottom, 13)
    }

    private func envChips(weather: WeatherSnapshot) -> some View {
        HStack(spacing: 6) {
            if !weather.condition.isEmpty {
                envChip(weather.condition)
            }
            if weather.temperature > 0 {
                envChip("\(Int(weather.temperature))°C")
            }
            if let tide = weather.tide, !tide.isEmpty {
                envChip(tide)
            }
            if session.totalCatch > 1 {
                envChip("×\(session.totalCatch)")
            }
        }
    }

    private func envChip(_ text: String) -> some View {
        Text(text)
            .font(Theme.Font.microLabel)
            .foregroundStyle(Theme.Colors.chipInk)
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background(Theme.Colors.chip)
            .clipShape(Capsule())
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 16) {
            // 无图占位
            CatchCard(session: {
                let s = FishingSession(date: .now, locationName: "千岛湖 · 大坝南")
                return s
            }())

            // 有天气数据
            CatchCard(session: {
                let s = FishingSession(date: .now, locationName: "太湖 · 西山岛")
                let w = WeatherSnapshot(
                    temperature: 22,
                    windSpeed: 3.2,
                    windDirection: "SE",
                    pressure: 1014,
                    uvIndex: 5,
                    condition: "多云",
                    waterTemp: nil,
                    moonPhase: nil,
                    tide: "涨潮"
                )
                s.weatherData = try? JSONEncoder().encode(w)
                return s
            }())
        }
        .padding()
    }
    .background(Theme.Colors.bg)
    .modelContainer(for: [FishingSession.self, FishCatch.self], inMemory: true)
}
