import SwiftUI

/// 填写渔获信息（鱼种 / 体长 / 重量）
struct FishFormView: View {
    @Binding var isRecordPresented: Bool
    @EnvironmentObject var recordSession: RecordSession

    @State private var navigateToEnv = false
    @FocusState private var focusedField: Field?

    private enum Field { case species, length, weight }

    private var currentIndex: Int { recordSession.currentFishIndex }
    private var total: Int { recordSession.fishForms.count }

    private var currentForm: Binding<FishForm> {
        Binding(
            get: { recordSession.fishForms[safe: currentIndex] ?? FishForm() },
            set: { recordSession.fishForms[currentIndex] = $0 }
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 抠图缩略图 + 鱼种标签
                cutoutStrip

                Divider().padding(.vertical, 8)

                // 表单字段
                formFields

                // 再记一条
                addAnotherButton

                Text("钓点由定位自动记录，不用手填。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 12)
            }
        }
        .navigationTitle("填写渔获")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Text("第 \(currentIndex + 1)/\(total) 尾")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                navigateToEnv = true
            } label: {
                Text("下一步 · 环境数据")
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
        .navigationDestination(isPresented: $navigateToEnv) {
            EnvDataView(isRecordPresented: $isRecordPresented)
        }
    }

    // MARK: - 抠图缩略图
    private var cutoutStrip: some View {
        HStack(spacing: 12) {
            // 图片
            let images = recordSession.effectiveImages
            if let img = images[safe: currentIndex] {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 80)
            }

            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray4))
                    .frame(width: 74, height: 8)
                Text("已抠图 · 来自上一步")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // 重抠按钮（返回 CutoutView）
            Button("重抠 ↺") {
                recordSession.currentCutoutIndex = currentIndex
            }
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .clipShape(Capsule())
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    // MARK: - 表单字段
    private var formFields: some View {
        VStack(spacing: 0) {
            // 鱼种
            HStack {
                Text("鱼种").font(.subheadline).foregroundStyle(.secondary).frame(width: 50, alignment: .leading)
                TextField("大口黑鲈", text: currentForm.speciesName)
                    .focused($focusedField, equals: .species)
                Spacer()
                Text("改 ›").font(.caption).foregroundStyle(.accentColor)
            }
            .padding(.horizontal)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
            .onTapGesture { focusedField = .species }

            Divider().padding(.leading, 66)

            // 体长 + 重量（并排）
            HStack(spacing: 0) {
                HStack {
                    Text("体长").font(.subheadline).foregroundStyle(.secondary).frame(width: 50, alignment: .leading)
                    TextField("38", text: currentForm.lengthCm)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .length)
                    Text("cm").font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 14)

                Divider().frame(height: 44)

                HStack {
                    Text("重量").font(.subheadline).foregroundStyle(.secondary).frame(width: 50, alignment: .leading)
                    TextField("选填", text: currentForm.weightKg)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .weight)
                    Text("kg").font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 14)
            }

            Divider().padding(.leading, 66)
        }
    }

    // MARK: - 再记一条
    private var addAnotherButton: some View {
        Button {
            recordSession.fishForms.append(FishForm())
            // 把一张新的"原图副本"也加入（同一张图的第二尾鱼）
            if let img = recordSession.rawImages[safe: currentIndex] {
                recordSession.rawImages.append(img)
                recordSession.cutoutImages.append(recordSession.cutoutImages[safe: currentIndex] ?? nil)
            }
            recordSession.currentFishIndex = recordSession.fishForms.count - 1
        } label: {
            Label("这张还有一尾 / 记下一条", systemImage: "plus.circle")
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.systemGray6))
                .foregroundStyle(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }
}

#Preview {
    NavigationStack {
        FishFormView(isRecordPresented: .constant(true))
            .environmentObject({
                let r = RecordSession()
                r.fishForms = [FishForm()]
                return r
            }())
    }
}
