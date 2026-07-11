import SwiftUI

// MARK: - 设置页 MVP
struct SettingsView: View {
    @AppStorage("userName") private var userName: String = "钓鱼人"
    @AppStorage("defaultWeightUnit") private var defaultWeightUnitRaw = WeightUnit.kg.rawValue
    @AppStorage("appLanguage") private var appLanguageRaw = AppLanguage.simplifiedChinese.rawValue

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
                    languageSection
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

    private var languageSection: some View {
        settingsCard(title: "语言") {
            NavigationLink {
                LanguageSettingsView(selectedLanguageRaw: $appLanguageRaw)
            } label: {
                settingsRow(icon: "globe", title: "应用语言", trailing: currentLanguage.nativeName)
            }
        }
    }

    private var currentLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .simplifiedChinese
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
            Text(LocalizedStringKey(title.uppercased()))
                .font(Theme.Font.microLabel)
                .kerning(1.2)
                .foregroundStyle(Theme.Colors.ink3)
                .frame(maxWidth: .infinity, alignment: .leading)
            content()
                .padding(Theme.Space.md)
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field))
                .shadowSoft()
        }
    }

    private func settingsRow(icon: String, title: LocalizedStringKey, trailing: String? = nil) -> some View {
        HStack(spacing: Theme.Space.md) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(Theme.Colors.accent)
                .frame(width: 22)
            Text(title)
                .font(Theme.Font.subhead)
                .foregroundStyle(Theme.Colors.ink)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Colors.ink3)
            }
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Theme.Colors.ink3)
        }
        .padding(.vertical, 13)
        .contentShape(Rectangle())
    }
}

private struct LanguageSettingsView: View {
    @Binding var selectedLanguageRaw: String

    var body: some View {
        ZStack {
            Theme.Colors.bg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: Theme.Space.md) {
                Text("选择后会立即应用到支持多语言的页面。")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Colors.ink2)
                    .padding(.horizontal, Theme.Space.lg)

                VStack(spacing: 0) {
                    ForEach(AppLanguage.allCases) { language in
                        Button {
                            selectedLanguageRaw = language.rawValue
                        } label: {
                            HStack(spacing: Theme.Space.md) {
                                Text(language.nativeName)
                                    .font(Theme.Font.subhead)
                                    .foregroundStyle(Theme.Colors.ink)
                                Spacer()
                                if selectedLanguageRaw == language.rawValue {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(Theme.Colors.accent)
                                }
                            }
                            .padding(Theme.Space.md)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if language != AppLanguage.allCases.last {
                            Divider().padding(.leading, Theme.Space.md)
                        }
                    }
                }
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field))
                .shadowSoft()
                .padding(.horizontal, Theme.Space.lg)

                Spacer()
            }
            .padding(.vertical, Theme.Space.md)
        }
        .navigationTitle("语言")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LegalTextView: View {
    let title: LocalizedStringKey
    let content: LocalizedStringKey

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
    }
}
