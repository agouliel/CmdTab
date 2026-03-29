import SwiftUI
import CoreGraphics
import ApplicationServices

@MainActor
class SwitcherController: ObservableObject {
    @Published var isRunning = false
    @Published var countdown: Int = 0
    @Published var lastTabCount: Int = 0
    @Published var switchCount: Int = 0
    @Published var isAccessibilityGranted: Bool = false

    private var switchTask: Task<Void, Never>?

    init() {
        isAccessibilityGranted = AXIsProcessTrusted()
    }

    func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        isAccessibilityGranted = AXIsProcessTrustedWithOptions(options)
    }

    func recheckAccessibility() {
        isAccessibilityGranted = AXIsProcessTrusted()
    }

    func start() {
        recheckAccessibility()
        guard isAccessibilityGranted, !isRunning else { return }
        isRunning = true
        switchCount = 0
        switchTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                let tabCount = Int.random(in: 1...5)
                self.lastTabCount = tabCount
                self.switchCount += 1

                await self.performCmdTab(tabCount: tabCount)

                let seconds = Int.random(in: 60...180)
                for remaining in stride(from: seconds, through: 0, by: -1) {
                    guard !Task.isCancelled else { return }
                    self.countdown = remaining
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                }
            }
        }
    }

    func stop() {
        switchTask?.cancel()
        switchTask = nil
        isRunning = false
        countdown = 0
    }

    private func performCmdTab(tabCount: Int) async {
        await Task.detached(priority: .userInitiated) {
            let src = CGEventSource(stateID: .hidSystemState)
            let cmdKey: CGKeyCode = 0x37  // left Command
            let tabKey: CGKeyCode = 0x30  // Tab

            // Command down
            let cmdDown = CGEvent(keyboardEventSource: src, virtualKey: cmdKey, keyDown: true)
            cmdDown?.flags = .maskCommand
            cmdDown?.post(tap: .cgSessionEventTap)

            for _ in 0..<tabCount {
                let tabDown = CGEvent(keyboardEventSource: src, virtualKey: tabKey, keyDown: true)
                tabDown?.flags = .maskCommand
                tabDown?.post(tap: .cgSessionEventTap)

                let tabUp = CGEvent(keyboardEventSource: src, virtualKey: tabKey, keyDown: false)
                tabUp?.flags = .maskCommand
                tabUp?.post(tap: .cgSessionEventTap)
            }

            // Command up
            let cmdUp = CGEvent(keyboardEventSource: src, virtualKey: cmdKey, keyDown: false)
            cmdUp?.flags = []
            cmdUp?.post(tap: .cgSessionEventTap)
        }.value
    }
}

struct ContentView: View {
    @EnvironmentObject private var controller: SwitcherController

    var body: some View {
        VStack(spacing: 20) {
            Text("Cmd+Tab Switcher")
                .font(.title2)
                .fontWeight(.semibold)

            if !controller.isAccessibilityGranted {
                accessibilityWarning
            } else {
                statusSection
            }

            controlButtons
        }
        .padding(32)
        .frame(minWidth: 300)
        .onAppear { controller.recheckAccessibility() }
    }

    private var accessibilityWarning: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.shield")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text("Accessibility Access Required")
                .fontWeight(.medium)
            Text("Grant access in System Settings to simulate keystrokes.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Grant Access…") {
                controller.requestAccessibility()
                // Open System Settings to Accessibility pane
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
        }
        .frame(minHeight: 50)
    }

    @ViewBuilder
    private var statusSection: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(controller.isRunning ? Color.green : Color.gray.opacity(0.5))
                    .frame(width: 8, height: 8)
                Text(controller.isRunning ? "Running" : "Idle")
                    .foregroundStyle(controller.isRunning ? .green : .secondary)
                    .fontWeight(.medium)
            }

            if controller.isRunning {
                Text("Next switch in \(controller.countdown)s")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()

                if controller.switchCount > 0 {
                    Text("Last: \(controller.lastTabCount) tab \(controller.lastTabCount == 1 ? "press" : "presses")  •  \(controller.switchCount) total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(minHeight: 50)
        .animation(.easeInOut(duration: 0.2), value: controller.isRunning)
    }

    private var controlButtons: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Button("Start") {
                    controller.start()
                }
                .buttonStyle(.borderedProminent)
                .disabled(controller.isRunning)
                .keyboardShortcut("s", modifiers: [])

                Button("Stop") {
                    controller.stop()
                }
                .buttonStyle(.bordered)
                .disabled(!controller.isRunning)
                .keyboardShortcut(.escape, modifiers: [])
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .font(.caption)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SwitcherController())
}
