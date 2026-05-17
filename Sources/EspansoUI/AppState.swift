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
    @Published var isMenuPresented: Bool = false

    private let loader: EspansoLoader
    private var watcher: ConfigWatcher?

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
        reload()
        guard startWatcher else { return }
        let watcher = ConfigWatcher(directory: loader.configDirectory) { [weak self] in
            Task { @MainActor in self?.reload() }
        }
        self.watcher = watcher
        watcher.start()
    }

    func reload() {
        do {
            matches = try loader.load()
            lastError = nil
        } catch {
            matches = []
            lastError = (error as? EspansoLoaderError).map(describe) ?? error.localizedDescription
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

    private func describe(_ error: EspansoLoaderError) -> String {
        switch error {
        case let .configDirectoryMissing(url):
            "Espanso config not found at \(url.path)"
        }
    }
}
