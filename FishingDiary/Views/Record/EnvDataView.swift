import SwiftUI
import CoreLocation

// MARK: - 环境数据界面（默认带入，全部可编辑）
struct EnvDataView: View {
    @Binding var isRecordPresented: Bool
    @EnvironmentObject var recordSession: RecordSession

    @State private var isLoading = true
    @State private var navigateToSaved = false
    @State private var locating = false
    @State private var locator = OneShotLocation()

    // 枚举选项
    private let windDirections = ["北", "东北", "东", "东南", "南", "西南", "西", "西北"]
    private let tideOptions = ["涨潮", "落潮", "平潮"]
    private let moonOptions = ["新月", "上弦月", "满月", "下弦月"]
    private let conditionOptions = ["晴", "多云", "阴", "小雨", "中雨", "大雨", "雷阵雨", "雪"]

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
                    Image(systemName: "pencil.circle.fill")
                        .font(.caption)
                    Text("已带入当前数据，可直接编辑或关掉不想记录的项 ↓")
                        .font(Theme.Font.caption)
                }
                .foregroundStyle(Theme.Colors.accent)
                .padding(.horizontal, Theme.Space.md)
                .padding(.vertical, Theme.Space.sm)
                .background(Theme.Colors.accentSoft)
                .clipShape(Capsule())
                .padding(.horizontal, Theme.Space.lg)
                .padding(.top, Theme.Space.md)

                // 可编辑数据列表
                VStack(spacing: 0) {
                    locationRow
                    divider
                    numberRow("气温", unit: "°C", value: numberText(\.temperature), toggle: \.temperature)
                    divider
                    numberRow("水温", unit: "°C", value: optNumberText(\.waterTemp), toggle: \.waterTemp)
                    divider
                    windRow
                    divider
                    numberRow("气压", unit: "hPa", value: numberText(\.pressure), toggle: \.pressure)
                    divider
                    numberRow("紫外线 UVI", unit: "", value: intText(\.uvIndex), toggle: \.uvIndex)
                    divider
                    enumRow("潮汐", options: tideOptions, selection: optStringText(\.tide), toggle: \.tide)
                    divider
                    enumRow("月相", options: moonOptions, selection: optStringText(\.moonPhase), toggle: \.moonPhase)
                    divider
                    enumRow("天气", options: conditionOptions, selection: stringText(\.condition), toggle: \.condition)
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
        Divider().padding(.leading, Theme.Space.lg)
    }

    // MARK: - 定位行
    private var locationRow: some View {
        HStack(spacing: Theme.Space.sm) {
            Text("定位")
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Colors.ink)
            Spacer()
            TextField("钓点名称", text: $recordSession.locationName)
                .multilineTextAlignment(.trailing)
                .font(Theme.Font.dataReading)
                .foregroundStyle(Theme.Colors.ink)
            Button {
                locateNow()
            } label: {
                if locating {
                    ProgressView().scaleEffect(0.7)
                } else {
                    Image(systemName: "location.fill")
                        .foregroundStyle(Theme.Colors.accent)
                }
            }
            .buttonStyle(.plain)
            Toggle("", isOn: bindToggle(\.location))
                .labelsHidden()
                .tint(Theme.Colors.accent)
        }
        .padding(.horizontal, Theme.Space.lg)
        .padding(.vertical, 12)
    }

    // MARK: - 风速 / 风向行（方向下拉 + 风速手输）
    private var windRow: some View {
        HStack(spacing: Theme.Space.sm) {
            Text("风速/风向")
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Colors.ink)
            Spacer()
            Menu {
                ForEach(windDirections, id: \.self) { d in
                    Button(d) { stringText(\.windDirection).wrappedValue = d }
                }
            } label: {
                menuLabel(stringText(\.windDirection).wrappedValue, placeholder: "风向")
            }
            TextField("--", text: numberText(\.windSpeed))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(Theme.Font.dataReading)
                .foregroundStyle(Theme.Colors.ink)
                .frame(width: 46)
            Text("m/s")
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.Colors.ink3)
            Toggle("", isOn: bindToggle(\.wind))
                .labelsHidden()
                .tint(Theme.Colors.accent)
        }
        .padding(.horizontal, Theme.Space.lg)
        .padding(.vertical, 12)
    }

    // MARK: - 数字行
    private func numberRow(_ label: String, unit: String, value: Binding<String>, toggle: WritableKeyPath<WeatherToggles, Bool>) -> some View {
        HStack(spacing: Theme.Space.sm) {
            Text(label)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Colors.ink)
            Spacer()
            TextField("--", text: value)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(Theme.Font.dataReading)
                .foregroundStyle(Theme.Colors.ink)
                .frame(width: 70)
            if !unit.isEmpty {
                Text(unit)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Colors.ink3)
            }
            Toggle("", isOn: bindToggle(toggle))
                .labelsHidden()
                .tint(Theme.Colors.accent)
        }
        .padding(.horizontal, Theme.Space.lg)
        .padding(.vertical, 12)
    }

    // MARK: - 枚举行（下拉单选）
    private func enumRow(_ label: String, options: [String], selection: Binding<String>, toggle: WritableKeyPath<WeatherToggles, Bool>) -> some View {
        HStack(spacing: Theme.Space.sm) {
            Text(label)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Colors.ink)
            Spacer()
            Menu {
                ForEach(options, id: \.self) { opt in
                    Button(opt) { selection.wrappedValue = opt }
                }
            } label: {
                menuLabel(selection.wrappedValue, placeholder: "选择")
            }
            Toggle("", isOn: bindToggle(toggle))
                .labelsHidden()
                .tint(Theme.Colors.accent)
        }
        .padding(.horizontal, Theme.Space.lg)
        .padding(.vertical, 12)
    }

    private func menuLabel(_ value: String, placeholder: String) -> some View {
        HStack(spacing: 4) {
            Text(value.isEmpty ? placeholder : value)
                .font(Theme.Font.dataReading)
                .foregroundStyle(value.isEmpty ? Theme.Colors.ink3 : Theme.Colors.accent)
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 10))
                .foregroundStyle(Theme.Colors.ink3)
        }
    }

    // MARK: - 绑定辅助
    private func bindToggle(_ keyPath: WritableKeyPath<WeatherToggles, Bool>) -> Binding<Bool> {
        Binding(
            get: { recordSession.weatherToggles[keyPath: keyPath] },
            set: { recordSession.weatherToggles[keyPath: keyPath] = $0 }
        )
    }

    private func ensureWeather() {
        if recordSession.weather == nil {
            recordSession.weather = WeatherSnapshot(
                temperature: 0, windSpeed: 0, windDirection: "", pressure: 0,
                uvIndex: 0, condition: "", waterTemp: nil, moonPhase: nil, tide: nil
            )
        }
    }

    private func numberText(_ kp: WritableKeyPath<WeatherSnapshot, Double>) -> Binding<String> {
        Binding(
            get: {
                guard let v = recordSession.weather?[keyPath: kp], v != 0 else { return "" }
                return trimNumber(v)
            },
            set: { str in
                ensureWeather()
                recordSession.weather?[keyPath: kp] = Double(str) ?? 0
            }
        )
    }

    private func optNumberText(_ kp: WritableKeyPath<WeatherSnapshot, Double?>) -> Binding<String> {
        Binding(
            get: {
                guard let outer = recordSession.weather?[keyPath: kp], let v = outer else { return "" }
                return trimNumber(v)
            },
            set: { str in
                ensureWeather()
                recordSession.weather?[keyPath: kp] = Double(str)
            }
        )
    }

    private func intText(_ kp: WritableKeyPath<WeatherSnapshot, Int>) -> Binding<String> {
        Binding(
            get: {
                guard let v = recordSession.weather?[keyPath: kp], v != 0 else { return "" }
                return "\(v)"
            },
            set: { str in
                ensureWeather()
                recordSession.weather?[keyPath: kp] = Int(str) ?? 0
            }
        )
    }

    private func stringText(_ kp: WritableKeyPath<WeatherSnapshot, String>) -> Binding<String> {
        Binding(
            get: { recordSession.weather?[keyPath: kp] ?? "" },
            set: { str in
                ensureWeather()
                recordSession.weather?[keyPath: kp] = str
            }
        )
    }

    private func optStringText(_ kp: WritableKeyPath<WeatherSnapshot, String?>) -> Binding<String> {
        Binding(
            get: { (recordSession.weather?[keyPath: kp] ?? nil) ?? "" },
            set: { str in
                ensureWeather()
                recordSession.weather?[keyPath: kp] = str.isEmpty ? nil : str
            }
        )
    }

    // MARK: - 实时定位
    private func locateNow() {
        locating = true
        locator.fetch { loc in
            DispatchQueue.main.async {
                guard let loc = loc else {
                    locating = false
                    return
                }
                recordSession.latitude = loc.coordinate.latitude
                recordSession.longitude = loc.coordinate.longitude
                CLGeocoder().reverseGeocodeLocation(loc) { placemarks, _ in
                    if let p = placemarks?.first {
                        let parts = [p.locality, p.subLocality, p.name].compactMap { $0 }
                        let name = parts.prefix(2).joined(separator: " · ")
                        if !name.isEmpty { recordSession.locationName = name }
                    }
                    locating = false
                }
            }
        }
    }

    // MARK: - 加载天气（默认带入，可编辑）
    private func loadWeather() async {
        let mockLocation = CLLocation(latitude: 29.6, longitude: 119.0)
        let weather = await WeatherService.shared.fetchCurrent(for: mockLocation)
        if recordSession.weather == nil {
            recordSession.weather = weather
        }
        if recordSession.locationName.isEmpty {
            recordSession.locationName = "千岛湖 · 大坝南"
        }
        if recordSession.latitude == nil || recordSession.longitude == nil {
            recordSession.latitude = mockLocation.coordinate.latitude
            recordSession.longitude = mockLocation.coordinate.longitude
        }
        isLoading = false
    }
}

// MARK: - 数字格式化（整数不带小数，其余一位）
private func trimNumber(_ v: Double) -> String {
    v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.1f", v)
}

// MARK: - 一次性定位（请求权限 + 取一次当前位置）
final class OneShotLocation: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var completion: ((CLLocation?) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func fetch(_ completion: @escaping (CLLocation?) -> Void) {
        self.completion = completion
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            finish(nil)
        }
    }

    private func finish(_ loc: CLLocation?) {
        completion?(loc)
        completion = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if completion != nil { manager.requestLocation() }
        case .denied, .restricted:
            finish(nil)
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        finish(locations.last)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish(nil)
    }
}

#Preview {
    NavigationStack {
        EnvDataView(isRecordPresented: .constant(true))
            .environmentObject(RecordSession())
    }
}
