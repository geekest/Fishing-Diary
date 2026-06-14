import SwiftUI
import UIKit
import TOCropViewController

/// 批量抠图界面：逐张用 TOCropViewController 裁剪
struct CutoutView: View {
    @Binding var isRecordPresented: Bool
    @EnvironmentObject var recordSession: RecordSession

    @State private var showCropper = false
    @State private var navigateToFillFish = false

    private var total: Int { recordSession.rawImages.count }
    private var currentIndex: Int { recordSession.currentCutoutIndex }
    private var currentImage: UIImage? {
        guard currentIndex < total else { return nil }
        return recordSession.rawImages[currentIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            // 进度队列
            queueRow

            Divider().padding(.vertical, 8)

            // 提示文字
            Text("一张图＝一尾鱼，逐张抠 ↓")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            // 当前图预览
            if let img = currentImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .onTapGesture { showCropper = true }
                    .overlay(alignment: .topLeading) {
                        Text("第 \(currentIndex + 1) 张 · 点击裁剪")
                            .font(.caption2)
                            .padding(6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .padding(16)
                    }
            }

            // 抠图模式选择器（UI 展示，TOCropViewController 统一处理）
            Picker("", selection: .constant(0)) {
                Text("自动抠图").tag(0)
                Text("手动微调").tag(1)
                Text("留背景").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 12)

            Spacer()

            // 底部按钮
            HStack(spacing: 12) {
                Button("跳过") { advance(withCutout: nil) }
                    .frame(width: 80)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    showCropper = true
                } label: {
                    Text("开始裁剪 · 下一张 ›")
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
        .navigationTitle("抠图剪切")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Text("\(currentIndex + 1)/\(total)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .fullScreenCover(isPresented: $showCropper) {
            if let img = currentImage {
                CropViewControllerWrapper(image: img) { cropped in
                    showCropper = false
                    advance(withCutout: cropped)
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
                        // 完成标记
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

    // MARK: - 推进到下一张
    private func advance(withCutout result: UIImage?) {
        // 存入抠图结果
        if recordSession.cutoutImages.count > currentIndex {
            recordSession.cutoutImages[currentIndex] = result
        } else {
            recordSession.cutoutImages.append(result)
        }

        let next = currentIndex + 1
        if next >= total {
            // 所有图处理完毕，初始化鱼表单并跳转
            prepareFishForms()
            navigateToFillFish = true
        } else {
            recordSession.currentCutoutIndex = next
        }
    }

    private func prepareFishForms() {
        // 每张图默认一尾鱼
        recordSession.fishForms = (0..<total).map { _ in FishForm() }
        recordSession.currentFishIndex = 0
    }
}

// MARK: - TOCropViewController 包装
/// 用一个宿主控制器以「全屏模态」方式呈现 TOCropViewController，
/// 确保其底部工具栏（取消 / 完成 / 旋转 / 比例）正常显示在安全区之上，
/// 避免内嵌进 SwiftUI sheet 时工具栏被挤到屏幕最底端而无法点击。
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
        cropVC.rotateButtonsHidden = false          // 逆时针旋转
        cropVC.rotateClockwiseButtonHidden = false  // 顺时针旋转
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

#Preview {
    NavigationStack {
        CutoutView(isRecordPresented: .constant(true))
            .environmentObject(RecordSession())
    }
}
