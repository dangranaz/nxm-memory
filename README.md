# nxm-memory

Downloadable binaries + installer for the Nexum memory MCP server.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/dangranaz/nxm-memory/main/install.sh | sh
```

This downloads the `nxm-mcp-server` binary for your platform (macOS arm64 or Linux x86_64) into `~/.local/bin`. The embedding model (~200 MB) and the ONNX Runtime library are downloaded automatically by the binary on first run.

## Run

```sh
nxm-mcp-server --w <path-to-project> --port 7169
```

## Platforms

- macOS arm64 (Apple Silicon)
- Linux x86_64

Binaries are published as release assets. Source code is maintained privately.
