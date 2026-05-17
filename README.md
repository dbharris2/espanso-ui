# Espanso UI (macOS)

A macOS menu bar app that gives [Espanso](https://espanso.org/) a Maccy-style picker. It reads your `~/.config/espanso` directory, lists every match, and lets you copy a snippet's replacement to the clipboard from the menu bar.

This is a viewer, not an editor — add and remove snippets in your Espanso config files as usual.

## Features

- Menu bar list of every Espanso match (trigger → replace)
- Inline preview for image replacements (`<img src="...">`)
- Type-ahead search
- Enter / click to copy the replacement to the clipboard
- Live reload when the config files change

## Setup

```bash
brew install xcodegen just swiftlint swiftformat
just xcode    # Generates project + opens in Xcode
```

Press ⌘R to build and run.

## Project Structure

- `Sources/EspansoUI/`
  - `EspansoUIApp.swift` — app entry point + `MenuBarExtra`
  - `AppState.swift` — observable state, config watcher
  - `Models/EspansoMatch.swift` — match model
  - `Services/EspansoLoader.swift` — YAML parsing + filesystem watch
  - `Views/` — SwiftUI views
- `Resources/` — Info.plist, entitlements, assets
- `Tests/EspansoUITests/` — unit tests
- `project.yml` — XcodeGen spec

## Common Commands

```bash
just build    # Generate project + build
just run      # Build + launch app
just test     # Run unit tests
just lint     # Check formatting + linting
just format   # Auto-fix formatting
```
