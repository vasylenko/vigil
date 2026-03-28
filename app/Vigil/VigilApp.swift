import SwiftUI

@main
struct AppLauncher {
    static func main() {
        if NSClassFromString("XCTestCase") != nil {
            TestApp.main()
        } else {
            VigilApp.main()
        }
    }
}

struct VigilApp: App {
    @State private var sleepManager = SleepManager()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(sleepManager: sleepManager)
        } label: {
            Image(systemName: "light.beacon.max.fill")
                .font(.system(size: 22))
                .opacity(sleepManager.isActive ? 1.0 : 0.4)
        }
        .menuBarExtraStyle(.window)
    }
}

struct TestApp: App {
    var body: some Scene {
        WindowGroup { }
    }
}
