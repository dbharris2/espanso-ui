import Foundation

final class ConfigWatcher: @unchecked Sendable {
    private let directory: URL
    private let onChange: @Sendable () -> Void
    private let queue = DispatchQueue(label: "com.espansoui.config-watcher", qos: .utility)
    private let debounceInterval: DispatchTimeInterval

    // All mutable state below is only touched on `queue`.
    private var sources: [DispatchSourceFileSystemObject] = []
    private var pendingWork: DispatchWorkItem?
    private var isRunning = false

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
        pendingWork?.cancel()
        sources.forEach { $0.cancel() }
    }

    func start() {
        queue.async { [weak self] in
            guard let self, !self.isRunning else { return }
            self.isRunning = true
            self.rebuildWatches()
        }
    }

    func stop() {
        queue.async { [weak self] in
            guard let self, self.isRunning else { return }
            self.isRunning = false
            self.teardown()
        }
    }

    private func rebuildWatches() {
        teardown()
        guard isRunning else { return }
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
        pendingWork?.cancel()
        pendingWork = nil
        sources.forEach { $0.cancel() }
        sources.removeAll()
    }

    private func watch(_ url: URL) {
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else { return }

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
        guard isRunning else { return }
        pendingWork?.cancel()
        let onChange = onChange
        let work = DispatchWorkItem { [weak self] in
            guard self?.isRunning == true else { return }
            onChange()
            self?.rebuildWatches()
        }
        pendingWork = work
        queue.asyncAfter(deadline: .now() + debounceInterval, execute: work)
    }
}
