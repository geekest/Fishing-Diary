import SwiftUI

// MARK: - Design token 单一来源
enum Theme {

    // MARK: Colors
    enum Colors {
        static let bg          = Color(hex: "F7F4EF")   // 全局底色·暖纸
        static let bg2         = Color(hex: "EFEAE2")   // 次背景·分组凹陷
        static let surface     = Color(hex: "FFFFFF")   // 卡片/面板/字段
        static let ink         = Color(hex: "1C1C1E")   // 主文字·大数字
        static let ink2        = Color(hex: "8A8580")   // 次文字
        static let ink3        = Color(hex: "C0BBB5")   // 三级/占位符
        static let accent      = Color(hex: "1F6F5C")   // 品牌松绿
        static let accentDeep  = Color(hex: "155244")   // 松绿按下态
        static let accentSoft  = Color(hex: "E4F0EB")   // 松绿浅底
        static let chip        = Color(hex: "F2EEE8")   // chip 底色
        static let chipInk     = Color(hex: "6B6560")   // chip 文字
        static let hairline    = Color.black.opacity(0.07)
        static let gold        = Color(hex: "C99A3F")   // 里程碑·付费高光

        // 渔获照片渐变（无图占位 / 照片暗角打底）
        static let catchGradientForest = LinearGradient(
            colors: [Color(hex: "3D5835"), Color(hex: "223020")],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        static let catchGradientLake = LinearGradient(
            colors: [Color(hex: "4A6258"), Color(hex: "2A3C35")],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        static let catchGradientDusk = LinearGradient(
            colors: [Color(hex: "6A5838"), Color(hex: "403520")],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )

        static func catchGradient(for id: UUID) -> LinearGradient {
            let gradients: [LinearGradient] = [catchGradientForest, catchGradientLake, catchGradientDusk]
            let index = abs(id.hashValue) % gradients.count
            return gradients[index]
        }
    }

    // MARK: Typography
    enum Font {
        // 读数一律等宽 SF Mono
        static func data(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .monospaced)
        }

        // 大数字展示（体长）
        static let displayNumber = SwiftUI.Font.system(size: 34, weight: .medium, design: .monospaced)

        // 环境读数行
        static let dataReading = SwiftUI.Font.system(size: 15, weight: .regular, design: .monospaced)

        // Micro 标签（大写+字距）
        static let microLabel = SwiftUI.Font.system(size: 10, weight: .medium, design: .monospaced)

        // 普通叙述文字（SF Pro）
        static let largeTitle  = SwiftUI.Font.system(size: 28, weight: .bold)
        static let title       = SwiftUI.Font.system(size: 22, weight: .bold)
        static let headline    = SwiftUI.Font.system(size: 17, weight: .semibold)
        static let body        = SwiftUI.Font.system(size: 15, weight: .regular)
        static let subhead     = SwiftUI.Font.system(size: 13, weight: .regular)
        static let caption     = SwiftUI.Font.system(size: 11, weight: .regular)
    }

    // MARK: Spacing (4 的倍数)
    enum Space {
        static let xs:  CGFloat = 4
        static let sm:  CGFloat = 8
        static let md:  CGFloat = 12
        static let lg:  CGFloat = 16
        static let xl:  CGFloat = 20
        static let xxl: CGFloat = 24
    }

    // MARK: Corner Radius
    enum Radius {
        static let field:  CGFloat = 14
        static let photo:  CGFloat = 16
        static let card:   CGFloat = 18
        static let sheet:  CGFloat = 24
    }

    // MARK: Shadow
    enum Shadow {
        // 字段/小卡
        static func soft(in view: some View) -> some View {
            view.shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
        // 渔获卡/面板
        static func card(in view: some View) -> some View {
            view.shadow(color: .black.opacity(0.07), radius: 6, x: 0, y: 1)
        }
        // 弹层/sheet
        static func pop(in view: some View) -> some View {
            view.shadow(color: .black.opacity(0.16), radius: 15, x: 0, y: 8)
        }

        static let softValues: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) =
            (.black.opacity(0.05), 3, 0, 1)
        static let cardValues: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) =
            (.black.opacity(0.07), 6, 0, 1)
        static let popValues: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) =
            (.black.opacity(0.16), 15, 0, 8)
    }
}

// MARK: - Color hex 扩展
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xff) / 255
        let g = Double((int >> 8) & 0xff) / 255
        let b = Double(int & 0xff) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

// MARK: - View 阴影快捷扩展
extension View {
    func shadowSoft() -> some View {
        self.shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
    func shadowCard() -> some View {
        self.shadow(color: .black.opacity(0.07), radius: 6, x: 0, y: 1)
    }
    func shadowPop() -> some View {
        self.shadow(color: .black.opacity(0.16), radius: 15, x: 0, y: 8)
    }
}
