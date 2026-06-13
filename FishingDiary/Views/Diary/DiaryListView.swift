import SwiftUI
import SwiftData

/// 日记时间线（主页）
struct DiaryListView: View {
    @Query(sort: \FishingSession.date, order: .reverse)
    private var sessions: [FishingSession]

    /// 按日期（年-月）分组
    private var grouped: [(String, [FishingSession])] {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy年MM月"
        let dict = Dictionary(grouping: sessions) { fmt.string(from: $0.date) }
        return dict.sorted { $0.key > $1.key }
    }

    var body: some View {
        Group {
            if sessions.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .navigationTitle("钓鱼日记")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Text("2026 ▾")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - 空态
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "fish")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)
            Text("点右下「记录」\n开始今天的渔获")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 日记列表
    private var list: some View {
        List {
            ForEach(grouped, id: \.0) { month, items in
                Section(header: Text(month).font(.footnote).foregroundStyle(.secondary)) {
                    ForEach(items) { session in
                        NavigationLink(destination: SessionDetailView(session: session)) {
                            SessionRowView(session: session)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - 日记行
private struct SessionRowView: View {
    let session: FishingSession

    private var dateText: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MM.dd"
        return fmt.string(from: session.date)
    }

    var body: some View {
        HStack(spacing: 12) {
            // 封面图
            Group {
                if let data = session.coverImageData,
                   let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay {
                            Image(systemName: "fish")
                                .foregroundStyle(.tertiary)
                        }
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // 文字信息
            VStack(alignment: .leading, spacing: 4) {
                Text("\(dateText) · \(session.locationName.isEmpty ? "未知钓点" : session.locationName)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text(session.speciesNames.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // 渔获数量
            Text("×\(session.totalCatch)")
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.1))
                .foregroundStyle(Color.accentColor)
                .clipShape(Capsule())
        }
    }
}

// MARK: - 出钓详情（占位）
struct SessionDetailView: View {
    let session: FishingSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 封面图
                if let data = session.coverImageData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // 基本信息
                VStack(alignment: .leading, spacing: 8) {
                    Label(session.locationName.isEmpty ? "未知钓点" : session.locationName,
                          systemImage: "mappin.circle.fill")
                    Label("\(session.totalCatch) 尾渔获", systemImage: "fish.fill")
                    if let w = session.weather {
                        Label("\(w.condition) · \(Int(w.temperature))°C", systemImage: "cloud.fill")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Divider()

                // 渔获列表
                ForEach(session.catches.sorted(by: { $0.sortIndex < $1.sortIndex })) { catch_ in
                    FishCatchRow(fishCatch: catch_)
                }
            }
            .padding()
        }
        .navigationTitle(session.locationName.isEmpty ? "出钓记录" : session.locationName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct FishCatchRow: View {
    let fishCatch: FishCatch

    var body: some View {
        HStack(spacing: 12) {
            if let img = UIImage(data: fishCatch.cutoutImageData) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(fishCatch.speciesName.isEmpty ? "未填鱼种" : fishCatch.speciesName)
                    .font(.subheadline).fontWeight(.medium)
                if let len = fishCatch.lengthCm {
                    Text("\(Int(len)) cm")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if let kg = fishCatch.weightKg {
                    Text(String(format: "%.2f kg", kg))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DiaryListView()
    }
    .modelContainer(for: [FishingSession.self, FishCatch.self], inMemory: true)
}
