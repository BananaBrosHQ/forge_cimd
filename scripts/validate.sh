#!/usr/bin/env bash
# Local + remote checks for the Forge CIMD document.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/public/oauth/client-metadata.json"

python3 - "$FILE" "${1:-}" <<'PY'
import json, sys, urllib.request
from pathlib import Path

path = Path(sys.argv[1])
remote = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2] else None

def check(doc: dict, source: str, expect_client_id: str | None = None) -> None:
    required = ["client_id", "client_name", "redirect_uris"]
    missing = [k for k in required if k not in doc]
    if missing:
        raise SystemExit(f"{source}: missing fields {missing}")

    cid = doc["client_id"]
    if not isinstance(cid, str) or not cid.startswith("https://"):
        raise SystemExit(f"{source}: client_id must be an https URL")
    # Must include a path component (CIMD rule)
    rest = cid[len("https://") :]
    if "/" not in rest or rest.endswith("/"):
        raise SystemExit(f"{source}: client_id must be https://host/path (with a path)")

    if "REPLACE_WITH_YOUR_HOST" in cid:
        print(f"warn: {source} still has placeholder host — run scripts/apply-base-url.sh")

    uris = doc["redirect_uris"]
    if not isinstance(uris, list) or not uris:
        raise SystemExit(f"{source}: redirect_uris must be a non-empty list")

    for u in uris:
        ok = (
            u.startswith("http://localhost")
            or u.startswith("http://127.0.0.1")
            or u.startswith("http://[::1]")
            or u.startswith("https://")
        )
        if not ok:
            raise SystemExit(f"{source}: unsupported redirect_uri {u!r}")

    if doc.get("token_endpoint_auth_method") not in (None, "none"):
        raise SystemExit(
            f"{source}: public MCP clients should use token_endpoint_auth_method=none"
        )

    if expect_client_id is not None and cid != expect_client_id:
        raise SystemExit(
            f"{source}: client_id must equal fetch URL exactly\n"
            f"  document={cid}\n"
            f"  fetched ={expect_client_id}"
        )

    print(f"ok: {source}")
    print(f"  client_name = {doc.get('client_name')}")
    print(f"  client_id   = {cid}")
    print(f"  redirects   = {len(uris)}")

doc = json.loads(path.read_text(encoding="utf-8"))
check(doc, str(path))

if remote:
    url = remote.rstrip("/")
    if not url.endswith(".json"):
        url = f"{url}/oauth/client-metadata.json"
    with urllib.request.urlopen(url, timeout=20) as resp:
        body = resp.read()
        ctype = resp.headers.get("Content-Type", "")
        remote_doc = json.loads(body)
    check(remote_doc, url, expect_client_id=url)
    if "json" not in ctype and "text/plain" not in ctype:
        print(f"warn: Content-Type is {ctype!r} (prefer application/json)")
    print("remote CIMD looks good")
PY
