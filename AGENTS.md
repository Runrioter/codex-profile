# Repository Guidelines

This file guides coding agents contributing to the repository. Keep human installation and usage instructions in `README.md`.

## Language Rule

Use English throughout this repository. This applies to `README.md`, other documentation, source code, comments, tests, template text, CLI messages, and commit or pull request text. Do not add Chinese text or parallel translated documentation. Before finishing a change, run `rg -n '\p{Han}' .` and resolve every match in tracked project files.

## Project Structure & Module Organization

`Package.swift` defines the Swift executable target. `Sources/Codexp/` contains the `codexp` CLI and profile storage logic. `templates/<oss_provider>/` holds one provider's `config.toml.in` and `model-catalog.json`; SwiftPM bundles these resources into the executable product. `tests/CodexpTests/` contains XCTest coverage. Keep `README.md` focused on human setup and usage; put implementation guidance here. Generated profiles belong in `$CODEX_HOME` or `~/.codex`, not in this repository.

## Build, Test, and Development Commands

Run `make build` for a release build, `make test` for XCTest, and `make install PREFIX=<directory>` to install the binary and its resource bundle. The CLI supports `codexp list`, `codexp create <name>`, and `codexp remove <name>`; `create` also accepts `--provider` and `--force`. Start Codex with `codex --profile <name>`. Set `CODEX_HOME` to a temporary directory for manual checks. The package has no third-party dependencies.

## Coding Style & Naming Conventions

Use four spaces for Swift indentation and standard Foundation APIs. Name XCTest methods `test...` and use lowerCamelCase for Swift declarations. Provider template directories match `oss_provider` values. Profile names start with a lowercase letter and contain only lowercase letters, digits, underscores, or hyphens. Keep `model` and `model_provider` explicit in each config template; `oss_provider` only selects the service when `--oss` is used. Use `{{MODEL_CATALOG_JSON}}` for the machine-specific catalog path. No formatter or linter is configured.

## Testing Guidelines

Tests use XCTest; run them with `make test`. Cover installed-profile listing, custom names, generated paths, idempotent creation, overwrite protection, and safe removal. Use temporary directories so tests never modify a contributor's Codex settings. Validate generated TOML and JSON when changing templates.

## Commit & Pull Request Guidelines

The initial commit uses a short imperative summary; continue that style, for example `Add Ollama profile template`. Pull requests should describe the template or CLI behavior changed, show the commands run, and note any effect on existing installed profiles. Include screenshots only for user-interface changes.
