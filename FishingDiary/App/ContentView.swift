import SwiftUI

struct ContentView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var selectedTab: Int = 0
    @State private var showCamera: Bool = false

    var body: some View {
        Group {
            if hasOnboarded {
                mainInterface
            } else {
                OnboardingView()
            }
        }
    }

    // MARK: - 主界面（含自定义 Tab Bar）
    private var mainInterface: some View {
        ZStack(alignment: .bottom) {
            // 内容区
            Group {
                NavigationStack {
                    DiaryListView()
                }
                .opacity(selectedTab == 0 ? 1 : 0)
                .allowsHitTesting(selectedTab == 0)

                NavigationStack {
                    ProfileView()
                }
                .opacity(selectedTab == 2 ? 1 : 0)
                .allowsHitTesting(selectedTab == 2)
            }
            .ignoresSafeArea(edges: .bottom)

            // 自定义浮动 Tab Bar
            FloatingTabBar(selectedTab: $selectedTab) {
                showCamera = true
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            NavigationStack {
                CameraView(isPresented: $showCamera)
            }
        }
    }
}

// MARK: - 浮动 Tab Bar
private struct FloatingTabBar: View {
    @Binding var selectedTab: Int
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // 日记 Tab
            tabItem(icon: "book.closed.fill", label: "日记", tag: 0)

            Spacer()

            // 中间 + 按钮（松绿胶囊）
            Button(action: onAdd) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(width: 64, height: 40)
                .background(Theme.Colors.accent)
                .clipShape(Capsule())
                .shadowSoft()
            }
            .buttonStyle(ScaleButtonStyle())

            Spacer()

            // 我的 Tab
            tabItem(icon: "person.fill", label: "我的", tag: 2)
        }
        .padding(.horizontal, Theme.Space.xxl)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(
            Theme.Colors.surface
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadowPop()
        )
        .padding(.horizontal, Theme.Space.lg)
        .padding(.bottom, 8)
    }

    private func tabItem(icon: String, label: String, tag: Int) -> some View {
        Button {
            selectedTab = tag
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(Theme.Font.caption)
                    .fontWeight(selectedTab == tag ? .semibold : .regular)
            }
            .foregroundStyle(selectedTab == tag ? Theme.Colors.accent : Theme.Colors.ink3)
            .frame(width: 64)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
        .environmentObject(PurchaseService())
        .environmentObject(RecordSession())
        .modelContainer(for: [FishingSession.self, FishCatch.self], inMemory: true)
}
