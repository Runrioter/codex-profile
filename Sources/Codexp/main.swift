import Darwin
import Foundation

@main
struct Codexp {
    static let usage = """
        Usage:
          codexp list
          codexp create <profile-name> [--provider <provider>] [--force]
          codexp remove <profile-name>
        """

    static func main() {
        do {
            try run(Array(CommandLine.arguments.dropFirst()), store: .fromEnvironment())
        } catch {
            FileHandle.standardError.write(Data("Error: \(error)\n\n\(usage)\n".utf8))
            exit(1)
        }
    }

    static func run(_ arguments: [String], store: ProfileStore) throws {
        guard let command = arguments.first else { throw ProfileError("Missing command.") }
        switch command {
        case "--help", "-h", "help":
            print(usage)
        case "list":
            guard arguments.count == 1 else { throw ProfileError("list takes no arguments.") }
            for name in try store.list() { print(name) }
        case "create":
            guard arguments.count >= 2 else { throw ProfileError("create requires a profile name.") }
            let name = arguments[1]
            var provider = "lmstudio"
            var force = false
            var index = 2
            while index < arguments.count {
                switch arguments[index] {
                case "--provider":
                    guard index + 1 < arguments.count else { throw ProfileError("--provider requires a value.") }
                    provider = arguments[index + 1]
                    index += 2
                case "--force":
                    force = true
                    index += 1
                default:
                    throw ProfileError("Unknown option: \(arguments[index])")
                }
            }
            let changed = try store.create(name, provider: provider, force: force)
            print(changed.isEmpty ? "Profile is already up to date: \(name)" : "Created profile: \(name)")
            print("Use with: codex --profile \(name)")
        case "remove":
            guard arguments.count == 2 else { throw ProfileError("remove requires one profile name.") }
            let removed = try store.remove(arguments[1])
            print("Removed profile: \(arguments[1])")
            if removed.count == 1 { print("Catalog retained because it is absent, shared, or not owned by this profile.") }
        default:
            throw ProfileError("Unknown command: \(command)")
        }
    }
}
