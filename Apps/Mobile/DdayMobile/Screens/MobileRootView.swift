import SwiftUI

struct MobileRootView: View {
    @EnvironmentObject private var model: MobileAppModel
    @State private var selectedTab: AppTab = .home

    private enum AppTab: Hashable {
        case home, conferences, customDeadlines, settings
    }

    var body: some View {
        if #available(iOS 18.0, *) {
            TabView(selection: $selectedTab) {
                Tab(model.text.homeTab, systemImage: "house", value: AppTab.home) {
                    HomeScreen()
                }
                Tab(model.text.conferencesTab, systemImage: "calendar", value: AppTab.conferences) {
                    ConferenceBrowserScreen()
                }
                Tab(model.text.customTab, systemImage: "plus.square", value: AppTab.customDeadlines) {
                    CustomDeadlinesScreen()
                }
                Tab(model.text.settingsTab, systemImage: "gearshape", value: AppTab.settings) {
                    SettingsScreen()
                }
            }
            .tabViewStyle(.sidebarAdaptable)
        } else {
            legacyTabs
        }
    }

    private var legacyTabs: some View {
        TabView(selection: $selectedTab) {
            HomeScreen()
                .tabItem {
                    Label(model.text.homeTab, systemImage: "house")
                }
                .tag(AppTab.home)

            ConferenceBrowserScreen()
                .tabItem {
                    Label(model.text.conferencesTab, systemImage: "calendar")
                }
                .tag(AppTab.conferences)

            CustomDeadlinesScreen()
                .tabItem {
                    Label(model.text.customTab, systemImage: "plus.square")
                }
                .tag(AppTab.customDeadlines)

            SettingsScreen()
                .tabItem {
                    Label(model.text.settingsTab, systemImage: "gearshape")
                }
                .tag(AppTab.settings)
        }
    }
}

#Preview {
    MobileRootView()
        .environmentObject(MobileAppModel())
}
