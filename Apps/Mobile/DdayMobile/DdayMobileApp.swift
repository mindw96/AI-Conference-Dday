import SwiftUI

@main
struct DdayMobileApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var model = MobileAppModel()

    var body: some Scene {
        WindowGroup {
            MobileRootView()
                .environmentObject(model)
                .task(id: scenePhase) {
                    if scenePhase == .active {
                        await model.refreshAfterActivation()
                    }
                }
        }
    }
}
