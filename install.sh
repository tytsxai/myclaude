#!/bin/bash
set -euo pipefail

if [ -z "${SKIP_WARNING:-}" ]; then
  echo "⚠️  WARNING: install.sh is LEGACY and will be removed in future versions."
  echo "Please use the new installation method:"
  echo "  python3 install.py --install-dir ~/.claude"
  echo ""
  echo "Set SKIP_WARNING=1 to bypass this message"
  echo "Continuing with legacy installation in 5 seconds..."
  sleep 5
fi

# Detect platform
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# Normalize architecture names
case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

REPO="tytsxai/myclaude"
VERSION="${CODEAGENT_WRAPPER_VERSION:-latest}"
if [ "${VERSION}" != "latest" ] && [[ "${VERSION}" != v* ]]; then
  VERSION="v${VERSION}"
fi
BINARY_NAME="codeagent-wrapper-${OS}-${ARCH}"
URL="https://github.com/${REPO}/releases/${VERSION}/download/${BINARY_NAME}"

TMP_FILE="$(mktemp -t codeagent-wrapper.XXXXXX)"
cleanup_tmp() {
  rm -f "${TMP_FILE}"
}
trap cleanup_tmp EXIT

echo "Downloading codeagent-wrapper from ${URL}..."
if ! curl -fsSL "$URL" -o "${TMP_FILE}"; then
    echo "ERROR: failed to download binary" >&2
    exit 1
fi

if [ -n "${CODEAGENT_WRAPPER_SHA256:-}" ]; then
    if command -v sha256sum >/dev/null 2>&1; then
        echo "${CODEAGENT_WRAPPER_SHA256}  ${TMP_FILE}" | sha256sum -c -
    elif command -v shasum >/dev/null 2>&1; then
        echo "${CODEAGENT_WRAPPER_SHA256}  ${TMP_FILE}" | shasum -a 256 -c -
    else
        echo "WARNING: no sha256 tool found; skip checksum verification" >&2
    fi
fi

INSTALL_DIR="${INSTALL_DIR:-$HOME/.claude}"
BIN_DIR="${INSTALL_DIR}/bin"
mkdir -p "$BIN_DIR"

mv "${TMP_FILE}" "${BIN_DIR}/codeagent-wrapper"
chmod +x "${BIN_DIR}/codeagent-wrapper"

if "${BIN_DIR}/codeagent-wrapper" --version >/dev/null 2>&1; then
    echo "codeagent-wrapper installed successfully to ${BIN_DIR}/codeagent-wrapper"
else
    echo "ERROR: installation verification failed" >&2
    exit 1
fi

if [[ ":$PATH:" != *":${BIN_DIR}:"* ]]; then
    echo ""
    echo "WARNING: ${BIN_DIR} is not in your PATH"
    echo "Add this line to your ~/.bashrc or ~/.zshrc (then restart your shell):"
    echo ""
    echo "    export PATH=\"${BIN_DIR}:\$PATH\""
    echo ""
fi
