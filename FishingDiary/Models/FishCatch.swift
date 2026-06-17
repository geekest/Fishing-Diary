import Foundation
import SwiftData

/// 一尾渔获记录
@Model
class FishCatch {
    var id: UUID
    var speciesName: String       // 鱼种（用户手填）
    var lengthCm: Double?         // 体长 cm
    var weightKg: Double?         // 重量 kg（选填）
    var fishingMethod: String = ""// 钓法（每尾各自，未填为空）
    var cutoutImageData: Data     // 抠图后的 PNG（透明背景）
    var originalImageData: Data   // 原图备份
    var sortIndex: Int            // 同一 Session 内排序

    init(
        id: UUID = UUID(),
        speciesName: String = "",
        lengthCm: Double? = nil,
        weightKg: Double? = nil,
        fishingMethod: String = "",
        cutoutImageData: Data,
        originalImageData: Data,
        sortIndex: Int = 0
    ) {
        self.id = id
        self.speciesName = speciesName
        self.lengthCm = lengthCm
        self.weightKg = weightKg
        self.fishingMethod = fishingMethod
        self.cutoutImageData = cutoutImageData
        self.originalImageData = originalImageData
        self.sortIndex = sortIndex
    }
}
