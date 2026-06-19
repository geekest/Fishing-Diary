import SwiftUI

// MARK: - 主操作按钮（松绿底白字）
struct PrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title)
                        .font(Theme.Font.headline)
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(isPressed ? Theme.Colors.accentDeep : Theme.Colors.accent)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field))
        }
        .disabled(isLoading)
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - 次级按钮（浅灰底）
struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.Colors.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Theme.Colors.chip)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Ghost 按钮（描边）
struct GhostButton: View {
    let title: String
    var color: Color = Theme.Colors.accent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Font.headline)
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.field)
                        .stroke(color, lineWidth: 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Chip 标签按钮
struct ChipButton: View {
    let title: String
    var isSelected: Bool = false
    var accentSelected: Bool = false   // true = 选中松绿；false = 选中墨底
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Font.subhead)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(selectedForeground)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(selectedBackground)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var selectedBackground: Color {
        if isSelected {
            return accentSelected ? Theme.Colors.accent : Theme.Colors.ink
        }
        return Theme.Colors.chip
    }

    private var selectedForeground: Color {
        isSelected ? .white : Theme.Colors.chipInk
    }
}

// MARK: - 环境数据格（EnvCell）
struct EnvCell: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.Font.data(15, weight: .medium))
                .foregroundStyle(Theme.Colors.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label)
                .font(Theme.Font.microLabel)
                .foregroundStyle(Theme.Colors.ink3)
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Space.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadowSoft()
    }
}

// MARK: - 月份/章节标题（SF Mono 大写）
struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(Theme.Font.microLabel)
            .kerning(1.2)
            .foregroundStyle(Theme.Colors.ink3)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Toggle 数据行
struct ToggleDataRow: View {
    let label: String
    let value: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Colors.ink)
            Spacer()
            Text(value)
                .font(Theme.Font.dataReading)
                .foregroundStyle(Theme.Colors.ink2)
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Theme.Colors.accent)
        }
        .padding(.horizontal, Theme.Space.lg)
        .padding(.vertical, 14)
    }
}

// MARK: - Toast 通知
struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(Theme.Font.subhead)
            .fontWeight(.medium)
            .foregroundStyle(.primary)
            .padding(.horizontal, Theme.Space.xl)
            .padding(.vertical, Theme.Space.md)
            .background(.regularMaterial, in: Capsule())
            .shadowPop()
    }
}

// MARK: - 按下缩放 ButtonStyle
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .brightness(configuration.isPressed ? -0.03 : 0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - 表单字段容器
struct FieldContainer<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(Theme.Font.microLabel)
                .kerning(0.5)
                .foregroundStyle(Theme.Colors.ink3)
            content()
        }
        .padding(Theme.Space.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field))
        .shadowSoft()
    }
}

// MARK: - Previews
#Preview("Buttons") {
    VStack(spacing: 16) {
        PrimaryButton(title: "生成分享图") {}
        SecondaryButton(title: "取消") {}
        GhostButton(title: "恢复购买") {}
        HStack {
            ChipButton(title: "全部", isSelected: true) {}
            ChipButton(title: "本月") {}
            ChipButton(title: "路亚") {}
        }
    }
    .padding()
    .background(Theme.Colors.bg)
}

#Preview("EnvCell") {
    HStack {
        EnvCell(value: "22°C", label: "气温")
        EnvCell(value: "1014", label: "气压 hPa")
        EnvCell(value: "SE 3.2", label: "风速")
        EnvCell(value: "涨潮", label: "潮汐")
    }
    .padding()
    .background(Theme.Colors.bg)
}

// MARK: - UIImage 白色描边贴纸效果
extension UIImage {
    /// 在透明 PNG 四周生成白色描边，产生剪贴贴纸视觉效果。
    /// 原理：将图像的 CGImage alpha mask 向 8 个方向各偏移 `width` 点，
    /// 每次以白色填充裁剪区，最后把原图绘制在最上层。
    func withWhiteStroke(width: CGFloat = 3) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        let margin = width * 2
        let newSize = CGSize(width: size.width + margin * 2,
                             height: size.height + margin * 2)
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.setFillColor(UIColor.white.cgColor)
        let centerRect = CGRect(x: margin, y: margin,
                                width: size.width, height: size.height)
        for step in 0..<8 {
            let angle = Double(step) * (.pi / 4)
            let dx = cos(angle) * Double(width)
            let dy = sin(angle) * Double(width)
            let shifted = centerRect.offsetBy(dx: CGFloat(dx), dy: CGFloat(dy))
            context.saveGState()
            context.clip(to: shifted, mask: cgImage)
            context.fill(shifted)
            context.restoreGState()
        }
        draw(in: centerRect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
