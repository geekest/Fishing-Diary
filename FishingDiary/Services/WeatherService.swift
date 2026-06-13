import Foundation
import CoreLocation

// TODO: 接入真实 WeatherKit
// 需要在 Apple Developer Console 启用 WeatherKit capability
// 真实实现示例：
//   import WeatherKit
//   let service = WeatherService.shared
//   let weather = try await service.weather(for: location)
//   weather.currentWeather.temperature
//   weather.currentWeather.wind.speed
//   weather.currentWeather.pressure
//   weather.currentWeather.uvIndex
//   weather.currentWeather.condition.description
//   weather.dailyForecast.first?.moon.phase

/// 天气服务（当前为 Mock 实现）
class WeatherService {
    static let shared = WeatherService()
    private init() {}

    /// 获取当前位置天气（Mock 返回固定数据，真实接入后替换）
    func fetchCurrent(for location: CLLocation) async -> WeatherSnapshot {
        // TODO: 替换为真实 WeatherKit 调用
        // 模拟网络延迟
        try? await Task.sleep(nanoseconds: 500_000_000)

        return WeatherSnapshot(
            temperature: 22.0,
            windSpeed: 3.2,
            windDirection: "东南",
            pressure: 1014.0,
            uvIndex: 5,
            condition: "多云",
            waterTemp: nil,
            moonPhase: "上弦 ◑",
            tide: "涨潮 · 大"
        )
    }
}
