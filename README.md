# Codex Profiles

`codexp` 是管理 Codex profile 的 Swift 命令行工具。当前内置 LM Studio 模版，预设模型为 `qwen/qwen3.8-27b`。

## 准备与安装

安装 Codex CLI、Swift 6 和 `make`。在 LM Studio 中下载并加载该模型，启动本地 API 服务。在本仓库运行：

```sh
make install
```

命令会将 `codexp` 安装到 `~/.local/bin`。如果这个目录尚未加入 `PATH`，请将它加入 shell 配置；也可以用 `make install PREFIX=/自定义目录` 指定安装位置。

## 管理 profile

```sh
codexp create qwen38
codexp list
codex --profile qwen38
codexp remove qwen38
```

`create` 使用 LM Studio 模版创建任意合法名称，例如 `codexp create local-qwen`。添加其他提供者模版后，可用 `codexp create local-model --provider <提供者名>` 选择。`list` 列出 Codex 目录中所有已安装的 profile，包括手工创建的 profile。

配置默认保存在 `~/.codex`，设置 `$CODEX_HOME` 时使用该目录。`create` 遇到内容不同的已有文件会停止；检查后可加 `--force` 替换。`remove` 删除指定 profile 的配置文件；仅当其专属模型目录文件被该 profile 引用且没有其他 profile 共用时，才会一并删除。

本 README 面向使用者；供 coding agents 遵循的开发约定见 [AGENTS.md](AGENTS.md)。
