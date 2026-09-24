# Repository Guidelines

This file guides coding agents contributing to the repository. Keep human installation and usage instructions in `README.md`.

## Project Structure & Module Organization

`bin/codex-profile` is the Python installer. `templates/<oss_provider>/` holds one provider's `config.toml.in` and `model-catalog.json`; the current template is `templates/lmstudio/`. `tests/test_installer.py` contains installer tests. `Makefile` exposes common commands. Keep `README.md` focused on human setup and usage; put implementation guidance here. Generated profiles belong in `$CODEX_HOME` or `~/.codex`, not in this repository.

## Build, Test, and Development Commands

This project has no build step or third-party runtime dependencies. Run `make list` to see available provider templates and `make test` to run the test suite. To install locally, use `make install PROFILE=qwen38 PROVIDER=lmstudio`; the provider defaults to `lmstudio`, while the profile name controls the generated filenames. Start Codex with `codex --profile qwen38`. For safe manual checks, set `CODEX_HOME` to a temporary directory before installing. Use `python3 bin/codex-profile install <name> --provider <provider> --force` only after reviewing existing files.

## Coding Style & Naming Conventions

Use four spaces for Python indentation and keep the installer compatible with its standard-library dependencies. Name tests `test_*` and use descriptive snake_case functions. Provider template directories match `oss_provider` values. Profile names start with a lowercase letter and contain only lowercase letters, digits, underscores, or hyphens. Keep `model` and `model_provider` explicit in each config template; `oss_provider` only selects the service when `--oss` is used. Use `{{MODEL_CATALOG_JSON}}` for the machine-specific catalog path. No formatter or linter is configured.

## Testing Guidelines

Tests use `unittest`; run them with `make test`. Cover new provider templates, custom profile names, generated paths, idempotent installs, and refusal to overwrite differing files. Use temporary `HOME` or `CODEX_HOME` values so tests never modify a contributor's Codex settings. Validate generated TOML and JSON when changing templates.

## Commit & Pull Request Guidelines

This repository has no commits yet, so there is no established commit-message convention. Use a short imperative summary, such as `Add Ollama profile template`. Pull requests should describe the template or installer behavior changed, show the commands run, and note any effect on existing installed profiles. Include screenshots only for user-interface changes.
