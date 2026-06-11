import Foundation
import Yams

enum EspansoLoaderError: Error {
    case configDirectoryMissing(URL)
}

struct EspansoLoader {
    let configDirectory: URL

    init(configDirectory: URL = EspansoLoader.defaultConfigDirectory) {
        self.configDirectory = configDirectory
    }

    static var defaultConfigDirectory: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appending(
            path: "./Library/Application Support/espanso", directoryHint: .isDirectory
        )
    }

    var matchDirectory: URL {
        configDirectory.appending(path: "match", directoryHint: .isDirectory)
    }

    func load() throws -> [EspansoMatch] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: matchDirectory.path) else {
            throw EspansoLoaderError.configDirectoryMissing(matchDirectory)
        }

        let files = try yamlFiles(under: matchDirectory)
        var results: [EspansoMatch] = []
        for file in files {
            results.append(contentsOf: parseFile(file))
        }
        return results
    }

    func parseFile(_ url: URL) -> [EspansoMatch] {
        guard let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .utf8)
        else {
            return []
        }
        return parse(yaml: text, sourceFile: url)
    }

    func parse(yaml text: String, sourceFile: URL) -> [EspansoMatch] {
        guard let root = try? Yams.load(yaml: text) as? [String: Any],
              let raw = root["matches"] as? [[String: Any]]
        else {
            return []
        }

        return raw.enumerated().compactMap { index, entry in
            makeMatch(from: entry, index: index, sourceFile: sourceFile)
        }
    }

    private func makeMatch(from entry: [String: Any], index: Int, sourceFile: URL) -> EspansoMatch? {
        let triggers = extractTriggers(from: entry)
        let replace = extractReplace(from: entry)
        let label = entry["label"] as? String

        guard !triggers.isEmpty, let replace, !replace.isEmpty else { return nil }

        let id = "\(sourceFile.path)#\(index)"
        return EspansoMatch(
            id: id,
            triggers: triggers,
            replace: replace,
            label: label,
            sourceFile: sourceFile
        )
    }

    private func extractTriggers(from entry: [String: Any]) -> [String] {
        if let triggers = entry["triggers"] as? [String] {
            return triggers
        }
        if let trigger = entry["trigger"] as? String {
            return [trigger]
        }
        if let regex = entry["regex"] as? String {
            return [regex]
        }
        return []
    }

    private func extractReplace(from entry: [String: Any]) -> String? {
        if let replace = entry["replace"] as? String {
            return replace
        }
        if let image = entry["image_path"] as? String {
            return #"<img src="\#(image)" />"#
        }
        if let html = entry["html"] as? String {
            return html
        }
        if let markdown = entry["markdown"] as? String {
            return markdown
        }
        if let form = entry["form"] as? String {
            return form
        }
        return nil
    }

    private func yamlFiles(under directory: URL) throws -> [URL] {
        let fm = FileManager.default
        let keys: [URLResourceKey] = [.isRegularFileKey]
        guard
            let enumerator = fm.enumerator(
                at: directory,
                includingPropertiesForKeys: keys,
                options: [.skipsHiddenFiles]
            )
        else {
            return []
        }

        var results: [URL] = []
        for case let url as URL in enumerator {
            let ext = url.pathExtension.lowercased()
            guard ext == "yml" || ext == "yaml" else { continue }
            let values = try? url.resourceValues(forKeys: Set(keys))
            guard values?.isRegularFile == true else { continue }
            results.append(url)
        }
        return results.sorted { $0.path < $1.path }
    }
}
