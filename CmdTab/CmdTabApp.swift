import SwiftUI

@main
struct CmdTabApp: App {
    @StateObject private var controller = SwitcherController()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(controller)
        } label: {
            Image(systemName: controller.isRunning ? "arrow.2.squarepath" : "arrow.2.squarepath")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(controller.isRunning ? .green : .primary)
        }
        .menuBarExtraStyle(.window)
    }
}
