import Foundation

struct EspansoMatch: Identifiable, Hashable {
    let id: String
    let triggers: [String]
    let replace: String
    let label: String?
    let sourceFile: URL

    var primaryTrigger: String {
        triggers.first ?? ""
    }

    var displayTitle: String {
        if let label, !label.isEmpty { return label }
        return primaryTrigger
    }

    var imageURL: URL? {
        Self.extractImageURL(from: replace, relativeTo: sourceFile.deletingLastPathComponent())
    }

    var isImage: Bool {
        imageURL != nil
    }

    static func extractImageURL(from replace: String, relativeTo baseDir: URL) -> URL? {
        let trimmed = replace.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            let regex = try? NSRegularExpression(
                pattern: #"^<img\s+[^>]*src=["']([^"']+)["'][^>]*/?>$"#,
                options: [.caseInsensitive]
            )
        else { return nil }

        let range = NSRange(trimmed.startIndex..., in: trimmed)
        guard let match = regex.firstMatch(in: trimmed, options: [], range: range),
              match.numberOfRanges >= 2,
              let srcRange = Range(match.range(at: 1), in: trimmed)
        else {
            return nil
        }
        let src = String(trimmed[srcRange])
        if let url = URL(string: src), url.scheme != nil {
            return url
        }
        return URL(fileURLWithPath: src, relativeTo: baseDir)
    }
}
