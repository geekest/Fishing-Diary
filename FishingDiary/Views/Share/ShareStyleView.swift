import SwiftUI

/// 分享第 1 步：选画幅 + 风格模板
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
        var isAvailable: Bool { self == .threeByFour }
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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 画幅选择
                ratioSection

                // 风格模板
                styleSection
            }
            .padding()
        }
        .navigationTitle("选尺寸 · 风格")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Text("1/2").font(.caption).foregroundStyle(.secondary)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                navigateToElements = true
            } label: {
                Text("下一步 · 选展示元素")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .navigationDestination(isPresented: $navigateToElements) {
            ShareElementsView(session: session, style: selectedStyle, isRecordPresented: $isRecordPresented)
        }
    }

    // MARK: - 画幅选择
    private var ratioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("画幅").font(.headline)

            HStack(spacing: 12) {
                ForEach(CardRatio.allCases) { ratio in
                    Button {
                        if ratio.isAvailable { selectedRatio = ratio }
                    } label: {
                        VStack(spacing: 6) {
                            // 比例方块
                            let w: CGFloat = ratio == .nineByteen ? 22 : ratio == .threeByFour ? 26 : 30
                            let h: CGFloat = ratio == .nineByteen ? 40 : ratio == .threeByFour ? 34 : 30
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(selectedRatio == ratio ? Color.accentColor : Color(.systemGray4), lineWidth: 1.5)
                                .frame(width: w, height: h)
                            Text(ratio.rawValue).font(.caption2).fontWeight(.semibold)
                            Text(ratio.subtitle).font(.caption2).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedRatio == ratio ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedRatio == ratio ? Color.accentColor : .clear, lineWidth: 1)
                        )
                        .opacity(ratio.isAvailable ? 1 : 0.4)
                    }
                    .disabled(!ratio.isAvailable)
                }
            }
        }
    }

    // MARK: - 风格模板
    private var styleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("风格模板").font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(CardStyle.allCases) { style in
                    Button {
                        if style.isFree { selectedStyle = style }
                    } label: {
                        VStack(spacing: 0) {
                            // 预览缩略图
                            styleThumbnail(for: style)
                                .frame(height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(alignment: .topTrailing) {
                                    Text(style.badge)
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(style.isFree ? Color.accentColor : Color(.systemGray3))
                                        .foregroundStyle(style.isFree ? .white : .primary)
                                        .clipShape(Capsule())
                                        .padding(6)
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedStyle == style ? Color.accentColor : .clear, lineWidth: 2)
                                )

                            Text(style.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.top, 8)
                        }
                        .opacity(style.isFree ? 1 : 0.6)
                    }
                    .disabled(!style.isFree)
                }
            }
        }
    }

    // MARK: - 风格预览缩略图
    @ViewBuilder
    private func styleThumbnail(for style: CardStyle) -> some View {
        switch style {
        case .minimal:
            ZStack(alignment: .bottomLeading) {
                Color(red: 0.05, green: 0.18, blue: 0.1)
                LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 2) {
                    Text("LOG").font(.system(size: 8, design: .monospaced)).foregroundStyle(.white.opacity(0.5))
                    Text("38cm").font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                    Divider().overlay(.white.opacity(0.3))
                }
                .padding(10)
            }
        case .tech:
            ZStack {
                LinearGradient(colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.1, green: 0.2, blue: 0.3)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                Grid(horizontalSpacing: 1, verticalSpacing: 1) {
                    ForEach(0..<4, id: \.self) { _ in
                        GridRow {
                            ForEach(0..<6, id: \.self) { _ in
                                Rectangle().fill(.cyan.opacity(0.08))
                            }
                        }
                    }
                }
                Text("FISHING\nDATA").font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.cyan.opacity(0.8)).multilineTextAlignment(.center)
            }
        case .sticker:
            ZStack {
                Color(red: 0.92, green: 0.88, blue: 0.82)
                Image(systemName: "fish.fill")
                    .font(.system(size: 30)).foregroundStyle(.green.opacity(0.6))
                    .offset(x: -20, y: 10)
                Image(systemName: "fish.fill")
                    .font(.system(size: 20)).foregroundStyle(.blue.opacity(0.5))
                    .offset(x: 25, y: -15)
            }
        case .film:
            ZStack {
                Color(red: 0.82, green: 0.76, blue: 0.64)
                RoundedRectangle(cornerRadius: 2)
                    .stroke(.white, lineWidth: 6)
                    .padding(10)
            }
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
