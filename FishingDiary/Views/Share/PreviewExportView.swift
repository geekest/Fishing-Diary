import SwiftUI

// MARK: - 出图预览 + 付费墙
struct PreviewExportView: View {
    let session: FishingSession
    let config: ShareElementsConfig
    let ratio: ShareStyleView.CardRatio
    @Binding var isRecordPresented: Bool

    @EnvironmentObject var purchaseService: PurchaseService
    @State private var showPaywall = true
    @State private var showShareSheet = false
    @State private var renderedImage: UIImage? = nil
    @State private var showSaveToast = false
    @State private var selectedPlan: PurchasePlan = .unlock
    @State private var saveToastMessage = ""

    enum PurchasePlan { case unlock, monthly }

    var body: some View {
        ZStack {
            Theme.Colors.bg.ignoresSafeArea()

            // 按最终导出图片等比预览，不再拉伸铺满屏幕。
            ShareCardPreview(
                session: session,
                config: config,
                ratio: ratio,
                showWatermark: !purchaseService.isPurchased,
                cornerRadius: 0
            )
            .padding(.horizontal, Theme.Space.lg)
            .padding(.vertical, Theme.Space.md)

            // 顶部导航覆盖
            VStack {
                HStack {
                    Spacer()
                    if purchaseService.isPurchased {
                        Button {
                            exportImage()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(.black.opacity(0.35))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, Theme.Space.lg)
                    }
                }
                .padding(.top, 8)
                Spacer()
            }

            // Toast
            if showSaveToast {
                VStack {
                    Spacer()
                    ToastView(message: saveToastMessage)
                        .padding(.bottom, showPaywall ? 380 : 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showPaywall) {
            paywallSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(Theme.Radius.sheet)
        }
        .onChange(of: purchaseService.isPurchased) { _, newValue in
            if newValue {
                showPaywall = false
                exportImage()
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let img = renderedImage {
                ShareSheet(items: [img])
            }
        }
    }

    // MARK: - 付费墙 Sheet
    private var paywallSheet: some View {
        ZStack {
            Theme.Colors.surface.ignoresSafeArea()

            VStack(spacing: 0) {
                // 抓手
                Capsule()
                    .fill(Theme.Colors.ink3)
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)
                    .padding(.bottom, Theme.Space.lg)

                // 锁图标
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.Colors.gold)
                    .padding(.bottom, Theme.Space.sm)

                // 标题
                Text("导出无水印高清图")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Colors.ink)

                Text("解锁全部模板 · 3 种画幅任意导出")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Colors.ink2)
                    .padding(.top, 4)
                    .padding(.bottom, Theme.Space.lg)

                // 方案选择
                VStack(spacing: Theme.Space.sm) {
                    planRow(
                        plan: .unlock,
                        title: "一次性买断",
                        subtitle: "永久解锁 · 不限张数",
                        price: "¥68",
                        badge: "最实惠 · 省 ¥40"
                    )
                    planRow(
                        plan: .monthly,
                        title: "月订阅",
                        subtitle: "随时取消",
                        price: "¥6/月",
                        badge: nil
                    )
                }
                .padding(.horizontal, Theme.Space.lg)

                // 购买按钮
                PrimaryButton(
                    title: selectedPlan == .unlock ? "永久解锁 · ¥68" : "订阅解锁 · ¥6/月",
                    isLoading: purchaseService.isPurchasing
                ) {
                    Task {
                        await purchaseService.purchase(selectedPlan == .unlock ? .unlock : .monthly)
                    }
                }
                .padding(.horizontal, Theme.Space.lg)
                .padding(.top, Theme.Space.md)

                // 底部链接
                HStack(spacing: Theme.Space.lg) {
                    Button("恢复购买") { Task { await purchaseService.restore() } }
                    Text("·").foregroundStyle(Theme.Colors.ink3)
                    Button("用户协议") {}
                    Text("·").foregroundStyle(Theme.Colors.ink3)
                    Button("隐私政策") {}
                }
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.Colors.ink2)
                .padding(.top, Theme.Space.md)
                .padding(.bottom, Theme.Space.xl)
            }
        }
    }

    private func planRow(plan: PurchasePlan, title: String, subtitle: String, price: String, badge: String?) -> some View {
        let isSelected = selectedPlan == plan

        return Button {
            selectedPlan = plan
        } label: {
            ZStack(alignment: .topTrailing) {
                HStack(spacing: Theme.Space.md) {
                    // 单选圆点
                    ZStack {
                        Circle()
                            .stroke(isSelected ? Theme.Colors.accent : Theme.Colors.ink3, lineWidth: 1.5)
                            .frame(width: 20, height: 20)
                        if isSelected {
                            Circle()
                                .fill(Theme.Colors.accent)
                                .frame(width: 10, height: 10)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(Theme.Font.subhead)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.Colors.ink)
                        Text(subtitle)
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.Colors.ink2)
                    }

                    Spacer()

                    Text(price)
                        .font(Theme.Font.data(16, weight: .medium))
                        .foregroundStyle(isSelected ? (plan == .unlock ? Theme.Colors.gold : Theme.Colors.accent) : Theme.Colors.ink2)
                }
                .padding(Theme.Space.md)
                .background(isSelected ? (plan == .unlock ? Theme.Colors.gold.opacity(0.06) : Theme.Colors.accentSoft) : Theme.Colors.bg2)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.field)
                        .stroke(isSelected ? (plan == .unlock ? Theme.Colors.gold : Theme.Colors.accent) : Theme.Colors.hairline,
                                lineWidth: isSelected ? 1.5 : 1)
                )

                // Badge
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.Colors.gold)
                        .clipShape(Capsule())
                        .offset(x: -12, y: -10)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 导出
    private func exportImage() {
        Task { @MainActor in
            let img = ImageRenderService.renderCard(
                session: session,
                visibleElements: config,
                ratio: ImageRenderService.CardRatio(ratio)
            )
            renderedImage = img
            ImageRenderService.saveToPhotoLibrary(img) { success in
                saveToastMessage = success ? "高清图已存入相册 ✓" : "保存失败，请检查相册权限"
                withAnimation { showSaveToast = true }
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    withAnimation { showSaveToast = false }
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    showShareSheet = true
                }
            }
        }
    }
}

// MARK: - UIActivityViewController 包装
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        PreviewExportView(
            session: FishingSession(date: .now, locationName: "千岛湖"),
            config: ShareElementsConfig(),
            ratio: .threeByFour,
            isRecordPresented: .constant(true)
        )
        .environmentObject(PurchaseService())
    }
    .modelContainer(for: [FishingSession.self, FishCatch.self], inMemory: true)
}
