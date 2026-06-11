import Foundation

final class ConfigWatcher: @unchecked Sendable {
    private let directory: URL
    private let onChange: @Sendable () -> Void
    private let queue = DispatchQueue(label: "com.espansoui.config-watcher", qos: .utility)
    private let debounceInterval: DispatchTimeInterval

    // All mutable state below is only touched on `queue`.
    private var sources: [DispatchSourceFileSystemObject] = []
    private var descriptors: [Int32] = []
    private var pendingWork: DispatchWorkItem?

    init(
        directory: URL,
        debounce: DispatchTimeInterval = .milliseconds(200),
        onChange: @escaping @Sendable () -> Void
    ) {
        self.directory = directory
        self.debounceInterval = debounce
        self.onChange = onChange
    }

    deinit {
        sources.forEach { $0.cancel() }
        descriptors.forEach { close($0) }
    }

    func start() {
        queue.async { [weak self] in self?.rebuildWatches() }
    }

    func stop() {
        queue.async { [weak self] in self?.teardown() }
    }

    private func rebuildWatches() {
        teardown()
        watch(directory)
        let matchDir = directory.appending(path: "match", directoryHint: .isDirectory)
        if FileManager.default.fileExists(atPath: matchDir.path) {
            watch(matchDir)
            for sub in enumerateSubdirectories(matchDir) {
                watch(sub)
            }
        }
    }

    private func teardown() {
        sources.forEach { $0.cancel() }
        sources.removeAll()
        descriptors.forEach { close($0) }
        descriptors.removeAll()
        pendingWork?.cancel()
        pendingWork = nil
    }

    private func watch(_ url: URL) {
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else { return }
        descriptors.append(fd)

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename, .extend],
            queue: queue
        )
        source.setEventHandler { [weak self] in
            self?.scheduleNotification()
        }
        source.setCancelHandler { [fd] in close(fd) }
        source.resume()
        sources.append(source)
    }

    private func enumerateSubdirectories(_ root: URL) -> [URL] {
        let fm = FileManager.default
        guard
            let enumerator = fm.enumerator(
                at: root,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
        else {
            return []
        }
        var results: [URL] = []
        for case let url as URL in enumerator {
            let values = try? url.resourceValues(forKeys: [.isDirectoryKey])
            if values?.isDirectory == true {
                results.append(url)
            }
        }
        return results
    }

    private func scheduleNotification() {
        pendingWork?.cancel()
        let onChange = onChange
        let work = DispatchWorkItem { [weak self] in
            onChange()
            self?.rebuildWatches()
        }
        pendingWork = work
        queue.asyncAfter(deadline: .now() + debounceInterval, execute: work)
    }
}
