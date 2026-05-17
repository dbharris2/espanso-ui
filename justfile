# Espanso UI macOS App

# List available recipes
default:
    @just --list

# Generate Xcode project from project.yml
generate:
    xcodegen generate

# Build the app (regenerates project first)
build: generate
    xcodebuild -scheme EspansoUI -configuration Debug build

# Run the app (builds first, kills existing instance)
run: build
    -pkill -x EspansoUI
    @open "$( xcodebuild -scheme EspansoUI -configuration Debug -showBuildSettings 2>/dev/null | grep -m1 'BUILT_PRODUCTS_DIR' | awk '{print $3}' )/EspansoUI.app"

# Open the app without rebuilding
open:
    -pkill -x EspansoUI
    @open "$( xcodebuild -scheme EspansoUI -configuration Debug -showBuildSettings 2>/dev/null | grep -m1 'BUILT_PRODUCTS_DIR' | awk '{print $3}' )/EspansoUI.app"

# Run SwiftFormat to auto-fix formatting
format:
    swiftformat .

# Run SwiftLint with auto-fix
lint-fix:
    swiftlint --fix

# Check formatting and linting without modifying files
lint:
    swiftformat . --lint
    swiftlint

# Run unit tests
test: generate
    xcodebuild -scheme EspansoUI -configuration Debug -destination 'platform=macOS' test

# Clean build artifacts
clean:
    xcodebuild -scheme EspansoUI -configuration Debug clean
    rm -rf ~/Library/Developer/Xcode/DerivedData/EspansoUI-*

# Open project in Xcode
xcode: generate
    open EspansoUI.xcodeproj
