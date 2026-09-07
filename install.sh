#!/bin/sh
# nxm-memory installer
#
#   curl -fsSL https://raw.githubusercontent.com/dangranaz/nxm-memory/main/install.sh | sh
#
# Detects your OS/arch, downloads the matching nxm-mcp-server binary from the
# public GitHub release, verifies its SHA-256, and installs it to ~/.local/bin.
#
# The embedding model (~200 MB) and the ONNX Runtime library are NOT bundled:
# the binary downloads them automatically on first run. So this installer only
# ever fetches a small (~15 MB) binary.
#
# Supported platforms: macOS arm64 (Apple Silicon), Linux x86_64.
#
# Overrides (env vars):
#   NXM_REPO      distribution repo         (default: dangranaz/nxm-memory)
#   NXM_VERSION   release tag or "latest"   (default: latest)
#   NXM_BIN_DIR   install dir               (default: $HOME/.local/bin)

set -eu

REPO="${NXM_REPO:-dangranaz/nxm-memory}"
VERSION="${NXM_VERSION:-latest}"
BIN_NAME="nxm-mcp-server"
BIN_DIR="${NXM_BIN_DIR:-$HOME/.local/bin}"

say() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
err() { printf '\033[1;31mERROR:\033[0m %s\n' "$1" >&2; exit 1; }

# --- detect os/arch → release asset label ---------------------------------
os="$(uname -s)"
arch="$(uname -m)"
case "$os-$arch" in
  Darwin-arm64|Darwin-aarch64) LABEL="macos-arm64" ;;
  Linux-x86_64)                LABEL="linux-x64" ;;
  *) err "unsupported platform: $os-$arch (supported: macOS arm64, Linux x86_64)" ;;
esac
say "platform: $LABEL"

ASSET="nxm-memory-${LABEL}.tar.gz"
if [ "$VERSION" = "latest" ]; then
  BASE="https://github.com/$REPO/releases/latest/download"
else
  BASE="https://github.com/$REPO/releases/download/$VERSION"
fi
URL="$BASE/$ASSET"

# --- download --------------------------------------------------------------
command -v curl >/dev/null 2>&1 || err "curl is required"
command -v tar  >/dev/null 2>&1 || err "tar is required"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

say "downloading $URL"
if ! curl -fsSL "$URL" -o "$TMP/pkg.tar.gz"; then
  err "download failed — the release/asset may not exist yet ($REPO $VERSION $ASSET)"
fi

# --- verify checksum (best-effort: sidecar .sha256 published next to asset) -
if curl -fsSL "$URL.sha256" -o "$TMP/pkg.sha256" 2>/dev/null; then
  expected="$(cat "$TMP/pkg.sha256" | tr -d '[:space:]')"
  if command -v shasum >/dev/null 2>&1; then
    got="$(shasum -a 256 "$TMP/pkg.tar.gz" | awk '{print $1}')"
  else
    got="$(sha256sum "$TMP/pkg.tar.gz" | awk '{print $1}')"
  fi
  if [ "$expected" != "$got" ]; then
    err "checksum mismatch: expected $expected, got $got"
  fi
  say "checksum verified"
else
  say "no checksum sidecar found — skipping verification"
fi

# --- stop a running server before replacing the binary --------------------
# The daemon binds the fixed port 7169 (single-owner policy). Overwriting the
# binary while it runs leaves the OLD version live until it is restarted, so we
# stop it first and tell the user. Port 7169 is the version-independent signal
# that an instance is active.
NXM_PORT=7169
port_in_use() {
  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -iTCP:"$NXM_PORT" -sTCP:LISTEN >/dev/null 2>&1
  elif command -v nc >/dev/null 2>&1; then
    nc -z 127.0.0.1 "$NXM_PORT" >/dev/null 2>&1
  else
    return 1  # can't tell — assume free
  fi
}

if port_in_use; then
  say "a nxm-memory server is running on port $NXM_PORT — stopping it before update"
  if [ -x "$BIN_DIR/$BIN_NAME" ]; then
    "$BIN_DIR/$BIN_NAME" --stop >/dev/null 2>&1 || true
  elif command -v "$BIN_NAME" >/dev/null 2>&1; then
    "$BIN_NAME" --stop >/dev/null 2>&1 || true
  fi
  # Give it a moment to release the port.
  i=0
  while port_in_use && [ "$i" -lt 10 ]; do sleep 1; i=$((i + 1)); done
  if port_in_use; then
    err "could not stop the running server on port $NXM_PORT.
   Stop it manually, then re-run the installer:
     $BIN_NAME --stop        # or: nxm-memory-stop.sh"
  fi
  say "server stopped"
  NXM_WAS_RUNNING=1
fi

# --- unpack + install ------------------------------------------------------
say "unpacking"
tar -C "$TMP" -xzf "$TMP/pkg.tar.gz"
[ -f "$TMP/$BIN_NAME" ] || err "binary $BIN_NAME not found in archive"

mkdir -p "$BIN_DIR"
install -m 0755 "$TMP/$BIN_NAME" "$BIN_DIR/$BIN_NAME" 2>/dev/null \
  || { cp "$TMP/$BIN_NAME" "$BIN_DIR/$BIN_NAME" && chmod 0755 "$BIN_DIR/$BIN_NAME"; }
say "installed → $BIN_DIR/$BIN_NAME"

# --- PATH hint -------------------------------------------------------------
case ":$PATH:" in
  *":$BIN_DIR:"*) : ;;
  *) printf '\033[1;33mNOTE:\033[0m add %s to your PATH:\n  export PATH="%s:$PATH"\n' "$BIN_DIR" "$BIN_DIR" ;;
esac

say "done. First run downloads the embedding model (~200 MB) automatically."
if [ "${NXM_WAS_RUNNING:-0}" = "1" ]; then
  printf '\033[1;33mNOTE:\033[0m the previous server was stopped for the update — restart it:\n'
fi
printf '  Start a workspace:  %s --w <path-to-project> --port 7169\n' "$BIN_NAME"
