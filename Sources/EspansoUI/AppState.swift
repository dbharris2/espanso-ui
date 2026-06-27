import AppKit
import Combine
import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var matches: [EspansoMatch] = []
    @Published private(set) var lastError: String?
    @Published var searchText: String = ""
    @Published var filter: MatchFilter = .all
    @Published var isMenuPresented: Bool = false {
        didSet {
            guard isMenuPresented != oldValue else { return }
            handleMenuPresentationChange()
        }
    }

    private let loader: EspansoLoader
    private let shouldWatchConfig: Bool
    private var watcher: ConfigWatcher?
    private var reloadTask: Task<Void, Never>?

    var configDirectory: URL {
        loader.configDirectory
    }

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    var filteredMatches: [EspansoMatch] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        return matches.filter { match in
            guard filter.includes(match) else { return false }
            guard !query.isEmpty else { return true }
            if match.triggers.contains(where: { $0.lowercased().contains(query) }) { return true }
            if match.replace.lowercased().contains(query) { return true }
            if let label = match.label, label.lowercased().contains(query) { return true }
            return false
        }
    }

    init(loader: EspansoLoader = EspansoLoader(), startWatcher: Bool = true) {
        self.loader = loader
        shouldWatchConfig = startWatcher
        if !startWatcher {
            reload()
        }
    }

    func reload() {
        reloadTask?.cancel()

        let loader = loader
        reloadTask = Task.detached(priority: .utility) { [loader, weak self] in
            let result = AppState.loadMatches(with: loader)

            guard !Task.isCancelled else { return }

            await self?.applyReloadResult(result)
        }
    }

    func copy(_ match: EspansoMatch) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(match.replace, forType: .string)
        isMenuPresented = false
    }

    func openConfigDirectory() {
        NSWorkspace.shared.open(configDirectory)
    }

    private func handleMenuPresentationChange() {
        guard shouldWatchConfig else { return }

        if isMenuPresented {
            reload()
            startWatcherIfNeeded()
        } else {
            reloadTask?.cancel()
            watcher?.stop()
        }
    }

    private func startWatcherIfNeeded() {
        if watcher == nil {
            watcher = ConfigWatcher(directory: loader.configDirectory) { [weak self] in
                Task { @MainActor in
                    guard self?.isMenuPresented == true else { return }
                    self?.reload()
                }
            }
        }
        watcher?.start()
    }

    private nonisolated static func loadMatches(with loader: EspansoLoader) -> ReloadResult {
        do {
            return try .success(loader.load())
        } catch let error as EspansoLoaderError {
            return .failure(describe(error))
        } catch {
            return .failure(error.localizedDescription)
        }
    }

    private func applyReloadResult(_ result: ReloadResult) {
        switch result {
        case let .success(matches):
            self.matches = matches
            lastError = nil
        case let .failure(message):
            matches = []
            lastError = message
        }
    }

    private nonisolated static func describe(_ error: EspansoLoaderError) -> String {
        switch error {
        case let .configDirectoryMissing(url):
            "Espanso config not found at \(url.path)"
        }
    }
}

private enum ReloadResult {
    case success([EspansoMatch])
    case failure(String)
}
