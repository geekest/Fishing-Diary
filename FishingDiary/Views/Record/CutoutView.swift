import SwiftUI
import UIKit
import Vision
import CoreImage
import TOCropViewController

// MARK: - 抠图模式
enum CutoutMode: Int, CaseIterable {
    case auto, manual, keep

    var title: String {
        switch self {
        case .auto:   return "自动抠图"
        case .manual: return "手动微调"
        case .keep:   return "留背景"
        }
    }
}

/// 批量抠图界面：进图自动用 Vision 抠出主体（鱼），可手动微调或保留背景
struct CutoutView: View {
    @Binding var isRecordPresented: Bool
    @EnvironmentObject var recordSession: RecordSession

    @State private var modes: [CutoutMode] = []
    @State private var liftCache: [Int: UIImage] = [:]      // 透明抠图缓存
    @State private var stickerCache: [Int: UIImage] = [:]   // 白描边贴纸缓存（仅预览用）
    @State private var processingIndex: Int? = nil
    @State private var autoFailed = false
    @State private var showCropper = false
    @State private var navigateToFillFish = false

    private var total: Int { recordSession.rawImages.count }
    private var currentIndex: Int { recordSession.currentCutoutIndex }
    private var currentMode: CutoutMode { modes[safe: currentIndex] ?? .auto }
    private var currentRaw: UIImage? { recordSession.rawImages[safe: currentIndex] }
    private var isProcessing: Bool { processingIndex == currentIndex }
    private var isLast: Bool { currentIndex + 1 >= total }

    private var displayImage: UIImage? {
        switch currentMode {
        case .auto:
            return stickerCache[currentIndex] ?? liftCache[currentIndex] ?? currentRaw
        case .keep:
            return currentRaw
        case .manual:
            return (recordSession.cutoutImages[safe: currentIndex].flatMap { $0 }) ?? currentRaw
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            queueRow

            Divider().padding(.vertical, 8)

            Text("一张图＝一尾鱼，已自动抠出主体 ↓")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            previewArea

            // 模式分段控件（真实生效）
            Picker("", selection: modeBinding) {
                ForEach(CutoutMode.allCases, id: \.self) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 12)

            // 失败提示
            if autoFailed {
                Text(autoFailHint)
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 6)
            }

            Spacer()

            bottomBar
        }
        .navigationTitle("抠图剪切")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Text("\(currentIndex + 1)/\(total)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .task(id: currentIndex) {
            ensureModesSized()
            if currentMode == .auto, liftCache[currentIndex] == nil {
                await performAutoCutout(for: currentIndex)
            }
        }
        .fullScreenCover(isPresented: $showCropper) {
            if let img = currentRaw {
                CropViewControllerWrapper(image: img) { cropped in
                    showCropper = false
                    storeManual(cropped)
                } onCancel: {
                    showCropper = false
                }
                .ignoresSafeArea()
            }
        }
        .navigationDestination(isPresented: $navigateToFillFish) {
            FishFormView(isRecordPresented: $isRecordPresented)
        }
    }

    // MARK: - 预览区
    private var previewArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.Colors.bg2)

            if isProcessing {
                if let raw = currentRaw {
                    Image(uiImage: raw)
                        .resizable()
                        .scaledToFit()
                        .opacity(0.2)
                        .padding(8)
                }
                VStack(spacing: 10) {
                    ProgressView().tint(Theme.Colors.accent)
                    Text("AI 正在识别并抠出主体…")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Colors.ink2)
                }
            } else if let img = displayImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            }
        }
        .frame(maxHeight: 340)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - 进度队列行
    private var queueRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0..<total, id: \.self) { i in
                    ZStack(alignment: .topTrailing) {
                        if let img = recordSession.rawImages[safe: i] {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 52, height: 52)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .opacity(i < currentIndex ? 0.5 : 1.0)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(i == currentIndex ? Color.accentColor : .clear, lineWidth: 2)
                                )
                        }
                        if i < currentIndex {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.white, Color.accentColor)
                                .font(.caption)
                                .offset(x: 4, y: -4)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    // MARK: - 底部按钮
    private var bottomBar: some View {
        HStack(spacing: 12) {
            if currentIndex > 0 {
                Button {
                    recordSession.currentCutoutIndex -= 1
                } label: {
                    Text("‹ 上一张")
                        .fontWeight(.medium)
                        .frame(width: 96)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            Button {
                advance()
            } label: {
                Text(isLast ? "完成 · 填写信息 ›" : "下一张 ›")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 24)
    }

    private var autoFailHint: String {
        SubjectCutoutService.isAvailable
            ? "没识别到明显主体，已暂时保留原图，可改用「手动微调」"
            : "当前系统不支持自动抠图（需 iOS 17），已保留原图"
    }

    // MARK: - 模式绑定
    private var modeBinding: Binding<CutoutMode> {
        Binding(
            get: { currentMode },
            set: { applyMode($0) }
        )
    }

    private func applyMode(_ mode: CutoutMode) {
        ensureModesSized()
        modes[currentIndex] = mode
        autoFailed = false
        switch mode {
        case .keep:
            setCutout(nil, at: currentIndex)
        case .manual:
            showCropper = true
        case .auto:
            if let cached = liftCache[currentIndex] {
                setCutout(cached, at: currentIndex)
            } else {
                Task { await performAutoCutout(for: currentIndex) }
            }
        }
    }

    // MARK: - 自动抠图
    @MainActor
    private func performAutoCutout(for index: Int) async {
        guard let raw = recordSession.rawImages[safe: index] else { return }
        autoFailed = false
        processingIndex = index

        let normalized = raw.normalizedUp()
        let cutout = await SubjectCutoutService.liftSubject(from: normalized)
        let sticker = await SubjectCutoutService.makeSticker(from: cutout)

        if let cutout {
            liftCache[index] = cutout
            stickerCache[index] = sticker
            setCutout(cutout, at: index)
        } else {
            // 失败：iOS<17 或没识别到主体 → 退回保留原图
            setCutout(nil, at: index)
            if modes.indices.contains(index) { modes[index] = .keep }
            autoFailed = true
        }

        if processingIndex == index { processingIndex = nil }
    }

    // MARK: - 手动裁剪结果
    private func storeManual(_ cropped: UIImage) {
        ensureModesSized()
        modes[currentIndex] = .manual
        setCutout(cropped, at: currentIndex)
    }

    // MARK: - 推进
    private func advance() {
        if isLast {
            prepareFishForms()
            navigateToFillFish = true
        } else {
            recordSession.currentCutoutIndex += 1
        }
    }

    private func prepareFishForms() {
        if recordSession.fishForms.count != total {
            recordSession.fishForms = (0..<total).map { _ in FishForm() }
        }
        recordSession.currentFishIndex = 0
    }

    // MARK: - 工具
    private func ensureModesSized() {
        if modes.count != total {
            modes = Array(repeating: .auto, count: total)
        }
    }

    private func setCutout(_ image: UIImage?, at index: Int) {
        guard recordSession.cutoutImages.indices.contains(index) else { return }
        recordSession.cutoutImages[index] = image
    }
}

// MARK: - 主体抠图服务（Vision 前景主体蒙版，iOS 17+）
enum SubjectCutoutService {
    /// 是否支持自动抠图
    static var isAvailable: Bool {
        if #available(iOS 17.0, *) { return true }
        return false
    }

    /// 把主体（鱼）从背景抠出，返回透明背景图；不支持或失败返回 nil
    static func liftSubject(from image: UIImage) async -> UIImage? {
        guard #available(iOS 17.0, *) else { return nil }
        return await liftSubjectiOS17(from: image)
    }

    @available(iOS 17.0, *)
    private static func liftSubjectiOS17(from image: UIImage) async -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        return await withCheckedContinuation { (cont: CheckedContinuation<UIImage?, Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNGenerateForegroundInstanceMaskRequest()
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([request])
                    guard let result = request.results?.first,
                          !result.allInstances.isEmpty else {
                        cont.resume(returning: nil)
                        return
                    }
                    let buffer = try result.generateMaskedImage(
                        ofInstances: result.allInstances,
                        from: handler,
                        croppedToInstancesExtent: true
                    )
                    let ciImage = CIImage(cvPixelBuffer: buffer)
                    let context = CIContext()
                    guard let cg = context.createCGImage(ciImage, from: ciImage.extent) else {
                        cont.resume(returning: nil)
                        return
                    }
                    cont.resume(returning: UIImage(cgImage: cg))
                } catch {
                    cont.resume(returning: nil)
                }
            }
        }
    }

    /// 后台生成白描边贴纸（仅用于展示，不改动存储的透明抠图）
    static func makeSticker(from cutout: UIImage?) async -> UIImage? {
        guard let cutout else { return nil }
        return await withCheckedContinuation { (cont: CheckedContinuation<UIImage?, Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                cont.resume(returning: sticker(from: cutout))
            }
        }
    }

    /// 给透明抠图加白色描边：多方向偏移叠白色剪影，再叠原抠图
    static func sticker(from cutout: UIImage, outline: CGFloat = 12) -> UIImage {
        let size = cutout.size
        guard size.width > 0, size.height > 0 else { return cutout }

        // 白色剪影（保留 alpha 边缘）
        let silhouette = UIGraphicsImageRenderer(size: size).image { ctx in
            cutout.draw(at: .zero)
            ctx.cgContext.setBlendMode(.sourceAtop)
            UIColor.white.setFill()
            ctx.cgContext.fill(CGRect(origin: .zero, size: size))
        }

        let pad = outline
        let newSize = CGSize(width: size.width + pad * 2, height: size.height + pad * 2)
        let center = CGRect(x: pad, y: pad, width: size.width, height: size.height)

        return UIGraphicsImageRenderer(size: newSize).image { _ in
            let steps = 24
            for i in 0..<steps {
                let angle = CGFloat(i) / CGFloat(steps) * 2 * .pi
                silhouette.draw(in: center.offsetBy(dx: cos(angle) * pad, dy: sin(angle) * pad))
            }
            cutout.draw(in: center)
        }
    }

    // MARK: - 分享卡用：白描边贴纸 + 模糊背景（带缓存，避免 ImageRenderer 反复重算）
    private static var stickerStore: [String: UIImage] = [:]
    private static var blurStore: [String: UIImage] = [:]

    /// 取一尾鱼的白描边贴纸（透明抠图 → 加白描边），按渔获 id 缓存
    static func cardSticker(id: UUID, cutoutData: Data) -> UIImage? {
        let key = id.uuidString
        if let hit = stickerStore[key] { return hit }
        guard !cutoutData.isEmpty, let cutout = UIImage(data: cutoutData) else { return nil }
        let scaled = cutout.resized(maxDimension: 1200)
        let pad = max(scaled.size.width, scaled.size.height) * 0.02
        let result = sticker(from: scaled, outline: pad)
        stickerStore[key] = result
        return result
    }

    /// 取一尾鱼的模糊背景（原图高斯模糊），按渔获 id 缓存
    static func cardBackground(id: UUID, originalData: Data) -> UIImage? {
        let key = id.uuidString
        if let hit = blurStore[key] { return hit }
        guard !originalData.isEmpty, let original = UIImage(data: originalData) else { return nil }
        let scaled = original.resized(maxDimension: 1200)
        let result = blurred(scaled, sigma: 18) ?? scaled
        blurStore[key] = result
        return result
    }

    /// 渔获图片被编辑后，清掉对应缓存，让分享卡重新生成
    static func clearCardCache(id: UUID) {
        let key = id.uuidString
        stickerStore[key] = nil
        blurStore[key] = nil
    }

    private static func blurred(_ image: UIImage, sigma: CGFloat) -> UIImage? {
        guard let cg = image.cgImage else { return nil }
        let ci = CIImage(cgImage: cg)
        let output = ci.clampedToExtent()
            .applyingGaussianBlur(sigma: Double(sigma))
            .cropped(to: ci.extent)
        let context = CIContext()
        guard let cgOut = context.createCGImage(output, from: ci.extent) else { return nil }
        return UIImage(cgImage: cgOut)
    }
}

// MARK: - TOCropViewController 包装
/// 用一个宿主控制器以「全屏模态」方式呈现 TOCropViewController，
/// 确保其底部工具栏（取消 / 完成 / 旋转 / 比例）正常显示在安全区之上。
struct CropViewControllerWrapper: UIViewControllerRepresentable {
    let image: UIImage
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIViewController {
        let host = UIViewController()
        host.view.backgroundColor = .black
        return host
    }

    func updateUIViewController(_ host: UIViewController, context: Context) {
        guard !context.coordinator.didPresent else { return }
        context.coordinator.didPresent = true

        let cropVC = TOCropViewController(croppingStyle: .default, image: image)
        cropVC.delegate = context.coordinator
        cropVC.resetAspectRatioEnabled = true
        cropVC.aspectRatioLockEnabled = false
        cropVC.rotateButtonsHidden = false
        cropVC.rotateClockwiseButtonHidden = false
        cropVC.aspectRatioPickerButtonHidden = false
        cropVC.doneButtonTitle = "完成"
        cropVC.cancelButtonTitle = "取消"
        cropVC.modalPresentationStyle = .fullScreen
        cropVC.modalTransitionStyle = .crossDissolve

        DispatchQueue.main.async {
            host.present(cropVC, animated: true)
        }
    }

    class Coordinator: NSObject, TOCropViewControllerDelegate {
        let parent: CropViewControllerWrapper
        var didPresent = false
        init(_ parent: CropViewControllerWrapper) { self.parent = parent }

        func cropViewController(_ cropViewController: TOCropViewController,
                                didCropTo image: UIImage,
                                with cropRect: CGRect,
                                angle: Int) {
            cropViewController.dismiss(animated: true) {
                self.parent.onCrop(image)
            }
        }

        func cropViewController(_ cropViewController: TOCropViewController,
                                didFinishCancelled cancelled: Bool) {
            cropViewController.dismiss(animated: true) {
                self.parent.onCancel()
            }
        }
    }
}

// MARK: - 安全下标
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - 图片方向归一化
extension UIImage {
    /// 把带 EXIF 方向的图重绘成 .up，避免 Vision 处理后坐标错位
    func normalizedUp() -> UIImage {
        guard imageOrientation != .up else { return self }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    /// 等比缩放到最长边不超过 maxDimension（用于控制贴纸/背景的生成开销）
    func resized(maxDimension: CGFloat) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension, maxSide > 0 else { return self }
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

#Preview {
    NavigationStack {
        CutoutView(isRecordPresented: .constant(true))
            .environmentObject(RecordSession())
    }
}
