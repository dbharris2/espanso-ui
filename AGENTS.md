# Espanso UI (macOS)

A macOS menu bar app that reads `~/.config/espanso` and presents a Maccy-style picker for copying snippet replacements to the clipboard.

## Tech Stack

- SwiftUI with `MenuBarExtra` (macOS 14+)
- [Yams](https://github.com/jpsim/Yams) for YAML parsing
- `DispatchSource` file watching on the config dir
- XcodeGen + just for project + task running

## Project Structure

- `Sources/EspansoUI/`
  - `EspansoUIApp.swift` — entry point, `MenuBarExtra` scene
  - `AppState.swift` — `@MainActor` observable state, owns the loader + watcher
  - `Models/EspansoMatch.swift` — model: trigger(s), replace text, optional image path
  - `Models/MatchFilter.swift` — All / Text / Images filter
  - `Services/EspansoLoader.swift` — scans `~/.config/espanso/match/**/*.yml`, parses with Yams
  - `Services/ConfigWatcher.swift` — `DispatchSource`-based watcher that re-fires loader
  - `Views/MatchListView.swift` — searchable list with type-filter picker; switches to grid when filter is Images
  - `Views/MatchRowView.swift` — one row; renders image if `replace` contains `<img src="...">`
  - `Views/MatchGridView.swift` — image grid view (used when filter is Images)
  - `Views/RemoteImage.swift` — URLSession-backed image loader + NSCache + animated NSImageView wrapper
- `Resources/` — Info.plist, entitlements, Assets.xcassets
- `Tests/EspansoUITests/` — unit tests for the loader

## Key Patterns

- `@MainActor` for UI state; loader runs off-main and hands results back
- Sandbox is OFF so the app can read `~/.config/espanso` directly
- Image rendering: when a match's `replace` looks like a single `<img src="URL"/>`, the row/cell renders via `RemoteImage`, which uses a shared `NSCache<NSURL, NSImage>` and an animated `NSImageView` (so GIFs play)
- Match identity is `file_path + index` so re-loads don't break selection

## Common Commands

```bash
just build    # Generate project + build
just run      # Build + launch app
just test     # Run unit tests
just lint     # Check formatting + linting
just format   # Auto-fix formatting
```

## Version Control

This repo uses **Jujutsu** (`jj`), not git. Use `jj` commands for VCS operations.
