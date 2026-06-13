import SwiftUI
import SwiftData

// MARK: - 鱼种选择器底部弹窗
struct SpeciesPickerSheet: View {
    @Binding var selectedSpecies: String
    @Binding var isPresented: Bool

    @Query(sort: \FishingSession.date, order: .reverse)
    private var sessions: [FishingSession]

    @State private var searchText = ""

    private static let allSpecies: [(name: String, latin: String)] = [
        ("大口黑鲈", "M. salmoides"),
        ("鳜鱼", "S. chuatsi"),
        ("翘嘴鲌", "E. ilishaeformis"),
        ("鲤鱼", "C. carpio"),
        ("草鱼", "C. idella"),
        ("鲫鱼", "C. auratus"),
        ("黑鱼", "C. argus"),
        ("罗非鱼", "O. niloticus"),
        ("尖吻鲈", "L. calcarifer"),
        ("黄颡鱼", "P. fulvidraco"),
        ("鲢鱼", "H. molitrix"),
        ("鳙鱼", "H. nobilis"),
        ("鲶鱼", "S. asotus"),
        ("鲻鱼", "M. cephalus"),
        ("鮻鱼", "L. haematocheila"),
    ]

    private var recentSpecies: [String] {
        let all = sessions.flatMap { $0.speciesNames }.filter { !$0.isEmpty }
        var seen = Set<String>()
        return all.filter { seen.insert($0).inserted }.prefix(5).map { $0 }
    }

    private var filteredSpecies: [(name: String, latin: String)] {
        if searchText.isEmpty { return Self.allSpecies }
        return Self.allSpecies.filter {
            $0.name.contains(searchText) || $0.latin.lowercased().contains(searchText.lowercased())
        }
    }

    var body: some View {
        ZStack {
            Theme.Colors.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部抓手 + 标题
                VStack(spacing: Theme.Space.md) {
                    Capsule()
                        .fill(Theme.Colors.ink3)
                        .frame(width: 36, height: 5)
                        .padding(.top, 12)

                    Text("选择鱼种")
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.Colors.ink)
                }
                .padding(.bottom, Theme.Space.md)

                // 搜索框
                HStack(spacing: Theme.Space.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Theme.Colors.ink3)
                    TextField("搜索鱼种…", text: $searchText)
                        .font(Theme.Font.body)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, Theme.Space.md)
                .padding(.vertical, 11)
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field))
                .shadowSoft()
                .padding(.horizontal, Theme.Space.lg)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // 最近使用
                        if searchText.isEmpty && !recentSpecies.isEmpty {
                            VStack(alignment: .leading, spacing: Theme.Space.md) {
                                SectionLabel(text: "最近使用")
                                    .padding(.horizontal, Theme.Space.lg)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: Theme.Space.sm) {
                                        ForEach(recentSpecies, id: \.self) { species in
                                            Button {
                                                select(species)
                                            } label: {
                                                HStack(spacing: 5) {
                                                    Text("🐟").font(.caption)
                                                    Text(species).font(Theme.Font.subhead)
                                                }
                                                .foregroundStyle(selectedSpecies == species ? .white : Theme.Colors.ink)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 7)
                                                .background(selectedSpecies == species ? Theme.Colors.accent : Theme.Colors.chip)
                                                .clipShape(Capsule())
                                            }
                                        }
                                    }
                                    .padding(.horizontal, Theme.Space.lg)
                                }
                            }
                            .padding(.vertical, Theme.Space.md)

                            Divider()
                                .padding(.horizontal, Theme.Space.lg)
                                .padding(.vertical, Theme.Space.sm)
                        }

                        // 全部鱼种
                        SectionLabel(text: "全部鱼种")
                            .padding(.horizontal, Theme.Space.lg)
                            .padding(.top, Theme.Space.md)
                            .padding(.bottom, Theme.Space.sm)

                        VStack(spacing: 0) {
                            ForEach(Array(filteredSpecies.enumerated()), id: \.offset) { i, species in
                                Button {
                                    select(species.name)
                                } label: {
                                    HStack {
                                        Text("🐟").font(.title3)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(species.name)
                                                .font(Theme.Font.subhead)
                                                .fontWeight(.medium)
                                                .foregroundStyle(Theme.Colors.ink)
                                            Text(species.latin)
                                                .font(Theme.Font.microLabel)
                                                .foregroundStyle(Theme.Colors.ink3)
                                        }
                                        Spacer()
                                        if selectedSpecies == species.name {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(Theme.Colors.accent)
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    .padding(.horizontal, Theme.Space.lg)
                                    .padding(.vertical, 13)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                if i < filteredSpecies.count - 1 {
                                    Divider().padding(.leading, 58)
                                }
                            }
                        }
                        .background(Theme.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field))
                        .shadowSoft()
                        .padding(.horizontal, Theme.Space.lg)

                        // 自定义输入
                        if !searchText.isEmpty && !filteredSpecies.map(\.name).contains(searchText) {
                            Button {
                                select(searchText)
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(Theme.Colors.accent)
                                    Text("添加 "\(searchText)"")
                                        .font(Theme.Font.subhead)
                                        .foregroundStyle(Theme.Colors.accent)
                                    Spacer()
                                }
                                .padding(.horizontal, Theme.Space.lg)
                                .padding(.vertical, 13)
                            }
                            .padding(.top, Theme.Space.sm)
                        }
                    }
                    .padding(.top, Theme.Space.md)
                    .padding(.bottom, 30)
                }
            }
        }
        .presentationCornerRadius(Theme.Radius.sheet)
        .presentationDragIndicator(.hidden)
    }

    private func select(_ species: String) {
        selectedSpecies = species
        isPresented = false
    }
}

#Preview {
    Text("preview")
        .sheet(isPresented: .constant(true)) {
            SpeciesPickerSheet(
                selectedSpecies: .constant("大口黑鲈"),
                isPresented: .constant(true)
            )
            .presentationDetents([.medium, .large])
        }
        .modelContainer(for: [FishingSession.self, FishCatch.self], inMemory: true)
}
