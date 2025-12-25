#!/usr/bin/env bash
set -euo pipefail

# PostToolUse hook example.
#
# Claude Code may provide a JSON payload on stdin describing the tool call/result.
# This script intentionally stays fast and non-blocking: it never fails the session.

payload="$(cat 2>/dev/null || true)"
if [ -z "${payload}" ]; then
  exit 0
fi

# If the payload isn't valid JSON, do nothing.
python3 - <<'PY' 2>/dev/null || true
import json, sys

raw = sys.stdin.read()
try:
    data = json.loads(raw)
except Exception:
    sys.exit(0)

exit_code = data.get("exit_code")
tool = data.get("tool") or data.get("toolName") or data.get("name")

if isinstance(exit_code, int) and exit_code != 0:
    sys.stderr.write(f"[post-tool-check] tool={tool or 'unknown'} exit_code={exit_code}\n")
PY

exit 0
