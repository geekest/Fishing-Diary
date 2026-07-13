import SwiftUI

// MARK: - 设置页 MVP
struct SettingsView: View {
    @EnvironmentObject var purchaseService: PurchaseService
    @AppStorage("userName") private var userName: String = "钓鱼人"
    @AppStorage("defaultWeightUnit") private var defaultWeightUnitRaw = WeightUnit.kg.rawValue

    private var defaultWeightUnit: Binding<WeightUnit> {
        Binding(
            get: { WeightUnit(rawValue: defaultWeightUnitRaw) ?? .kg },
            set: { defaultWeightUnitRaw = $0.rawValue }
        )
    }

    var body: some View {
        ZStack {
            Theme.Colors.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.xl) {
                    profileSection
                    unitSection
#if DEBUG
                    developerSection
#endif
                    legalSection
                }
                .padding(.horizontal, Theme.Space.lg)
                .padding(.vertical, Theme.Space.md)
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var profileSection: some View {
        settingsCard(title: "个人资料") {
            VStack(alignment: .leading, spacing: Theme.Space.sm) {
                Text("昵称")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Colors.ink2)
                TextField("请输入昵称", text: $userName)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .padding(Theme.Space.md)
                    .background(Theme.Colors.bg2)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field))
            }
        }
    }

    private var unitSection: some View {
        settingsCard(title: "单位偏好") {
            VStack(alignment: .leading, spacing: Theme.Space.sm) {
                Text("默认重量单位")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Colors.ink2)
                Picker("默认重量单位", selection: defaultWeightUnit) {
                    ForEach(WeightUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                Text("新建渔获时会默认使用该重量单位，已保存记录不会被改动。")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Colors.ink3)
            }
        }
    }

    private var developerSection: some View {
        settingsCard(title: "开发者调试") {
            VStack(alignment: .leading, spacing: Theme.Space.md) {
                HStack(spacing: Theme.Space.sm) {
                    Image(systemName: purchaseService.isPurchased ? "checkmark.seal.fill" : "lock.open")
                        .font(.system(size: 16))
                        .foregroundStyle(purchaseService.isPurchased ? Theme.Colors.accent : Theme.Colors.gold)
                    Text(purchaseService.isPurchased ? "当前为已订阅状态" : "当前为免费无订阅状态")
                        .font(Theme.Font.subhead)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.Colors.ink)
                    Spacer()
                }

                Button {
                    purchaseService.setDebugPurchased(!purchaseService.isPurchased)
                } label: {
                    HStack {
                        Text(purchaseService.isPurchased ? "切换为免费模式" : "切换为已订阅模式")
                            .font(Theme.Font.subhead)
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.Space.md)
                    .padding(.vertical, 12)
                    .background(purchaseService.isPurchased ? Theme.Colors.ink : Theme.Colors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field))
                }
                .buttonStyle(ScaleButtonStyle())

                Text("仅用于本地开发对比水印、导出与付费入口表现。")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Colors.ink3)
            }
        }
    }

    private var legalSection: some View {
        settingsCard(title: "隐私与协议") {
            VStack(spacing: 0) {
                NavigationLink {
                    LegalTextView(title: "用户协议", content: "当前为原型占位页面。正式上线前会补充完整的用户协议内容。")
                } label: {
                    settingsRow(icon: "doc.text", title: "用户协议")
                }
                Divider().padding(.leading, 46)
                NavigationLink {
                    LegalTextView(title: "隐私政策", content: "当前为原型占位页面。正式上线前会补充数据收集、使用和存储说明。")
                } label: {
                    settingsRow(icon: "hand.raised", title: "隐私政策")
                }
            }
        }
    }

    private func settingsCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            SectionLabel(text: title)
            content()
                .padding(Theme.Space.md)
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field))
                .shadowSoft()
        }
    }

    private func settingsRow(icon: String, title: String) -> some View {
        HStack(spacing: Theme.Space.md) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(Theme.Colors.accent)
                .frame(width: 22)
            Text(title)
                .font(Theme.Font.subhead)
                .foregroundStyle(Theme.Colors.ink)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Theme.Colors.ink3)
        }
        .padding(.vertical, 13)
        .contentShape(Rectangle())
    }
}

private struct LegalTextView: View {
    let title: String
    let content: String

    var body: some View {
        ZStack {
            Theme.Colors.bg.ignoresSafeArea()
            Text(content)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Colors.ink2)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.Space.lg)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(PurchaseService())
    }
}
