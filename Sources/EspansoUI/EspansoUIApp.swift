import MenuBarExtraAccess
import SwiftUI

@main
struct EspansoUIApp: App {
    @StateObject private var appState = AppState(
        startWatcher: NSClassFromString("XCTestCase") == nil
    )

    var body: some Scene {
        MenuBarExtra {
            MatchListView()
                .environmentObject(appState)
        } label: {
            Image(systemName: "text.cursor")
        }
        .menuBarExtraStyle(.window)
        .menuBarExtraAccess(isPresented: $appState.isMenuPresented)
    }
}
