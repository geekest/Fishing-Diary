import SwiftUI
import SwiftData

// MARK: - 鱼种选择器底部弹窗
struct SpeciesPickerSheet: View {
    @Binding var selectedSpecies: String
    @Binding var isPresented: Bool

    @Query(sort: \FishingSession.date, order: .reverse)
    private var sessions: [FishingSession]

    @State private var searchText = ""

    private struct SpeciesOption: Identifiable {
        let name: String
        let latin: String?

        var id: String { name }
    }

    private struct SpeciesSection: Identifiable {
        let title: String
        let options: [SpeciesOption]

        var id: String { title }
    }

    private static let freshwaterSpecies: [SpeciesOption] = [
        SpeciesOption(name: "大口黑鲈", latin: "M. salmoides"),
        SpeciesOption(name: "鳜鱼", latin: "S. chuatsi"),
        SpeciesOption(name: "翘嘴鲌", latin: "E. ilishaeformis"),
        SpeciesOption(name: "鲤鱼", latin: "C. carpio"),
        SpeciesOption(name: "草鱼", latin: "C. idella"),
        SpeciesOption(name: "鲫鱼", latin: "C. auratus"),
        SpeciesOption(name: "黑鱼", latin: "C. argus"),
        SpeciesOption(name: "罗非鱼", latin: "O. niloticus"),
        SpeciesOption(name: "黄颡鱼", latin: "P. fulvidraco"),
        SpeciesOption(name: "鲢鱼", latin: "H. molitrix"),
        SpeciesOption(name: "鳙鱼", latin: "H. nobilis"),
        SpeciesOption(name: "鲶鱼", latin: "S. asotus"),
    ]

    private static let saltwaterSpecies: [SpeciesOption] = [
        SpeciesOption(name: "鲈鱼", latin: "L. japonicus"),
        SpeciesOption(name: "尖吻鲈", latin: "L. calcarifer"),
        SpeciesOption(name: "黑鲷", latin: "A. schlegelii"),
        SpeciesOption(name: "真鲷", latin: "P. major"),
        SpeciesOption(name: "石斑鱼", latin: "Epinephelus"),
        SpeciesOption(name: "马鲛鱼", latin: "Scomberomorus"),
        SpeciesOption(name: "带鱼", latin: "T. lepturus"),
        SpeciesOption(name: "鲻鱼", latin: "M. cephalus"),
        SpeciesOption(name: "鮻鱼", latin: "L. haematocheila"),
        SpeciesOption(name: "黄鳍鲷", latin: "A. latus"),
    ]

    private static let commonSpecies = freshwaterSpecies + saltwaterSpecies

    private var recordedSpecies: [String] {
        orderedRecordedSpecies(limit: nil)
    }

    private var recentSpecies: [String] {
        orderedRecordedSpecies(limit: 6)
    }

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var sections: [SpeciesSection] {
        if normalizedSearchText.isEmpty {
            return defaultSections
        }

        let matches = filteredOptions(from: Self.commonSpecies + recordedSpecies.map { SpeciesOption(name: $0, latin: nil) })
        return matches.isEmpty ? [] : [SpeciesSection(title: "匹配鱼种", options: matches)]
    }

    private var defaultSections: [SpeciesSection] {
        var result: [SpeciesSection] = []
        if !recentSpecies.isEmpty {
            result.append(SpeciesSection(title: "最近使用", options: recentSpecies.map { SpeciesOption(name: $0, latin: nil) }))
        }
        if !recordedSpecies.isEmpty {
            result.append(SpeciesSection(title: "已记录鱼种", options: recordedSpecies.map { SpeciesOption(name: $0, latin: nil) }))
        }
        result.append(SpeciesSection(title: "常见淡水鱼种", options: Self.freshwaterSpecies))
        result.append(SpeciesSection(title: "常见海水鱼种", options: Self.saltwaterSpecies))
        return result
    }

    private var canAddCustomSpecies: Bool {
        guard !normalizedSearchText.isEmpty else { return false }
        return !allKnownSpeciesNames.contains { $0.localizedCaseInsensitiveCompare(normalizedSearchText) == .orderedSame }
    }

    private var allKnownSpeciesNames: [String] {
        Array(Set(recordedSpecies + Self.commonSpecies.map(\.name)))
    }

    var body: some View {
        ZStack {
            Theme.Colors.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                searchField

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Space.md) {
                        ForEach(sections) { section in
                            speciesSection(section)
                        }

                        if canAddCustomSpecies {
                            customSpeciesButton
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

    private var header: some View {
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
    }

    private var searchField: some View {
        HStack(spacing: Theme.Space.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.Colors.ink3)
            TextField("搜索或输入鱼种…", text: $searchText)
                .font(Theme.Font.body)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, Theme.Space.md)
        .padding(.vertical, 11)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field))
        .shadowSoft()
        .padding(.horizontal, Theme.Space.lg)
    }

    private var customSpeciesButton: some View {
        Button {
            select(normalizedSearchText)
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Theme.Colors.accent)
                Text("添加「\(normalizedSearchText)」")
                    .font(Theme.Font.subhead)
                    .foregroundStyle(Theme.Colors.accent)
                Spacer()
            }
            .padding(.horizontal, Theme.Space.lg)
            .padding(.vertical, 13)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field))
            .shadowSoft()
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Theme.Space.lg)
    }

    private func speciesSection(_ section: SpeciesSection) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            SectionLabel(text: section.title)
                .padding(.horizontal, Theme.Space.lg)

            VStack(spacing: 0) {
                ForEach(Array(section.options.enumerated()), id: \.element.id) { index, species in
                    speciesRow(species)

                    if index < section.options.count - 1 {
                        Divider().padding(.leading, 58)
                    }
                }
            }
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field))
            .shadowSoft()
            .padding(.horizontal, Theme.Space.lg)
        }
    }

    private func speciesRow(_ species: SpeciesOption) -> some View {
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
                    if let latin = species.latin {
                        Text(latin)
                            .font(Theme.Font.microLabel)
                            .foregroundStyle(Theme.Colors.ink3)
                    }
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
    }

    private func filteredOptions(from options: [SpeciesOption]) -> [SpeciesOption] {
        var seen = Set<String>()
        return options.filter { option in
            let matchesName = option.name.localizedCaseInsensitiveContains(normalizedSearchText)
            let matchesLatin = option.latin?.localizedCaseInsensitiveContains(normalizedSearchText) ?? false
            return (matchesName || matchesLatin) && seen.insert(option.name).inserted
        }
    }

    private func orderedRecordedSpecies(limit: Int?) -> [String] {
        var seen = Set<String>()
        let names = sessions.flatMap { session in
            session.catches
                .sorted { $0.sortIndex < $1.sortIndex }
                .map { $0.speciesName.trimmingCharacters(in: .whitespacesAndNewlines) }
        }
        let uniqueNames = names.filter { !$0.isEmpty && seen.insert($0).inserted }
        if let limit {
            return Array(uniqueNames.prefix(limit))
        }
        return uniqueNames
    }

    private func select(_ species: String) {
        selectedSpecies = species.trimmingCharacters(in: .whitespacesAndNewlines)
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
