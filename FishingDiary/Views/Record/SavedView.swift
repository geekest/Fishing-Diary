import SwiftUI
import SwiftData

/// 保存成功界面：存入 SwiftData 并引导分享
struct SavedView: View {
    @Binding var isRecordPresented: Bool
    @EnvironmentObject var recordSession: RecordSession
    @EnvironmentObject var purchaseService: PurchaseService
    @Environment(\.modelContext) private var modelContext

    @State private var savedSession: FishingSession? = nil
    @State private var navigateToShare = false
    @State private var isSaving = true

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 40)

                // 大勾
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 88, height: 88)
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                }

                Text("已存入日记")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("免费记录完成 — 要不要生成一张分享图？")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                // 卡片预览
                if let session = savedSession {
                    cardPreview(session: session)
                } else if isSaving {
                    ProgressView("保存中…")
                        .frame(height: 200)
                }

                // 操作按钮
                VStack(spacing: 12) {
                    if let session = savedSession {
                        Button {
                            navigateToShare = true
                        } label: {
                            Label("生成分享图", systemImage: "sparkles")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .navigationDestination(isPresented: $navigateToShare) {
                            ShareStyleView(session: session, isRecordPresented: $isRecordPresented)
                        }
                    }

                    Button("暂不，回日记") {
                        recordSession.reset()
                        isRecordPresented = false
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("保存完成")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .task { await saveSession() }
    }

    // MARK: - 卡片预览（占位样式）
    private func cardPreview(session: FishingSession) -> some View {
        ZStack(alignment: .bottomLeading) {
            // 封面图或占位
            Group {
                if let data = session.coverImageData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle().fill(Color(.systemGray5))
                }
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // 渐变蒙层
            LinearGradient(
                colors: [.clear, .black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // 文字
            VStack(alignment: .leading, spacing: 4) {
                Text("钓鱼日记 · \(session.date.formatted(.dateTime.month(.twoDigits).day(.twoDigits)))")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                if let first = session.catches.first {
                    Text("\(first.lengthCm.map { "\(Int($0))" } ?? "—") cm")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                    Text("\(first.speciesName) · \(session.locationName)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding(16)
        }
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }

    // MARK: - 写入 SwiftData
    private func saveSession() async {
        // 构建 FishCatch 列表
        var catches: [FishCatch] = []
        let forms = recordSession.fishForms
        let images = recordSession.effectiveImages

        for (i, form) in forms.enumerated() {
            let effective = images[safe: i] ?? UIImage()
            let original = recordSession.rawImages[safe: i] ?? UIImage()

            let catch_ = FishCatch(
                speciesName: form.speciesName.isEmpty ? "未知鱼种" : form.speciesName,
                lengthCm: Double(form.lengthCm),
                weightKg: Double(form.weightKg),
                cutoutImageData: effective.pngData() ?? Data(),
                originalImageData: original.jpegData(compressionQuality: 0.8) ?? Data(),
                sortIndex: i
            )
            catches.append(catch_)
            modelContext.insert(catch_)
        }

        // 构建天气 Data
        var weatherData: Data? = nil
        if let w = recordSession.weather {
            let toggles = recordSession.weatherToggles
            // 根据用户开关过滤存入的字段
            let filtered = WeatherSnapshot(
                temperature: toggles.temperature ? w.temperature : 0,
                windSpeed: toggles.wind ? w.windSpeed : 0,
                windDirection: toggles.wind ? w.windDirection : "",
                pressure: toggles.pressure ? w.pressure : 0,
                uvIndex: toggles.uvIndex ? w.uvIndex : 0,
                condition: toggles.condition ? w.condition : "",
                waterTemp: toggles.waterTemp ? w.waterTemp : nil,
                moonPhase: toggles.moonPhase ? w.moonPhase : nil,
                tide: toggles.tide ? w.tide : nil
            )
            weatherData = try? JSONEncoder().encode(filtered)
        }

        let session = FishingSession(
            date: .now,
            locationName: recordSession.locationName,
            latitude: recordSession.latitude,
            longitude: recordSession.longitude,
            catches: catches,
            weatherData: weatherData,
            coverImageData: images.first?.pngData()
        )
        modelContext.insert(session)

        do {
            try modelContext.save()
        } catch {
            print("SwiftData 保存失败：\(error)")
        }

        await MainActor.run {
            savedSession = session
            isSaving = false
        }
    }
}

#Preview {
    NavigationStack {
        SavedView(isRecordPresented: .constant(true))
            .environmentObject(RecordSession())
            .environmentObject(PurchaseService())
    }
    .modelContainer(for: [FishingSession.self, FishCatch.self], inMemory: true)
}
