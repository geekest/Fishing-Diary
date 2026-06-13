import SwiftUI

/// 根视图：三 Tab 导航（日记 / 记录+ / 我的）
struct ContentView: View {
    @State private var selectedTab: Int = 0
    @State private var showCamera: Bool = false

    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: 日记 Tab
            NavigationStack {
                DiaryListView()
            }
            .tabItem {
                Label("日记", systemImage: "book.closed.fill")
            }
            .tag(0)

            // MARK: 记录+ Tab（占位，真正的入口是 .overlay 里的按钮）
            Color.clear
                .tabItem {
                    Label("记录", systemImage: "plus.circle.fill")
                }
                .tag(1)

            // MARK: 我的 Tab
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("我的", systemImage: "person.fill")
            }
            .tag(2)
        }
        .tint(Color.accentColor)
        // 中间 Tab 点击时拦截，改为弹出记录流
        .onChange(of: selectedTab) { _, newValue in
            if newValue == 1 {
                showCamera = true
                selectedTab = 0  // 保持日记 tab 高亮
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            NavigationStack {
                CameraView(isPresented: $showCamera)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PurchaseService())
        .environmentObject(RecordSession())
        .modelContainer(for: [FishingSession.self, FishCatch.self], inMemory: true)
}
