import Foundation
import UIKit
import Combine

/// 记录流的临时状态容器（全局注入，保存完成后 reset）
class RecordSession: ObservableObject {
    /// 用户选择的原始图片（多张）
    @Published var rawImages: [UIImage] = []

    /// 抠图结果（nil 表示跳过，使用原图）
    @Published var cutoutImages: [UIImage?] = []

    /// 当前正在编辑的抠图索引
    @Published var currentCutoutIndex: Int = 0

    /// 每尾鱼的填写数据（鱼种、体长、重量）
    @Published var fishForms: [FishForm] = []

    /// 当前正在编辑的鱼表单索引
    @Published var currentFishIndex: Int = 0

    /// 定位地名（EnvDataView 进入时自动写入）
    @Published var locationName: String = ""
    @Published var latitude: Double? = nil
    @Published var longitude: Double? = nil

    /// 天气快照（EnvDataView 获取后写入）
    @Published var weather: WeatherSnapshot? = nil

    /// 用户选择是否纳入天气字段
    @Published var weatherToggles: WeatherToggles = .defaultOn

    // MARK: - 计算属性

    /// 已完成抠图的有效图片（cutout 结果或原图）
    var effectiveImages: [UIImage] {
        rawImages.enumerated().map { i, raw in
            cutoutImages.indices.contains(i) ? (cutoutImages[i] ?? raw) : raw
        }
    }

    // MARK: - 重置

    /// 保存完成后清空所有临时状态
    func reset() {
        rawImages = []
        cutoutImages = []
        currentCutoutIndex = 0
        fishForms = []
        currentFishIndex = 0
        locationName = ""
        latitude = nil
        longitude = nil
        weather = nil
        weatherToggles = .defaultOn
    }
}

// MARK: - 子类型

/// 单尾鱼的填写表单
struct FishForm: Identifiable {
    var id = UUID()
    var speciesName: String = ""
    var lengthCm: String = ""   // 用字符串方便 TextField 绑定
    var weightKg: String = ""   // 选填
}

/// 用户选择纳入天气快照的字段开关
struct WeatherToggles {
    var location: Bool
    var temperature: Bool
    var waterTemp: Bool
    var wind: Bool
    var pressure: Bool
    var uvIndex: Bool
    var tide: Bool
    var moonPhase: Bool
    var condition: Bool

    static let defaultOn = WeatherToggles(
        location: true,
        temperature: true,
        waterTemp: false,
        wind: true,
        pressure: true,
        uvIndex: false,
        tide: true,
        moonPhase: false,
        condition: true
    )
}
