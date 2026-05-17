@testable import EspansoUI
import XCTest

final class EspansoLoaderTests: XCTestCase {
    private var tempDir: URL!
    private var matchDir: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("EspansoUITests-\(UUID().uuidString)")
        matchDir = tempDir.appendingPathComponent("match")
        try FileManager.default.createDirectory(at: matchDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
        try super.tearDownWithError()
    }

    func testLoadsPlainTriggerReplace() throws {
        try write(file: "base.yml", contents: """
        matches:
          - trigger: ":email"
            replace: "devon@example.com"
          - trigger: ":me"
            replace: "Devon"
        """)
        let matches = try EspansoLoader(configDirectory: tempDir).load()
        XCTAssertEqual(matches.count, 2)
        XCTAssertEqual(matches[0].triggers, [":email"])
        XCTAssertEqual(matches[0].replace, "devon@example.com")
        XCTAssertEqual(matches[1].primaryTrigger, ":me")
    }

    func testSupportsMultipleTriggers() throws {
        try write(file: "base.yml", contents: """
        matches:
          - triggers: [":hi", ":hello"]
            replace: "hello there"
        """)
        let matches = try EspansoLoader(configDirectory: tempDir).load()
        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches[0].triggers, [":hi", ":hello"])
    }

    func testDetectsImageReplace() throws {
        try write(file: "gifs.yml", contents: """
        matches:
          - trigger: ":cat"
            replace: '<img src="https://example.com/cat.gif"/>'
        """)
        let matches = try EspansoLoader(configDirectory: tempDir).load()
        XCTAssertEqual(matches.count, 1)
        XCTAssertTrue(matches[0].isImage)
        XCTAssertEqual(matches[0].imageURL?.absoluteString, "https://example.com/cat.gif")
    }

    func testImagePathFieldBecomesImage() throws {
        try write(file: "img.yml", contents: """
        matches:
          - trigger: ":logo"
            image_path: "/tmp/logo.png"
        """)
        let matches = try EspansoLoader(configDirectory: tempDir).load()
        XCTAssertEqual(matches.count, 1)
        XCTAssertTrue(matches[0].isImage)
    }

    func testSkipsEntriesWithoutTriggerOrReplace() throws {
        try write(file: "base.yml", contents: """
        matches:
          - replace: "no trigger"
          - trigger: ":nothing"
        """)
        let matches = try EspansoLoader(configDirectory: tempDir).load()
        XCTAssertEqual(matches.count, 0)
    }

    func testRecursesIntoSubdirectories() throws {
        let nested = matchDir.appendingPathComponent("packages/work")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        try write(file: "base.yml", contents: """
        matches:
          - trigger: ":a"
            replace: "A"
        """)
        let nestedYaml = nested.appendingPathComponent("snippets.yml")
        try """
        matches:
          - trigger: ":b"
            replace: "B"
        """.write(to: nestedYaml, atomically: true, encoding: .utf8)

        let matches = try EspansoLoader(configDirectory: tempDir).load()
        XCTAssertEqual(matches.count, 2)
        XCTAssertEqual(Set(matches.map(\.primaryTrigger)), [":a", ":b"])
    }

    func testThrowsWhenMatchDirectoryMissing() {
        let empty = tempDir.appendingPathComponent("does-not-exist")
        XCTAssertThrowsError(try EspansoLoader(configDirectory: empty).load()) { error in
            guard case EspansoLoaderError.configDirectoryMissing = error else {
                XCTFail("Expected configDirectoryMissing, got \(error)")
                return
            }
        }
    }

    private func write(file: String, contents: String) throws {
        let url = matchDir.appendingPathComponent(file)
        try contents.write(to: url, atomically: true, encoding: .utf8)
    }
}
