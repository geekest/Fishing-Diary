import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var currentStep = 0

    var body: some View {
        ZStack {
            Theme.Colors.bg.ignoresSafeArea()

            TabView(selection: $currentStep) {
                welcomeStep.tag(0)
                permissionsStep.tag(1)
                featuresStep.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)

            // 底部步骤点 + 按钮
            VStack {
                Spacer()
                stepDots
                    .padding(.bottom, Theme.Space.lg)
                nextButton
                    .padding(.horizontal, Theme.Space.lg)
                    .padding(.bottom, 36)
            }
        }
    }

    // MARK: - 步骤点
    private var stepDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { i in
                Capsule()
                    .fill(i == currentStep ? Theme.Colors.accent : Theme.Colors.ink3)
                    .frame(width: i == currentStep ? 20 : 6, height: 6)
                    .animation(.spring(response: 0.3), value: currentStep)
            }
        }
    }

    // MARK: - 下一步/开始按钮
    private var nextButton: some View {
        PrimaryButton(title: currentStep < 2 ? "下一步" : "开始记录") {
            if currentStep < 2 {
                withAnimation { currentStep += 1 }
            } else {
                hasOnboarded = true
            }
        }
    }

    // MARK: - Step 1：欢迎
    private var welcomeStep: some View {
        VStack(spacing: 0) {
            // 顶部插画区
            ZStack {
                Theme.Colors.catchGradientLake
                    .ignoresSafeArea(edges: .top)

                VStack(spacing: 0) {
                    Spacer()
                    Text("🎣")
                        .font(.system(size: 72))
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                    Spacer()
                }
            }
            .frame(height: 260)
            // 波浪过渡
            .overlay(alignment: .bottom) {
                ellipseTransition
            }

            // 内容区
            VStack(alignment: .leading, spacing: Theme.Space.md) {
                stepIndicator("01 / 03")

                Text("钓友的醒图")
                    .font(Theme.Font.largeTitle)
                    .foregroundStyle(Theme.Colors.ink)

                Text("拍几张图，**30 秒**生成有高级感的渔获分享图——专为发小红书、朋友圈而生。\n\n记录永远免费，分享才付费。")
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Colors.ink2)
                    .lineSpacing(4)
            }
            .padding(.horizontal, Theme.Space.xl)
            .padding(.top, Theme.Space.xxl)

            Spacer()
        }
    }

    // MARK: - Step 2：权限
    private var permissionsStep: some View {
        VStack(spacing: 0) {
            ZStack {
                Theme.Colors.catchGradientForest
                    .ignoresSafeArea(edges: .top)
                HStack(spacing: 24) {
                    Text("📷").font(.system(size: 44))
                    Text("📍").font(.system(size: 44))
                    Text("☁️").font(.system(size: 44))
                }
                .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
            }
            .frame(height: 200)
            .overlay(alignment: .bottom) { ellipseTransition }

            VStack(alignment: .leading, spacing: Theme.Space.md) {
                stepIndicator("02 / 03")

                Text("需要几个权限")
                    .font(Theme.Font.largeTitle)
                    .foregroundStyle(Theme.Colors.ink)

                Text("用来自动填钓点、天气、照片——不用手动查，**比你更懂钓鱼场景**。")
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Colors.ink2)
                    .lineSpacing(4)

                VStack(spacing: 0) {
                    permRow(icon: "camera.fill", title: "相机与相册", desc: "拍渔获照、选图抠图")
                    Divider().padding(.leading, 54)
                    permRow(icon: "location.fill", title: "位置信息", desc: "自动记录钓点，无需手填")
                    Divider().padding(.leading, 54)
                    permRow(icon: "cloud.fill", title: "天气（WeatherKit）", desc: "自动抓风速 / 气压 / UVI…")
                }
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field))
                .shadowSoft()
                .padding(.top, Theme.Space.sm)
            }
            .padding(.horizontal, Theme.Space.xl)
            .padding(.top, Theme.Space.xxl)

            Spacer()
        }
    }

    // MARK: - Step 3：功能亮点
    private var featuresStep: some View {
        VStack(spacing: 0) {
            ZStack {
                Theme.Colors.catchGradientDusk
                    .ignoresSafeArea(edges: .top)
                // 双卡片预览
                HStack(spacing: 12) {
                    // 极简数据卡缩略
                    ZStack(alignment: .bottomLeading) {
                        Theme.Colors.catchGradientForest
                        LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .center, endPoint: .bottom)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("FISHING LOG · 06.13")
                                .font(Theme.Font.microLabel)
                                .foregroundStyle(.white.opacity(0.7))
                            Text("38cm")
                                .font(.system(size: 22, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white)
                            Text("大口黑鲈")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .padding(10)
                    }
                    .frame(width: 110, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadowCard()

                    // 功能特性列表
                    VStack(alignment: .leading, spacing: 10) {
                        featureRow("🌊", "天气自动入卡")
                        featureRow("🐟", "一键抠图贴纸")
                        featureRow("✦", "多款精美模板")
                    }
                }
                .padding(.horizontal, 24)
            }
            .frame(height: 220)
            .overlay(alignment: .bottom) { ellipseTransition }

            VStack(alignment: .leading, spacing: Theme.Space.md) {
                stepIndicator("03 / 03")

                Text("30 秒出一张好图")
                    .font(Theme.Font.largeTitle)
                    .foregroundStyle(Theme.Colors.ink)

                VStack(alignment: .leading, spacing: Theme.Space.md) {
                    featureDetail(icon: "🌊", title: "环境数据自动入卡", desc: "风速、气压、潮汐、UVI，拍照即抓")
                    featureDetail(icon: "🐟", title: "抠图贴纸", desc: "每条鱼一键抠图成 die-cut 贴纸")
                    featureDetail(icon: "✦", title: "5 套精美模板", desc: "极简数据卡 · 户外科技 · 贴纸墙…")
                }
            }
            .padding(.horizontal, Theme.Space.xl)
            .padding(.top, Theme.Space.xxl)

            Spacer()
        }
    }

    // MARK: - 辅助组件
    private var ellipseTransition: some View {
        Theme.Colors.bg
            .frame(height: 40)
            .clipShape(Ellipse().scale(x: 1.5, y: 1))
            .offset(y: 20)
    }

    private func stepIndicator(_ text: String) -> some View {
        Text(text)
            .font(Theme.Font.microLabel)
            .kerning(1.5)
            .foregroundStyle(Theme.Colors.accent)
    }

    private func permRow(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: Theme.Space.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Theme.Colors.accent)
                .frame(width: 30)
                .padding(.leading, Theme.Space.sm)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Font.subhead)
                    .fontWeight(.medium)
                    .foregroundStyle(Theme.Colors.ink)
                Text(desc)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Colors.ink2)
            }
            Spacer()
        }
        .padding(.vertical, 13)
        .padding(.horizontal, Theme.Space.sm)
    }

    private func featureRow(_ emoji: String, _ text: String) -> some View {
        HStack(spacing: 6) {
            Text(emoji).font(.system(size: 14))
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    private func featureDetail(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Space.md) {
            Text(icon).font(.title3).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Font.subhead)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Colors.ink)
                Text(desc)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Colors.ink2)
            }
        }
    }
}

#Preview {
    OnboardingView()
}
