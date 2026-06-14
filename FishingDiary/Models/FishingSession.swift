import Foundation
import SwiftData

/// 一次出钓记录（包含多尾渔获）
@Model
class FishingSession {
    var id: UUID
    var date: Date
    var locationName: String          // 反地理编码的地名
    var latitude: Double?             // 坐标（可选，定位失败时为空）
    var longitude: Double?
    @Relationship(deleteRule: .cascade)
    var catches: [FishCatch]          // 一对多
    var weatherData: Data?            // WeatherSnapshot 序列化存储
    var coverImageData: Data?         // 封面图（第一条鱼的抠图）
    var notes: String?
    var fishingMethod: String = ""    // 钓法（路亚/台钓/矶钓/筏钓/其他）

    init(
        id: UUID = UUID(),
        date: Date = .now,
        locationName: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        catches: [FishCatch] = [],
        weatherData: Data? = nil,
        coverImageData: Data? = nil,
        notes: String? = nil,
        fishingMethod: String = ""
    ) {
        self.id = id
        self.date = date
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.catches = catches
        self.weatherData = weatherData
        self.coverImageData = coverImageData
        self.notes = notes
        self.fishingMethod = fishingMethod
    }

    /// 解码天气快照
    var weather: WeatherSnapshot? {
        get {
            guard let data = weatherData else { return nil }
            return try? JSONDecoder().decode(WeatherSnapshot.self, from: data)
        }
        set {
            weatherData = try? JSONEncoder().encode(newValue)
        }
    }

    /// 总渔获数
    var totalCatch: Int { catches.count }

    /// 鱼种列表（去重）
    var speciesNames: [String] {
        Array(Set(catches.map(\.speciesName))).sorted()
    }
}
