import SwiftUI

// MARK: - 出图第 1 步：选画幅 + 风格
struct ShareStyleView: View {
    let session: FishingSession
    @Binding var isRecordPresented: Bool

    @State private var selectedRatio: CardRatio = .threeByFour
    @State private var selectedStyle: CardStyle = .minimal
    @State private var navigateToElements = false

    enum CardRatio: String, CaseIterable, Identifiable {
        case threeByFour = "3:4"
        case oneByOne    = "1:1"
        case nineByteen  = "9:16"
        var id: String { rawValue }
        var subtitle: String {
            switch self {
            case .threeByFour: return "小红书"
            case .oneByOne:    return "朋友圈"
            case .nineByteen:  return "故事"
            }
        }
        var aspectRatio: CGFloat {
            switch self {
            case .threeByFour: return 3.0/4.0
            case .oneByOne:    return 1.0
            case .nineByteen:  return 9.0/16.0
            }
        }
        var isAvailable: Bool { true }
    }

    enum CardStyle: String, CaseIterable, Identifiable {
        case minimal = "极简数据卡"
        case tech    = "户外科技风"
        case sticker = "抠图贴纸墙"
        case film    = "胶片复古"
        var id: String { rawValue }
        var isFree: Bool { self == .minimal }
        var badge: String { isFree ? "FREE" : "PRO" }
    }

    var body: some View {
        ZStack {
            Theme.Colors.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.xl) {
                    // 实时预览卡
                    livePreviewSection

                    // 画幅选择
                    ratioSection

                    // 风格模板
                    styleSection
                }
                .padding(.horizontal, Theme.Space.lg)
                .padding(.vertical, Theme.Space.md)
                .padding(.bottom, 80)
            }
        }
        .navigationTitle("选尺寸 · 风格")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 6) {
                    Circle().fill(Theme.Colors.accent).frame(width: 6, height: 6)
                    Circle().fill(Theme.Colors.ink3).frame(width: 6, height: 6)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "下一步 · 选展示元素") {
                navigateToElements = true
            }
            .padding(.horizontal, Theme.Space.lg)
            .padding(.bottom, 8)
            .background(Theme.Colors.bg)
        }
        .navigationDestination(isPresented: $navigateToElements) {
            ShareElementsView(session: session, style: selectedStyle, ratio: selectedRatio, isRecordPresented: $isRecordPresented)
        }
    }

    // MARK: - 实时预览卡
    private var livePreviewSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            HStack {
                SectionLabel(text: "实时预览")
                Spacer()
                Text(selectedRatio.rawValue + " · " + selectedRatio.subtitle)
                    .font(Theme.Font.microLabel)
                    .foregroundStyle(Theme.Colors.accent)
            }

            HStack {
                Spacer()
                livePreviewCard
                    .frame(height: 220)
                    .animation(.easeInOut(duration: 0.28), value: selectedRatio)
                    .animation(.easeInOut(duration: 0.28), value: selectedStyle)
                Spacer()
            }
        }
    }

    private var livePreviewCard: some View {
        ShareCardPreview(
            session: session,
            config: ShareElementsConfig(),
            ratio: selectedRatio
        )
            .shadowCard()
    }

    // MARK: - 画幅选择
    private var ratioSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            SectionLabel(text: "画幅")

            HStack(spacing: Theme.Space.sm) {
                ForEach(CardRatio.allCases) { ratio in
                    Button {
                        if ratio.isAvailable {
                            withAnimation(.easeInOut(duration: 0.28)) {
                                selectedRatio = ratio
                            }
                        }
                    } label: {
                        VStack(spacing: 8) {
                            // 比例方块
                            let baseSize: CGFloat = 44
                            let w = ratio == .nineByteen ? baseSize * 9/16 : ratio == .threeByFour ? baseSize * 3/4 : baseSize
                            let h: CGFloat = ratio == .nineByteen ? baseSize : ratio == .threeByFour ? baseSize : baseSize * 3/4

                            RoundedRectangle(cornerRadius: 3)
                                .fill(selectedRatio == ratio ? Theme.Colors.accentSoft : Theme.Colors.bg2)
                                .frame(width: w, height: h)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(selectedRatio == ratio ? Theme.Colors.accent : Theme.Colors.hairline, lineWidth: 1.5)
                                )

                            Text(ratio.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(selectedRatio == ratio ? Theme.Colors.accent : Theme.Colors.ink)
                            Text(ratio.subtitle)
                                .font(Theme.Font.caption)
                                .foregroundStyle(Theme.Colors.ink2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedRatio == ratio ? Theme.Colors.accentSoft : Theme.Colors.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedRatio == ratio ? Theme.Colors.accent : Theme.Colors.hairline, lineWidth: 1.5)
                                )
                        )
                        .opacity(ratio.isAvailable ? 1 : 0.45)
                    }
                    .disabled(!ratio.isAvailable)
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 风格模板
    private var styleSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            SectionLabel(text: "风格模板")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Space.md) {
                ForEach(CardStyle.allCases) { style in
                    Button {
                        if style.isFree {
                            withAnimation(.easeInOut(duration: 0.28)) { selectedStyle = style }
                        }
                    } label: {
                        VStack(spacing: 0) {
                            // 缩略图
                            ZStack(alignment: .topTrailing) {
                                styleThumbnail(for: style)
                                    .aspectRatio(selectedRatio.aspectRatio, contentMode: .fit)
                                    .frame(maxWidth: .infinity)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedStyle == style ? Theme.Colors.accent : Color.clear, lineWidth: 2)
                                    )

                                // FREE / PRO 标签
                                Text(style.badge)
                                    .font(Theme.Font.microLabel)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(style.isFree ? Theme.Colors.accent : Theme.Colors.ink3)
                                    .clipShape(Capsule())
                                    .padding(7)

                                // PRO 锁图标
                                if !style.isFree {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.white.opacity(0.8))
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .background(.black.opacity(0.35))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }

                            Text(style.rawValue)
                                .font(Theme.Font.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(Theme.Colors.ink)
                                .padding(.top, Theme.Space.sm)
                                .padding(.bottom, Theme.Space.xs)
                        }
                        .opacity(style.isFree ? 1 : 0.6)
                    }
                    .disabled(!style.isFree)
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func styleThumbnail(for style: CardStyle) -> some View {
        switch style {
        case .minimal:
            ShareCardPreview(
                session: session,
                config: ShareElementsConfig(),
                ratio: selectedRatio
            )
        case .tech:
            ZStack(alignment: .bottomLeading) {
                LinearGradient(colors: [Color(hex: "0A0F1C"), Color(hex: "1A3050")],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .center, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 2) {
                    Text("FISHING DATA").font(Theme.Font.microLabel).foregroundStyle(Color(hex: "00E5FF").opacity(0.8))
                }
                .padding(10)
            }
            .aspectRatio(selectedRatio.aspectRatio, contentMode: .fit)
        case .sticker:
            ZStack(alignment: .bottomLeading) {
                Color(hex: "EDE5CE")
                VStack(alignment: .leading, spacing: 2) {
                    Text("今日战果").font(.system(size: 12)).foregroundStyle(Color(hex: "3C3422"))
                    Image(systemName: "fish.fill").font(.system(size: 30)).foregroundStyle(Theme.Colors.accent.opacity(0.7)).offset(x: -8, y: 4)
                }
                .padding(10)
            }
            .aspectRatio(selectedRatio.aspectRatio, contentMode: .fit)
        case .film:
            ZStack {
                Color(hex: "D4C9A8")
                RoundedRectangle(cornerRadius: 2).stroke(.white, lineWidth: 5).padding(6)
            }
            .aspectRatio(selectedRatio.aspectRatio, contentMode: .fit)
        }
    }
}

#Preview {
    NavigationStack {
        ShareStyleView(session: FishingSession(date: .now, locationName: "千岛湖"),
                       isRecordPresented: .constant(true))
    }
    .modelContainer(for: [FishingSession.self, FishCatch.self], inMemory: true)
}

/// 分享卡预览图：统一走导出渲染链路，避免小尺寸 SwiftUI 预览和最终图片不一致。
struct ShareCardPreview: View {
    let session: FishingSession
    let config: ShareElementsConfig
    let ratio: ShareStyleView.CardRatio
    var showWatermark: Bool = false
    var cornerRadius: CGFloat = 10

    @State private var previewImage: UIImage?

    private var renderKey: RenderKey {
        RenderKey(
            sessionID: session.id,
            config: config,
            ratio: ratio.rawValue,
            showWatermark: showWatermark
        )
    }

    var body: some View {
        ZStack {
            Theme.Colors.bg2

            if let previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView()
                    .tint(Theme.Colors.accent)
            }
        }
        .aspectRatio(ratio.aspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .task(id: renderKey) {
            previewImage = ImageRenderService.renderCard(
                session: session,
                visibleElements: config,
                showWatermark: showWatermark,
                ratio: ImageRenderService.CardRatio(ratio)
            )
        }
    }

    private struct RenderKey: Hashable {
        let sessionID: UUID
        let config: ShareElementsConfig
        let ratio: String
        let showWatermark: Bool
    }
}
