import SwiftUI
import CoreLocation

// MARK: - 环境数据界面
struct EnvDataView: View {
    @Binding var isRecordPresented: Bool
    @EnvironmentObject var recordSession: RecordSession

    @State private var isLoading = true
    @State private var navigateToSaved = false

    var body: some View {
        ZStack {
            Theme.Colors.bg.ignoresSafeArea()

            if isLoading {
                loadingView
            } else {
                dataScrollView
            }
        }
        .navigationTitle("环境数据")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadWeather() }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "完成 · 存入日记") {
                navigateToSaved = true
            }
            .padding(.horizontal, Theme.Space.lg)
            .padding(.bottom, 8)
            .background(Theme.Colors.bg)
        }
        .navigationDestination(isPresented: $navigateToSaved) {
            SavedView(isRecordPresented: $isRecordPresented)
        }
    }

    // MARK: - 加载中
    private var loadingView: some View {
        VStack(spacing: Theme.Space.lg) {
            ProgressView()
                .tint(Theme.Colors.accent)
                .scaleEffect(1.2)
            Text("正在感应环境数据…")
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Colors.ink2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 数据滚动区
    private var dataScrollView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.md) {
                // 提示 chip
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                    Text("已自动带入当前天气数据，选择要记录的项 ↓")
                        .font(Theme.Font.caption)
                }
                .foregroundStyle(Theme.Colors.accent)
                .padding(.horizontal, Theme.Space.md)
                .padding(.vertical, Theme.Space.sm)
                .background(Theme.Colors.accentSoft)
                .clipShape(Capsule())
                .padding(.horizontal, Theme.Space.lg)
                .padding(.top, Theme.Space.md)

                // 数据 toggle 列表
                VStack(spacing: 0) {
                    toggleRow(label: "定位",
                              value: recordSession.locationName.isEmpty ? "未获取" : recordSession.locationName,
                              isOn: bindToggle(\.location))

                    if let w = recordSession.weather {
                        divider
                        toggleRow(label: "气温", value: "\(Int(w.temperature)) °C", isOn: bindToggle(\.temperature))
                        divider
                        toggleRow(label: "水温", value: w.waterTemp.map { "\(Int($0)) °C" } ?? "暂无", isOn: bindToggle(\.waterTemp))
                        divider
                        toggleRow(label: "风速 / 风向", value: "\(w.windDirection) \(String(format: "%.1f", w.windSpeed))m/s", isOn: bindToggle(\.wind))
                        divider
                        toggleRow(label: "气压", value: "\(Int(w.pressure)) hPa", isOn: bindToggle(\.pressure))
                        divider
                        toggleRow(label: "紫外线 UVI", value: "\(uvLevel(w.uvIndex)) · \(w.uvIndex)", isOn: bindToggle(\.uvIndex))
                        divider
                        toggleRow(label: "潮汐", value: w.tide ?? "暂无", isOn: bindToggle(\.tide))
                        divider
                        toggleRow(label: "月相", value: w.moonPhase ?? "暂无", isOn: bindToggle(\.moonPhase))
                        divider
                        toggleRow(label: "天气", value: w.condition, isOn: bindToggle(\.condition))
                    }
                }
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field))
                .shadowSoft()
                .padding(.horizontal, Theme.Space.lg)
                .padding(.bottom, 80)
            }
        }
    }

    private var divider: some View {
        Divider()
            .padding(.leading, Theme.Space.lg)
    }

    private func toggleRow(label: String, value: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Colors.ink)
            Spacer()
            Text(value)
                .font(Theme.Font.dataReading)
                .foregroundStyle(Theme.Colors.ink2)
                .lineLimit(1)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Theme.Colors.accent)
        }
        .padding(.horizontal, Theme.Space.lg)
        .padding(.vertical, 14)
    }

    private func uvLevel(_ index: Int) -> String {
        switch index {
        case 0...2: return "低"
        case 3...5: return "中等"
        case 6...7: return "高"
        default:    return "极高"
        }
    }

    // MARK: - 绑定辅助
    private func bindToggle(_ keyPath: WritableKeyPath<WeatherToggles, Bool>) -> Binding<Bool> {
        Binding(
            get: { recordSession.weatherToggles[keyPath: keyPath] },
            set: { recordSession.weatherToggles[keyPath: keyPath] = $0 }
        )
    }

    // MARK: - 加载天气
    private func loadWeather() async {
        let mockLocation = CLLocation(latitude: 29.6, longitude: 119.0)
        let weather = await WeatherService.shared.fetchCurrent(for: mockLocation)
        recordSession.weather = weather
        if recordSession.locationName.isEmpty {
            recordSession.locationName = "千岛湖 · 大坝南"
        }
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        EnvDataView(isRecordPresented: .constant(true))
            .environmentObject(RecordSession())
    }
}
