import SwiftUI
import PhotosUI
import AVFoundation
import UIKit

/// 拍照界面：实时取景 + 快门连拍多张（最多 9 张），也可从相册导入
struct CameraView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var recordSession: RecordSession

    @StateObject private var camera = CameraManager()
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var navigateToCutout = false
    @State private var shutterFlash = false

    private let maxCount = 9
    private var images: [UIImage] { camera.images }
    private var canAddMore: Bool { images.count < maxCount }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // 取景区 / 降级态
            Group {
                switch camera.status {
                case .ready:
                    CameraPreviewLayerView(session: camera.session)
                        .ignoresSafeArea()
                        .overlay(focusReticle)
                case .configuring:
                    configuringView
                case .denied:
                    deniedView
                case .unavailable:
                    unavailableView
                }
            }

            // 快门白闪
            if shutterFlash {
                Color.white.ignoresSafeArea().transition(.opacity)
            }

            // 顶部栏 + 底部控制条
            VStack(spacing: 0) {
                topBar
                Spacer()
                bottomBar
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .statusBarHidden(false)
        .onAppear { camera.configure() }
        .onDisappear { camera.stop() }
        .onChange(of: photoItems) { _, items in
            loadFromLibrary(items)
        }
        .navigationDestination(isPresented: $navigateToCutout) {
            CutoutView(isRecordPresented: $isPresented)
        }
    }

    // MARK: - 顶部栏
    private var topBar: some View {
        ZStack {
            Text("拍照")
                .font(Theme.Font.headline)
                .foregroundStyle(.white)

            HStack {
                Button("‹ 取消") { isPresented = false }
                    .font(Theme.Font.body)
                    .foregroundStyle(.white)
                Spacer()
                Label("REC · 自动抓环境数据", systemImage: "circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial, in: Capsule())
                    .environment(\.colorScheme, .dark)
            }
        }
        .padding(.horizontal, Theme.Space.lg)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(
            LinearGradient(colors: [.black.opacity(0.55), .clear],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .top)
        )
    }

    // MARK: - 取景中心对焦标
    private var focusReticle: some View {
        Image(systemName: "plus")
            .font(.system(size: 28, weight: .thin))
            .foregroundStyle(.white.opacity(0.5))
    }

    // MARK: - 底部控制条
    private var bottomBar: some View {
        VStack(spacing: Theme.Space.md) {
            // 已拍/已选缩略图条
            if !images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(images.indices, id: \.self) { i in
                            thumbnail(index: i)
                        }
                    }
                    .padding(.horizontal, Theme.Space.lg)
                }
            }

            // 操作行：相册 · 快门 · 下一步
            HStack {
                // 相册导入
                PhotosPicker(
                    selection: $photoItems,
                    maxSelectionCount: maxCount,
                    matching: .images
                ) {
                    VStack(spacing: 3) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 22))
                        Text("相册").font(.caption2)
                    }
                    .foregroundStyle(.white)
                    .frame(width: 64)
                }

                Spacer()

                // 快门
                shutterButton

                Spacer()

                // 下一步
                Button {
                    goNext()
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 24))
                        Text("下一步").font(.caption2)
                    }
                    .foregroundStyle(images.isEmpty ? .white.opacity(0.3) : Theme.Colors.accent)
                    .frame(width: 64)
                }
                .disabled(images.isEmpty)
            }
            .padding(.horizontal, Theme.Space.xl)

            // 计数提示
            Text(images.isEmpty ? "点圆点拍照，可拍多张（最多 \(maxCount) 张）" : "已拍 \(images.count)/\(maxCount) 张 · 一张图＝一尾鱼")
                .font(Theme.Font.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.top, Theme.Space.md)
        .padding(.bottom, 28)
        .background(
            LinearGradient(colors: [.clear, .black.opacity(0.6)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - 快门按钮（白色双圈）
    private var shutterButton: some View {
        Button {
            capture()
        } label: {
            ZStack {
                Circle()
                    .stroke(.white, lineWidth: 4)
                    .frame(width: 72, height: 72)
                Circle()
                    .fill(canAddMore ? Color.white : Color.white.opacity(0.4))
                    .frame(width: 58, height: 58)
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!canAddMore || camera.status != .ready)
        .opacity(camera.status == .ready ? 1 : 0.4)
    }

    // MARK: - 缩略图（可删除）
    private func thumbnail(index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: images[index])
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white.opacity(0.6), lineWidth: 1)
                )

            Button {
                camera.removeImage(at: index)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white, .black.opacity(0.5))
            }
            .offset(x: 5, y: -5)
        }
        .padding(.top, 5)
    }

    // MARK: - 降级态视图
    private var configuringView: some View {
        VStack(spacing: Theme.Space.md) {
            ProgressView().tint(.white)
            Text("正在启动相机…")
                .font(Theme.Font.body)
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    private var deniedView: some View {
        VStack(spacing: Theme.Space.lg) {
            Image(systemName: "camera.fill")
                .font(.system(size: 56))
                .foregroundStyle(.white.opacity(0.5))
            Text("未获得相机权限")
                .font(Theme.Font.headline)
                .foregroundStyle(.white)
            Text("可在系统设置里开启相机，或直接从相册选图")
                .font(Theme.Font.subhead)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            Button("前往设置开启") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(Theme.Font.body)
            .foregroundStyle(Theme.Colors.accent)
        }
        .padding(.horizontal, Theme.Space.xxl)
    }

    private var unavailableView: some View {
        VStack(spacing: Theme.Space.lg) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 56))
                .foregroundStyle(.white.opacity(0.5))
            Text("当前设备无可用相机")
                .font(Theme.Font.headline)
                .foregroundStyle(.white)
            Text("请从相册选择渔获照片")
                .font(Theme.Font.subhead)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, Theme.Space.xxl)
    }

    // MARK: - 动作
    private func capture() {
        guard canAddMore else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.easeOut(duration: 0.08)) { shutterFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeIn(duration: 0.12)) { shutterFlash = false }
        }
        camera.capturePhoto(limit: maxCount)
    }

    private func loadFromLibrary(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        let group = DispatchGroup()
        var loaded: [Int: UIImage] = [:]
        for (i, item) in items.enumerated() {
            group.enter()
            item.loadTransferable(type: Data.self) { result in
                if case .success(let data) = result, let d = data, let img = UIImage(data: d) {
                    loaded[i] = img
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            let ordered = items.indices.compactMap { loaded[$0] }
            camera.addFromLibrary(ordered, limit: maxCount)
            photoItems = []
        }
    }

    private func goNext() {
        guard !images.isEmpty else { return }
        recordSession.rawImages = images
        recordSession.cutoutImages = Array(repeating: nil, count: images.count)
        recordSession.currentCutoutIndex = 0
        navigateToCutout = true
    }
}

// MARK: - 相机管理器（AVFoundation 会话 + 拍照输出）
/// 不绑定 @MainActor：会话相关操作走专用串行队列，@Published 更新统一切回主线程
final class CameraManager: NSObject, ObservableObject {
    enum Status: Equatable { case configuring, ready, denied, unavailable }

    @Published var status: Status = .configuring
    /// 已拍摄 / 已导入的照片（顺序即渔获顺序）
    @Published var images: [UIImage] = []

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "com.fishingdiary.camera.session")
    private var isConfigured = false

    private func setStatus(_ newValue: Status) {
        DispatchQueue.main.async { self.status = newValue }
    }

    // MARK: 权限 + 配置
    func configure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.setupSession()
                } else {
                    self?.setStatus(.denied)
                }
            }
        default:
            setStatus(.denied)
        }
    }

    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.isConfigured {
                if !self.session.isRunning { self.session.startRunning() }
                return
            }

            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                let input = try? AVCaptureDeviceInput(device: device),
                self.session.canAddInput(input),
                self.session.canAddOutput(self.photoOutput)
            else {
                self.session.commitConfiguration()
                self.setStatus(.unavailable)
                return
            }

            self.session.addInput(input)
            self.session.addOutput(self.photoOutput)
            self.session.commitConfiguration()
            self.isConfigured = true
            self.session.startRunning()
            self.setStatus(.ready)
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    // MARK: 拍照
    func capturePhoto(limit: Int) {
        guard status == .ready, images.count < limit else { return }
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if let connection = self.photoOutput.connection(with: .video),
               connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            self.photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        }
    }

    // MARK: 相册导入 / 删除（主线程调用）
    func addFromLibrary(_ newImages: [UIImage], limit: Int) {
        let room = max(0, limit - images.count)
        guard room > 0 else { return }
        images.append(contentsOf: newImages.prefix(room))
    }

    func removeImage(at index: Int) {
        guard images.indices.contains(index) else { return }
        images.remove(at: index)
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        DispatchQueue.main.async { self.images.append(image) }
    }
}

// MARK: - 实时取景预览层
struct CameraPreviewLayerView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.backgroundColor = .black
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        if view.videoPreviewLayer.connection?.isVideoOrientationSupported == true {
            view.videoPreviewLayer.connection?.videoOrientation = .portrait
        }
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

#Preview {
    NavigationStack {
        CameraView(isPresented: .constant(true))
            .environmentObject(RecordSession())
    }
}
