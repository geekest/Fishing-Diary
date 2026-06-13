import SwiftUI

/// 出图预览 + 付费墙
struct PreviewExportView: View {
    let session: FishingSession
    let config: ShareElementsConfig
    @Binding var isRecordPresented: Bool

    @EnvironmentObject var purchaseService: PurchaseService
    @State private var showPaywall = true
    @State private var showShareSheet = false
    @State private var renderedImage: UIImage? = nil
    @State private var showSuccessToast = false

    var body: some View {
        ZStack {
            // 全屏卡片预览
            MinimalCardView(
                session: session,
                visibleElements: config,
                showWatermark: !purchaseService.isPurchased
            )
            .ignoresSafeArea()

            // 顶部导航（透明覆盖）
            VStack {
                HStack {
                    // 返回按钮由 NavigationStack 提供
                    Spacer()
                    if purchaseService.isPurchased {
                        Button {
                            exportImage()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .padding(.trailing)
                    }
                }
                .padding(.top, 8)
                Spacer()
            }

            // 付费成功 Toast
            if showSuccessToast {
                VStack {
                    Spacer()
                    Text("高清图已存入相册 ✓")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: Capsule())
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
                .presentationDragIndicator(.visible)
        }
        .onChange(of: purchaseService.isPurchased) { _, isPurchased in
            if isPurchased {
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
        VStack(spacing: 0) {
            // 抓手
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 12)

            VStack(spacing: 16) {
                Text("导出无水印高清图")
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(.top, 8)

                Text("解锁全部模板 · 1:1 / 3:4 / 9:16 任意导出")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // 买断方案
                PlanRow(
                    isSelected: true,
                    flag: "最实惠 · 省 ¥40",
                    title: "一次性买断",
                    subtitle: "永久解锁 · 不限张数",
                    price: "¥68"
                )

                // 月订阅
                PlanRow(
                    isSelected: false,
                    flag: nil,
                    title: "月订阅",
                    subtitle: "随时取消",
                    price: "¥6/月"
                )

                // 购买按钮
                Button {
                    Task { await purchaseService.purchase(.unlock) }
                } label: {
                    Group {
                        if purchaseService.isPurchasing {
                            ProgressView().tint(.white)
                        } else {
                            Text("永久解锁 · ¥68")
                                .fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(purchaseService.isPurchasing)

                HStack(spacing: 20) {
                    Button("恢复购买") { Task { await purchaseService.restore() } }
                    Text("·")
                    Button("用户协议") {}
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - 导出图片
    private func exportImage() {
        Task { @MainActor in
            let img = ImageRenderService.renderCard(session: session, visibleElements: config)
            renderedImage = img
            ImageRenderService.saveToPhotoLibrary(img)

            withAnimation { showSuccessToast = true }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation { showSuccessToast = false }

            // 延迟一点再弹分享
            try? await Task.sleep(nanoseconds: 300_000_000)
            showShareSheet = true
        }
    }
}

// MARK: - 方案行
private struct PlanRow: View {
    let isSelected: Bool
    let flag: String?
    let title: String
    let subtitle: String
    let price: String

    var body: some View {
        HStack {
            Image(systemName: isSelected ? "record.circle.fill" : "circle")
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title).fontWeight(.medium)
                    if let flag {
                        Text(flag)
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(price).fontWeight(.semibold)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color(.systemGray5), lineWidth: isSelected ? 1.5 : 1)
        )
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
            isRecordPresented: .constant(true)
        )
        .environmentObject(PurchaseService())
    }
    .modelContainer(for: [FishingSession.self, FishCatch.self], inMemory: true)
}
