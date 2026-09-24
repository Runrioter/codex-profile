# Codex Profiles

`codexp` is a Swift command-line tool for managing Codex profiles. Its bundled LM Studio template uses `qwen/qwen3.8-27b` by default.

## Requirements and Installation

Install the Codex CLI, Swift 6, and `make`. Download and load `qwen/qwen3.8-27b` in LM Studio, then start its local API server. From this repository, run:

```sh
make install
```

This installs `codexp` and its template resources in `~/.local/bin`. Add that directory to your `PATH` if needed, or choose another location with `make install PREFIX=/your/path`.

## Manage Profiles

```sh
codexp create qwen38
codexp list
codex --profile qwen38
codexp remove qwen38
```

`create` accepts a custom profile name, such as `local-qwen`, and uses the LM Studio template by default. If more provider templates are added, select one with `codexp create local-model --provider <provider>`. `list` shows every installed Codex profile, including profiles created manually.

Profiles are stored in `~/.codex`, or in `$CODEX_HOME` when it is set. `create` refuses to overwrite differing files; review them before adding `--force`. `remove` deletes the selected profile's configuration. It also deletes the profile-specific model catalog when that file is referenced by the profile and is not shared with another profile.

This README is for users. Coding agents should follow [AGENTS.md](AGENTS.md).
