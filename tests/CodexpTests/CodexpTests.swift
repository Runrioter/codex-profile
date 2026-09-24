import XCTest
import Foundation
@testable import codexp

final class CodexpTests: XCTestCase {
    private func fixture() throws -> (URL, ProfileStore) {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let templates = ProfileStore.fromEnvironment().templates
        return (root, ProfileStore(codexHome: root.appendingPathComponent("codex"), templates: templates))
    }

    func testCreateAndListInstalledProfiles() throws {
        let (root, store) = try fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        XCTAssertTrue(try store.availableProviders().contains("lmstudio"))
        XCTAssertEqual(try store.create("local-qwen").count, 2)

        let config = try String(contentsOf: store.codexHome.appendingPathComponent("local-qwen.config.toml"), encoding: .utf8)
        XCTAssertTrue(config.contains("model = \"qwen/qwen3.8-27b\""))
        XCTAssertTrue(config.contains("model_provider = \"lmstudio\""))
        XCTAssertTrue(config.contains(store.codexHome.path + "/local-qwen-model-catalog.json"))
        let catalog = try Data(contentsOf: store.codexHome.appendingPathComponent("local-qwen-model-catalog.json"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: catalog) as? [String: Any])
        XCTAssertNotNil(json["models"])

        try "model = \"manual\"\n".write(to: store.codexHome.appendingPathComponent("manual.config.toml"), atomically: true, encoding: .utf8)
        try "model = \"manual\"\n".write(to: store.codexHome.appendingPathComponent("Legacy.Profile.config.toml"), atomically: true, encoding: .utf8)
        XCTAssertEqual(try store.list(), ["Legacy.Profile", "local-qwen", "manual"])
        XCTAssertEqual(try store.remove("Legacy.Profile").count, 1)
    }

    func testCreateIsIdempotentAndProtectsDifferentFiles() throws {
        let (root, store) = try fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        try store.create("qwen38")
        XCTAssertTrue(try store.create("qwen38").isEmpty)
        let configURL = store.codexHome.appendingPathComponent("qwen38.config.toml")
        try "custom\n".write(to: configURL, atomically: true, encoding: .utf8)
        XCTAssertThrowsError(try store.create("qwen38"))
        XCTAssertEqual(try String(contentsOf: configURL, encoding: .utf8), "custom\n")
        XCTAssertEqual(try store.create("qwen38", force: true).count, 1)
    }

    func testRemoveDeletesProfileAndOwnedCatalog() throws {
        let (root, store) = try fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        try store.create("qwen38")
        XCTAssertEqual(try store.remove("qwen38").count, 2)
        XCTAssertEqual(try store.list(), [])
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.codexHome.appendingPathComponent("qwen38-model-catalog.json").path))
    }

    func testRemovePreservesUnreferencedAndSharedCatalogs() throws {
        let (root, store) = try fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        try store.create("first")
        let catalog = store.codexHome.appendingPathComponent("first-model-catalog.json")
        let second = store.codexHome.appendingPathComponent("second.config.toml")
        try "model_catalog_json = \"\(catalog.path)\"\n".write(to: second, atomically: true, encoding: .utf8)
        XCTAssertEqual(try store.remove("first").count, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: catalog.path))

        let manualCatalog = store.codexHome.appendingPathComponent("manual-model-catalog.json")
        try Data("{}".utf8).write(to: manualCatalog)
        let manual = store.codexHome.appendingPathComponent("manual.config.toml")
        try "model = \"manual\"\n".write(to: manual, atomically: true, encoding: .utf8)
        XCTAssertEqual(try store.remove("manual").count, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: manualCatalog.path))
    }

    func testRejectsInvalidNamesAndUnknownProviders() throws {
        let (root, store) = try fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        XCTAssertThrowsError(try store.create("../other"))
        XCTAssertThrowsError(try store.create("Uppercase"))
        XCTAssertThrowsError(try store.create("good", provider: "missing"))
        XCTAssertThrowsError(try store.remove("missing"))
        XCTAssertThrowsError(try store.remove("../other"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.codexHome.path))
    }

    func testRefusesSymlinkTargets() throws {
        let (root, store) = try fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        try store.create("qwen38")
        let config = store.codexHome.appendingPathComponent("qwen38.config.toml")
        let other = root.appendingPathComponent("other.toml")
        try "safe\n".write(to: other, atomically: true, encoding: .utf8)
        try FileManager.default.removeItem(at: config)
        try FileManager.default.createSymbolicLink(at: config, withDestinationURL: other)
        XCTAssertThrowsError(try store.create("qwen38", force: true))
        XCTAssertThrowsError(try store.remove("qwen38"))
        XCTAssertEqual(try String(contentsOf: other, encoding: .utf8), "safe\n")
    }
}
