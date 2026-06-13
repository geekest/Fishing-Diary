import SwiftUI
import SwiftData

@main
struct FishingDiaryApp: App {
    /// 购买服务全局单例（注入环境）
    @StateObject private var purchaseService = PurchaseService()
    /// 记录流临时状态（注入环境）
    @StateObject private var recordSession = RecordSession()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(purchaseService)
                .environmentObject(recordSession)
        }
        .modelContainer(for: [FishingSession.self, FishCatch.self])
    }
}
