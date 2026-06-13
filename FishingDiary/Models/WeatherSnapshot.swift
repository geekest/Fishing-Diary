import Foundation

/// 拍照时抓取的天气快照（一次性记录，不随时间变化）
struct WeatherSnapshot: Codable {
    var temperature: Double      // 气温 °C
    var windSpeed: Double        // 风速 m/s
    var windDirection: String    // 风向（东南/北…）
    var pressure: Double         // 气压 hPa
    var uvIndex: Int             // 紫外线指数
    var condition: String        // 天气描述（多云/晴…）
    var waterTemp: Double?       // 水温（预留，WeatherKit 暂无）
    var moonPhase: String?       // 月相（上弦/满月…）
    var tide: String?            // 潮汐（涨潮/退潮，预留）
}
