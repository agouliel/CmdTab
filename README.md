# CmdTab Switcher

A macOS menu bar app that randomly switches between open applications by simulating Cmd+Tab at randomised intervals.

## Behaviour

- Presses Cmd+Tab a random number of times (1–5) to cycle through apps
- Waits a random interval between **1 and 3 minutes** before switching again
- Runs continuously until stopped

## Requirements

- macOS 13 Ventura or later
- **Accessibility permission** — required to simulate keystrokes (System Settings → Privacy & Security → Accessibility)

## Installation

1. Open `CmdTab.xcodeproj` in Xcode
2. Select **Product → Build** (`⌘B`)
3. Select **Product → Show Build Folder in Finder**, navigate to `Products/Release/CmdTab.app`
4. Drag `CmdTab.app` to your `/Applications` folder

> If macOS blocks the app on first launch, right-click → **Open** → **Open Anyway**.

## Usage

1. Launch the app — a **⇄** icon appears in the menu bar
2. Click the icon to open the control panel
3. If prompted, click **Grant Access…** to open System Settings and enable Accessibility for CmdTab
4. Click **Start** to begin — the icon turns green while active
5. Click **Stop** to pause, or **Quit** to exit

## Distributing to Other Machines

Copy `CmdTab.app` to the target Mac. Recipients will need to right-click → **Open** the first time to bypass Gatekeeper (the app is unsigned). They will also need to grant Accessibility permission on their own machine.
