import SwiftUI
import SwiftData

@main
struct FishingDiaryApp: App {
    /// 购买服务全局单例（注入环境）
    @StateObject private var purchaseService = PurchaseService()
    /// 记录流临时状态（注入环境）
    @StateObject private var recordSession = RecordSession()
    @AppStorage("appLanguage") private var appLanguageRaw = AppLanguage.simplifiedChinese.rawValue

    private var currentLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .simplifiedChinese
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(purchaseService)
                .environmentObject(recordSession)
                .environment(\.locale, Locale(identifier: currentLanguage.localeIdentifier))
        }
        .modelContainer(for: [FishingSession.self, FishCatch.self])
    }
}
