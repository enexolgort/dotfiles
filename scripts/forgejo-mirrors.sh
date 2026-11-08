#!/usr/bin/env bash
# forgejo-mirrors.sh — run on the host that runs Forgejo (mnemosyne).
#
# Creates pull mirrors in Forgejo of the GitHub repos below (all public,
# so no GitHub token needed). Forgejo re-syncs each mirror every 8h; you
# can also hit "Synchronize now" on the repo page. Safe to re-run:
# repos that already exist are skipped.
#
# Auth: generates a Forgejo access token for the admin user with the
# forgejo CLI (as the forgejo system user, so sudo asks for your
# password once) — your Forgejo password is never typed or stored. The
# token only has repository scope; delete it afterwards in Forgejo under
# Settings → Applications if you like (it's named "mirrors-<timestamp>").

set -euo pipefail

FORGEJO_URL="${FORGEJO_URL:-http://localhost:3000}"
FORGEJO_USER="${FORGEJO_USER:-gituser}"   # gitAdminUser in hosts/<host>/vars.nix

REPOS=(
  https://github.com/enexolgort/yt-dlp-API
  https://github.com/enexolgort/yt-dlp-webUi
  https://github.com/enexolgort/transmission-API
  https://github.com/enexolgort/transmission-webUi
  https://github.com/enexolgort/dotfiles
)

if ! systemctl is-active --quiet forgejo; then
  echo "!! forgejo.service isn't running on this host — run this on mnemosyne after the rebuild." >&2
  exit 1
fi

# The forgejo binary and its environment (FORGEJO_WORK_DIR etc.) exactly
# as the service runs them.
BIN="$(systemctl show forgejo -p ExecStart --value | grep -o 'path=[^ ;]*' | head -n1 | cut -d= -f2)"
mapfile -t ENVV < <(systemctl show forgejo -p Environment --value | tr ' ' '\n' | grep -v '^$')
WORKDIR="$(systemctl show forgejo -p WorkingDirectory --value)"

echo "==> Creating an access token for $FORGEJO_USER (sudo may ask for your password)"
TOKEN="$(cd / && sudo -u forgejo env "${ENVV[@]}" sh -c 'cd "$1" && shift && exec "$@"' _ "$WORKDIR" \
  "$BIN" admin user generate-access-token \
    --username "$FORGEJO_USER" --token-name "mirrors-$(date +%s)" \
    --scopes write:repository --raw | tail -n1)"
[ -n "$TOKEN" ] || { echo "!! couldn't create a token" >&2; exit 1; }

for url in "${REPOS[@]}"; do
  name="$(basename "$url")"
  code="$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: token $TOKEN" \
    "$FORGEJO_URL/api/v1/repos/$FORGEJO_USER/$name")"
  if [ "$code" = 200 ]; then
    echo "==> $name already exists, skipping"
    continue
  fi
  echo "==> Mirroring $url"
  body="$(printf '{"clone_addr":"%s","repo_name":"%s","repo_owner":"%s","mirror":true,"mirror_interval":"8h0m0s","service":"git","private":false,"description":"Mirror of %s"}' \
    "$url" "$name" "$FORGEJO_USER" "$url")"
  resp="$(curl -s -w '\n%{http_code}' -X POST "$FORGEJO_URL/api/v1/repos/migrate" \
    -H "Authorization: token $TOKEN" -H "Content-Type: application/json" -d "$body")"
  status="$(printf '%s' "$resp" | tail -n1)"
  if [ "$status" = 201 ]; then
    echo "    ok -> $FORGEJO_URL/$FORGEJO_USER/$name"
  else
    echo "!! $name failed (HTTP $status): $(printf '%s' "$resp" | head -n -1 | cut -c1-300)" >&2
  fi
done

unset TOKEN
echo "==> Done. Mirrors sync every 8h (repo page → Settings → Mirror settings to change)."
