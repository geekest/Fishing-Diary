import SwiftUI
import PhotosUI
import UIKit

/// 拍照/选图界面：支持多选最多 9 张
struct CameraView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var recordSession: RecordSession

    @State private var photoItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var showPicker = true
    @State private var navigateToCutout = false

    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            HStack {
                Button("取消") { isPresented = false }
                    .foregroundStyle(.primary)
                Spacer()
                Label("REC · 自动抓环境数据", systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                Spacer()
                // 占位对齐
                Text("取消").opacity(0)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            Divider()

            if selectedImages.isEmpty {
                // 空态：引导选图
                emptyState
            } else {
                // 已选图预览
                previewGrid
            }

            Spacer()

            // 底部操作区
            VStack(spacing: 12) {
                // 缩略图行
                if !selectedImages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(selectedImages.indices, id: \.self) { i in
                                Image(uiImage: selectedImages[i])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 56, height: 56)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                HStack(spacing: 12) {
                    // 选图按钮
                    PhotosPicker(
                        selection: $photoItems,
                        maxSelectionCount: 9,
                        matching: .images
                    ) {
                        Label(selectedImages.isEmpty ? "从相册选图" : "重新选择",
                              systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .onChange(of: photoItems) { _, items in
                        loadImages(from: items)
                    }

                    // 下一步按钮
                    if !selectedImages.isEmpty {
                        Button {
                            recordSession.rawImages = selectedImages
                            recordSession.cutoutImages = Array(repeating: nil, count: selectedImages.count)
                            recordSession.currentCutoutIndex = 0
                            navigateToCutout = true
                        } label: {
                            Text("下一步 · 去抠图 ›")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 24)
        }
        .navigationTitle("拍照")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("‹ 取消") { isPresented = false }
            }
        }
        .navigationDestination(isPresented: $navigateToCutout) {
            CutoutView(isRecordPresented: $isPresented)
        }
    }

    // MARK: - 空态
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 80))
                .foregroundStyle(.tertiary)
            Text("选择渔获照片\n（最多 9 张）")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 已选图预览（九宫格）
    private var previewGrid: some View {
        let columns = [GridItem(.adaptive(minimum: 100), spacing: 2)]
        return ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(selectedImages.indices, id: \.self) { i in
                    Image(uiImage: selectedImages[i])
                        .resizable()
                        .scaledToFill()
                        .frame(minHeight: 100)
                        .clipped()
                }
            }
        }
    }

    // MARK: - 加载图片
    private func loadImages(from items: [PhotosPickerItem]) {
        selectedImages = []
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
            selectedImages = items.indices.compactMap { loaded[$0] }
        }
    }
}

#Preview {
    NavigationStack {
        CameraView(isPresented: .constant(true))
            .environmentObject(RecordSession())
    }
}
