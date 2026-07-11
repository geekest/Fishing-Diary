import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case simplifiedChinese = "zh-Hans"
    case english = "en"
    case japanese = "ja"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .simplifiedChinese: "简体中文"
        case .english: "English"
        case .japanese: "日语"
        }
    }

    var nativeName: String {
        switch self {
        case .simplifiedChinese: "简体中文"
        case .english: "English"
        case .japanese: "日本語"
        }
    }

    var localeIdentifier: String { rawValue }
}
