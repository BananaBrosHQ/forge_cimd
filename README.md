# Forge CIMD

Hosted **Client ID Metadata Document** for Forge’s MCP OAuth client.

When Forge connects to Vercel MCP (or any MCP auth server that supports CIMD), the consent screen shows whatever this document advertises: **Forge**, your logo, and your hostname — not Claude Code.

## What you get

| Path | Purpose |
|------|---------|
| `/oauth/client-metadata.json` | CIMD (`client_id` = this URL) |
| `/forge-logo.png` | Consent-screen logo (PNG, &lt;100 KB) |
| `/` | Small landing page |
| `/policy`, `/terms` | Placeholder policy links |

Designed for **Vercel MCP** and other CIMD-capable providers (loopback redirects, public client, auth code + refresh).

## Quick start (Vercel)

```bash
cd /home/mega/Documents/forge_cimd

# 1) Deploy the static site (first deploy gets you a *.vercel.app URL)
npm run deploy
# or: npx vercel@latest ./public --prod

# 2) Stamp the real HTTPS base into the metadata (no trailing slash)
./scripts/apply-base-url.sh https://YOUR-PROJECT.vercel.app

# 3) Redeploy so the live JSON matches that URL exactly
npm run deploy

# 4) Sanity-check
./scripts/validate.sh https://YOUR-PROJECT.vercel.app
```

Then in Forge:

```bash
export MCP_OAUTH_CLIENT_METADATA_URL="https://YOUR-PROJECT.vercel.app/oauth/client-metadata.json"
```

Clear any old Vercel MCP OAuth tokens in Forge, reconnect, and the Allow Access page should say **Forge** with your hostname.

## Local preview

```bash
npm run dev
# → http://127.0.0.1:4173
```

Local HTTP is fine for viewing files. Auth servers will only accept an **https** `client_id`.

## Why the redirect URIs look port-less

Forge opens `http://localhost:<random-port>/callback`.  
RFC 8252 §7.3: authorization servers matching loopback redirects should ignore the port. Vercel MCP follows that (same pattern as Claude Code’s CIMD). Included:

- `http://localhost/callback`
- `http://127.0.0.1/callback`
- `http://[::1]/callback`

## Custom domain

```bash
./scripts/apply-base-url.sh https://cimd.yourdomain.com
npm run deploy
# point DNS / Vercel domain at this project
./scripts/validate.sh https://cimd.yourdomain.com
```

`client_id` inside the JSON must equal the fetch URL **byte-for-byte**.

## Wire into Forge permanently

Override (already supported):

```bash
export MCP_OAUTH_CLIENT_METADATA_URL="https://…/oauth/client-metadata.json"
```

Or change the default in Forge:

`lib/agent_orchestration/constants/oauth.dart` → `MCP_CLIENT_METADATA_URL`

## Optional: Vercel verified client

CIMD alone is enough for branding. To appear on Vercel’s supported-clients list with a verified badge, submit the [Vercel MCP client review](https://vercel.com/docs/agent-resources/vercel-mcp) using this same metadata URL.

## Replace placeholders

Edit `public/policy.html` and `public/terms.html` (and the logo under `public/`) before you treat this as production.
