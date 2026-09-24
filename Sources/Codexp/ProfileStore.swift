import Foundation

struct ProfileError: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}

struct ProfileStore {
    let codexHome: URL
    let templates: URL
    private let files = FileManager.default

    init(codexHome: URL, templates: URL) {
        self.codexHome = codexHome.standardizedFileURL.resolvingSymlinksInPath()
        self.templates = templates.standardizedFileURL
    }

    static func fromEnvironment() -> ProfileStore {
        let environment = ProcessInfo.processInfo.environment
        let home = environment["HOME"].flatMap { $0.isEmpty ? nil : $0 }
            ?? FileManager.default.homeDirectoryForCurrentUser.path
        let configured = environment["CODEX_HOME"].flatMap { $0.isEmpty ? nil : $0 }
        let path: String
        if let configured {
            path = configured == "~" ? home
                : configured.hasPrefix("~/") ? home + String(configured.dropFirst()) : configured
        } else {
            path = home + "/.codex"
        }
        return ProfileStore(
            codexHome: URL(fileURLWithPath: path),
            templates: Bundle.module.resourceURL!.appendingPathComponent("templates", isDirectory: true)
        )
    }

    func list() throws -> [String] {
        guard files.fileExists(atPath: codexHome.path) else { return [] }
        return try files.contentsOfDirectory(at: codexHome, includingPropertiesForKeys: [.isDirectoryKey])
            .filter { $0.lastPathComponent.hasSuffix(".config.toml") }
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == false }
            .map { String($0.lastPathComponent.dropLast(".config.toml".count)) }
            .sorted()
    }

    func availableProviders() throws -> [String] {
        try files.contentsOfDirectory(at: templates, includingPropertiesForKeys: [.isDirectoryKey])
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
            .filter {
                files.fileExists(atPath: $0.appendingPathComponent("config.toml.in").path)
                    && files.fileExists(atPath: $0.appendingPathComponent("model-catalog.json").path)
            }
            .map(\.lastPathComponent)
            .sorted()
    }

    @discardableResult
    func create(_ name: String, provider: String = "lmstudio", force: Bool = false) throws -> [URL] {
        try validate(name)
        guard try availableProviders().contains(provider) else {
            throw ProfileError("Unknown provider '\(provider)'.")
        }

        let source = templates.appendingPathComponent(provider, isDirectory: true)
        let template = try String(contentsOf: source.appendingPathComponent("config.toml.in"), encoding: .utf8)
        let placeholder = "{{MODEL_CATALOG_JSON}}"
        guard template.components(separatedBy: placeholder).count == 2 else {
            throw ProfileError("The \(provider) template must contain exactly one \(placeholder).")
        }
        let catalog = try Data(contentsOf: source.appendingPathComponent("model-catalog.json"))
        _ = try JSONSerialization.jsonObject(with: catalog)

        let catalogURL = codexHome.appendingPathComponent("\(name)-model-catalog.json")
        let configURL = codexHome.appendingPathComponent("\(name).config.toml")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]
        let encodedPath = String(decoding: try encoder.encode(catalogURL.path), as: UTF8.self)
        let config = Data(template.replacingOccurrences(of: placeholder, with: encodedPath).utf8)
        let outputs: [(URL, Data)] = [(catalogURL, catalog), (configURL, config)]

        for (url, expected) in outputs {
            if isSymbolicLink(url) {
                throw ProfileError("Refusing to replace symbolic link: \(url.path)")
            }
            if files.fileExists(atPath: url.path), try Data(contentsOf: url) != expected, !force {
                throw ProfileError("Existing file differs: \(url.path). Review it before using --force.")
            }
        }

        try files.createDirectory(at: codexHome, withIntermediateDirectories: true)
        var changed: [URL] = []
        for (url, expected) in outputs {
            if files.fileExists(atPath: url.path), try Data(contentsOf: url) == expected { continue }
            try expected.write(to: url, options: .atomic)
            changed.append(url)
        }
        return changed
    }

    @discardableResult
    func remove(_ name: String) throws -> [URL] {
        guard !name.isEmpty, name != ".", name != "..",
              !name.contains("/"), !name.contains("\\"), !name.contains("\0") else {
            throw ProfileError("Profile name must be a single file name.")
        }
        let configURL = codexHome.appendingPathComponent("\(name).config.toml")
        guard files.fileExists(atPath: configURL.path) else {
            throw ProfileError("Profile '\(name)' does not exist.")
        }
        guard !isSymbolicLink(configURL) else {
            throw ProfileError("Refusing to remove symbolic link: \(configURL.path)")
        }

        let catalogURL = codexHome.appendingPathComponent("\(name)-model-catalog.json")
        let config = try String(contentsOf: configURL, encoding: .utf8)
        let ownsCatalog = catalogReference(in: config) == catalogURL.path
        if ownsCatalog, isSymbolicLink(catalogURL) {
            throw ProfileError("Refusing to remove symbolic link: \(catalogURL.path)")
        }
        var shared = false
        for other in try list().filter({ $0 != name }) {
            let path = codexHome.appendingPathComponent("\(other).config.toml")
            let contents = try String(contentsOf: path, encoding: .utf8)
            if catalogReference(in: contents) == catalogURL.path {
                shared = true
                break
            }
        }

        try files.removeItem(at: configURL)
        var removed = [configURL]
        if ownsCatalog, !shared, files.fileExists(atPath: catalogURL.path) {
            try files.removeItem(at: catalogURL)
            removed.append(catalogURL)
        }
        return removed
    }

    private func validate(_ name: String) throws {
        let scalars = Array(name.unicodeScalars)
        func isLetter(_ value: UInt32) -> Bool { (97...122).contains(value) }
        guard let first = scalars.first, isLetter(first.value),
              scalars.allSatisfy({ isLetter($0.value) || (48...57).contains($0.value) || $0.value == 45 || $0.value == 95 })
        else {
            throw ProfileError("Profile name must start with a lowercase letter and contain only lowercase letters, digits, _ or -.")
        }
    }

    private func isSymbolicLink(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) == true
    }

    private func catalogReference(in config: String) -> String? {
        for line in config.split(separator: "\n") {
            let parts = line.split(separator: "=", maxSplits: 1)
            guard parts.count == 2, parts[0].trimmingCharacters(in: .whitespaces) == "model_catalog_json" else { continue }
            let literal = parts[1].trimmingCharacters(in: .whitespaces)
            return try? JSONDecoder().decode(String.self, from: Data(literal.utf8))
        }
        return nil
    }
}
