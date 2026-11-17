#!/usr/bin/env bash
# Render public/oauth/client-metadata.json from the template with a real HTTPS base URL.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE="$ROOT/templates/client-metadata.json"
OUT="$ROOT/public/oauth/client-metadata.json"

usage() {
  cat <<EOF
Usage: $(basename "$0") <https-base-url>

Example:
  $(basename "$0") https://forge-cimd.vercel.app
  $(basename "$0") https://cimd.forgelabs.dev

The base URL must be https, with no trailing slash.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -lt 1 ]]; then
  usage
  exit 0
fi

BASE="${1%/}"

if [[ ! "$BASE" =~ ^https:// ]]; then
  echo "error: base URL must start with https://" >&2
  exit 1
fi

if [[ "$BASE" =~ /$ ]]; then
  echo "error: do not include a trailing slash" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT")"
# Portable replace without requiring GNU sed
python3 - "$TEMPLATE" "$OUT" "$BASE" <<'PY'
import sys
from pathlib import Path

template, out, base = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3]
text = template.read_text(encoding="utf-8").replace("__BASE_URL__", base)
# Drop empty contacts array noise is fine; keep optional policy/tos URLs.
out.write_text(text, encoding="utf-8")
print(f"Wrote {out}")
print(f"client_id → {base}/oauth/client-metadata.json")
PY

echo
echo "Next:"
echo "  1. Deploy this folder (e.g. vercel --prod)"
echo "  2. export MCP_OAUTH_CLIENT_METADATA_URL=\"$BASE/oauth/client-metadata.json\""
echo "  3. Re-auth Vercel / other MCP servers in Forge"
