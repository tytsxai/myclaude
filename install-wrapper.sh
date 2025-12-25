#!/usr/bin/env bash
set -euo pipefail

# Preferred installer when running from the source repo:
# - If ./codeagent-wrapper exists and Go is available, build locally and install to $INSTALL_DIR/bin.
# - Otherwise fall back to the legacy download-based install.sh (used by GitHub Releases).

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${ROOT_DIR}/codeagent-wrapper"

INSTALL_DIR="${INSTALL_DIR:-$HOME/.claude}"
BIN_DIR="${INSTALL_DIR}/bin"
mkdir -p "${BIN_DIR}"

if [ -f "${SRC_DIR}/go.mod" ] && command -v go >/dev/null 2>&1; then
  echo "Building codeagent-wrapper from source..."
  (
    cd "${SRC_DIR}"
    go test ./... -short
    go build -ldflags="-s -w" -o "${BIN_DIR}/codeagent-wrapper" .
  )

  chmod +x "${BIN_DIR}/codeagent-wrapper"
  if "${BIN_DIR}/codeagent-wrapper" --version >/dev/null 2>&1; then
    echo "codeagent-wrapper installed successfully to ${BIN_DIR}/codeagent-wrapper"
  else
    echo "WARNING: installed binary did not respond to --version" >&2
  fi

  if [[ ":$PATH:" != *":${BIN_DIR}:"* ]]; then
    echo ""
    echo "WARNING: ${BIN_DIR} is not in your PATH"
    echo "Add this line to your ~/.bashrc or ~/.zshrc (then restart your shell):"
    echo ""
    echo "    export PATH=\"${BIN_DIR}:\$PATH\""
    echo ""
  fi

  exit 0
fi

echo "Go source build not available; falling back to legacy download installer..."
exec bash "${ROOT_DIR}/install.sh"

