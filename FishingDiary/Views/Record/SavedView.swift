import SwiftUI
import SwiftData

// MARK: - 保存成功界面
struct SavedView: View {
    @Binding var isRecordPresented: Bool
    @EnvironmentObject var recordSession: RecordSession
    @EnvironmentObject var purchaseService: PurchaseService
    @Environment(\.modelContext) private var modelContext

    @State private var savedSession: FishingSession? = nil
    @State private var navigateToShare = false
    @State private var isSaving = true
    @State private var badgeScale: CGFloat = 0.3
    @State private var badgeOpacity: Double = 0

    var body: some View {
        ZStack {
            Theme.Colors.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.Space.xxl) {
                    Spacer(minLength: 40)

                    // 大勾 badge
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.accentSoft)
                            .frame(width: 96, height: 96)
                        Image(systemName: "checkmark")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundStyle(Theme.Colors.accent)
                    }
                    .scaleEffect(badgeScale)
                    .opacity(badgeOpacity)

                    // 标题区
                    VStack(spacing: Theme.Space.sm) {
                        Text("已存入日记")
                            .font(Theme.Font.title)
                            .foregroundStyle(Theme.Colors.ink)

                        Text("免费记录完成 · 要生成一张分享卡吗？")
                            .font(Theme.Font.body)
                            .foregroundStyle(Theme.Colors.ink2)
                            .multilineTextAlignment(.center)
                    }

                    // 分享卡预览
                    if let session = savedSession {
                        shareCardPreview(session: session)
                    } else if isSaving {
                        RoundedRectangle(cornerRadius: Theme.Radius.card)
                            .fill(Theme.Colors.bg2)
                            .aspectRatio(3/4, contentMode: .fit)
                            .frame(maxWidth: 220)
                            .overlay {
                                ProgressView().tint(Theme.Colors.accent)
                            }
                    }

                    // 操作按钮
                    VStack(spacing: Theme.Space.md) {
                        if let session = savedSession {
                            PrimaryButton(title: "✦  生成分享图") {
                                navigateToShare = true
                            }
                            .navigationDestination(isPresented: $navigateToShare) {
                                ShareStyleView(session: session, isRecordPresented: $isRecordPresented)
                            }
                        } else {
                            PrimaryButton(title: "生成分享图", isLoading: true) {}
                        }

                        GhostButton(title: "暂不，回日记") {
                            recordSession.reset()
                            isRecordPresented = false
                        }
                    }
                    .padding(.horizontal, Theme.Space.lg)

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationTitle("保存完成")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .task {
            await saveSession()
            // 入场动画
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                badgeScale = 1.0
                badgeOpacity = 1.0
            }
        }
    }

    // MARK: - 分享卡预览
    private func shareCardPreview(session: FishingSession) -> some View {
        ZStack(alignment: .bottomLeading) {
            // 封面图或渐变占位
            Group {
                if let data = session.coverImageData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Theme.Colors.catchGradient(for: session.id)
                }
            }
            .frame(maxWidth: .infinity)
            .clipped()

            // 蒙层
            LinearGradient(
                colors: [.clear, .black.opacity(0.65)],
                startPoint: .top,
                endPoint: .bottom
            )

            // 卡片内容
            VStack(alignment: .leading, spacing: 4) {
                Text("钓鱼日记 · \(formattedDate(session.date))")
                    .font(Theme.Font.microLabel)
                    .foregroundStyle(.white.opacity(0.7))

                if let first = session.catches.first {
                    if let len = first.lengthCm {
                        HStack(alignment: .lastTextBaseline, spacing: 3) {
                            Text("\(Int(len))")
                                .font(Theme.Font.data(34, weight: .medium))
                                .foregroundStyle(.white)
                            Text("cm")
                                .font(Theme.Font.subhead)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    Text("\(first.speciesName) · \(session.locationName)")
                        .font(Theme.Font.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .padding(Theme.Space.lg)
        }
        .aspectRatio(3/4, contentMode: .fit)
        .frame(maxWidth: 220)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .shadowCard()
    }

    private func formattedDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MM.dd"
        return fmt.string(from: date)
    }

    // MARK: - 写入 SwiftData
    private func saveSession() async {
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

        var weatherData: Data? = nil
        if let w = recordSession.weather {
            let toggles = recordSession.weatherToggles
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

        let firstMethod = recordSession.fishForms.first?.fishingMethod ?? ""
        let combinedNotes = recordSession.fishForms
            .compactMap { $0.notes.isEmpty ? nil : $0.notes }
            .joined(separator: "\n")

        let session = FishingSession(
            date: .now,
            locationName: recordSession.locationName,
            latitude: recordSession.latitude,
            longitude: recordSession.longitude,
            catches: catches,
            weatherData: weatherData,
            coverImageData: images.first?.pngData(),
            notes: combinedNotes.isEmpty ? nil : combinedNotes,
            fishingMethod: firstMethod
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
