import Foundation
import Combine

// TODO: 接入真实 StoreKit 2
// Product IDs:
//   com.placeholder.FishingDiary.unlock   （Non-Consumable，买断 ¥68）
//   com.placeholder.FishingDiary.monthly  （Auto-Renewable，月订阅 ¥6）
//
// 真实实现框架：
//   import StoreKit
//
//   func loadProducts() async {
//       let products = try? await Product.products(for: [unlockID, monthlyID])
//   }
//
//   func purchase(_ product: Product) async throws {
//       let result = try await product.purchase()
//       if case .success(let verification) = result {
//           let transaction = try verification.payloadValue
//           await transaction.finish()
//           isPurchased = true
//       }
//   }
//
//   // 启动时检查权益
//   func checkEntitlements() async {
//       for await result in Transaction.currentEntitlements {
//           if let transaction = try? result.payloadValue {
//               isPurchased = transaction.productID == unlockID ||
//                             transaction.revocationDate == nil
//           }
//       }
//   }

/// 购买服务（当前为 Mock 实现）
class PurchaseService: ObservableObject {
    static let unlockProductID = "com.placeholder.FishingDiary.unlock"
    static let monthlyProductID = "com.placeholder.FishingDiary.monthly"

    /// 是否已解锁高清导出（持久化到 AppStorage）
    @Published var isPurchased: Bool {
        didSet { UserDefaults.standard.set(isPurchased, forKey: "isPro") }
    }

    @Published var isPurchasing: Bool = false

    init() {
        self.isPurchased = true
        UserDefaults.standard.set(true, forKey: "isPro")
        // TODO: 启动时调用 checkEntitlements()
    }

    enum PurchaseType {
        case unlock   // 买断
        case monthly  // 月订阅
    }

    /// 发起购买（Mock：直接解锁）
    func purchase(_ type: PurchaseType) async {
        // TODO: 替换为真实 StoreKit 2 购买流程
        isPurchasing = true
        try? await Task.sleep(nanoseconds: 800_000_000)  // 模拟网络请求
        await MainActor.run {
            isPurchased = true
            isPurchasing = false
        }
    }

    /// 恢复购买
    func restore() async {
        // TODO: 替换为真实 Transaction.currentEntitlements 检查
        isPurchasing = true
        try? await Task.sleep(nanoseconds: 500_000_000)
        await MainActor.run { isPurchasing = false }
    }
}
