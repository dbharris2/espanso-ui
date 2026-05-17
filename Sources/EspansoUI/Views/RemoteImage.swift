import AppKit
import SwiftUI

struct RemoteImage<Placeholder: View>: View {
    let url: URL
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var image: NSImage?
    @State private var didFail = false

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image).resizable().scaledToFill()
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            await load()
        }
    }

    private func load() async {
        if let cached = RemoteImageCache.shared.image(for: url) {
            image = cached
            return
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            try Task.checkCancellation()
            if let http = response as? HTTPURLResponse, !(200 ... 299).contains(http.statusCode) {
                didFail = true
                return
            }
            guard let nsImage = NSImage(data: data) else {
                didFail = true
                return
            }
            RemoteImageCache.shared.set(nsImage, for: url)
            image = nsImage
        } catch is CancellationError {
            return
        } catch {
            didFail = true
        }
    }
}

final class RemoteImageCache: @unchecked Sendable {
    static let shared = RemoteImageCache()

    private let cache: NSCache<NSURL, NSImage> = {
        let c = NSCache<NSURL, NSImage>()
        c.countLimit = 256
        c.totalCostLimit = 64 * 1024 * 1024
        return c
    }()

    func image(for url: URL) -> NSImage? {
        cache.object(forKey: url as NSURL)
    }

    func set(_ image: NSImage, for url: URL) {
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: url as NSURL, cost: cost)
    }
}
