import SwiftUI

@MainActor
class SwitcherController: ObservableObject {
    @Published var isRunning = false
    @Published var countdown: Int = 0
    @Published var lastTabCount: Int = 0
    @Published var switchCount: Int = 0

    private var switchTask: Task<Void, Never>?

    func start() {
        guard !isRunning else { return }
        isRunning = true
        switchCount = 0
        switchTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                // Match original: random.randint(1,6) then range(1, n) = 0..5 tabs
                // Using 1..5 so at least one tab is always pressed
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
        var script = "tell application \"System Events\"\n    key down command\n"
        for _ in 0..<tabCount {
            script += "    keystroke tab\n"
        }
        script += "    key up command\nend tell"

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", script]
            process.terminationHandler = { _ in continuation.resume() }
            do {
                try process.run()
            } catch {
                continuation.resume()
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var controller = SwitcherController()

    var body: some View {
        VStack(spacing: 20) {
            Text("Cmd+Tab Switcher")
                .font(.title2)
                .fontWeight(.semibold)

            statusSection

            controlButtons
        }
        .padding(32)
        .frame(minWidth: 300)
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
    }
}

#Preview {
    ContentView()
}
