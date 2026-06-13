import SwiftUI
import CoreLocation

/// 环境数据界面：展示自动抓取的天气，用户勾选要记录的字段
struct EnvDataView: View {
    @Binding var isRecordPresented: Bool
    @EnvironmentObject var recordSession: RecordSession

    @State private var isLoading = true
    @State private var navigateToSaved = false

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                loadingView
            } else {
                dataList
            }
        }
        .navigationTitle("环境数据")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadWeather() }
        .safeAreaInset(edge: .bottom) {
            Button {
                navigateToSaved = true
            } label: {
                Text("完成 · 存入日记")
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
        .navigationDestination(isPresented: $navigateToSaved) {
            SavedView(isRecordPresented: $isRecordPresented)
        }
    }

    // MARK: - 加载中
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("正在获取天气数据…")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 数据列表
    private var dataList: some View {
        List {
            Section {
                Text("已调天气自动带入，选要记录的 ↓")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            Section {
                toggleRow(label: "定位",
                          value: recordSession.locationName.isEmpty ? "未获取" : recordSession.locationName,
                          isOn: bindToggle(\.location))

                if let w = recordSession.weather {
                    toggleRow(label: "气温", value: "\(Int(w.temperature)) °C", isOn: bindToggle(\.temperature))
                    toggleRow(label: "水温", value: w.waterTemp.map { "\($0) °C" } ?? "暂无", isOn: bindToggle(\.waterTemp))
                    toggleRow(label: "风速 / 风向", value: "\(w.windDirection) \(w.windSpeed)m/s", isOn: bindToggle(\.wind))
                    toggleRow(label: "气压", value: "\(Int(w.pressure)) hPa", isOn: bindToggle(\.pressure))
                    toggleRow(label: "紫外线 UVI", value: "中等 · \(w.uvIndex)", isOn: bindToggle(\.uvIndex))
                    toggleRow(label: "潮汐", value: w.tide ?? "暂无", isOn: bindToggle(\.tide))
                    toggleRow(label: "月相", value: w.moonPhase ?? "暂无", isOn: bindToggle(\.moonPhase))
                    toggleRow(label: "天气", value: w.condition, isOn: bindToggle(\.condition))
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func toggleRow(label: String, value: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Toggle("", isOn: isOn)
                .labelsHidden()
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
        // 这里用 Mock 位置，真实接入后从 LocationManager 取
        let mockLocation = CLLocation(latitude: 29.6, longitude: 119.0)  // 千岛湖附近
        let weather = await WeatherService.shared.fetchCurrent(for: mockLocation)
        recordSession.weather = weather
        recordSession.locationName = recordSession.locationName.isEmpty ? "千岛湖 · 大坝南" : recordSession.locationName
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        EnvDataView(isRecordPresented: .constant(true))
            .environmentObject(RecordSession())
    }
}
