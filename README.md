# Codex Profiles

在新电脑上快速安装 Codex 的本地模型 profile。当前提供 LM Studio 模版，预设模型为 `qwen/qwen3.8-27b`；`qwen38` 是可自定义的 profile 名称。

## 使用前准备

- 安装 Codex CLI、Python 3 和 `make`。
- 在 LM Studio 中下载并加载 `qwen/qwen3.8-27b`，启动本地 API 服务。

## 安装与启动

在仓库根目录运行：

```sh
make install PROFILE=qwen38
codex --profile qwen38
```

安装后可在 Codex 的 `/status` 中核对模型和提供者是否分别为 `qwen/qwen3.8-27b` 与 `lmstudio`。日常启动只需 `--profile`，无需再添加 `--oss` 或 `-m`。

想使用其他 profile 名称，可以运行 `make install PROFILE=local-qwen`，之后用 `codex --profile local-qwen` 启动。运行 `make list` 可查看可用的提供者模版；选择其他模版时指定 `PROVIDER`，例如 `make install PROFILE=my-model PROVIDER=lmstudio`。

安装文件默认写入当前用户的 `~/.codex`；设置了 `$CODEX_HOME` 时写入该目录。安装器会自动生成适用于当前电脑的模型目录路径。如果目标文件与模版内容不同，安装会停止并列出冲突文件。请先检查现有配置；确认要替换后，再运行 `python3 bin/codex-profile install qwen38 --provider lmstudio --force`。

本 README 面向使用者；供 coding agents 遵循的开发与模版维护约定见 [AGENTS.md](AGENTS.md)。
