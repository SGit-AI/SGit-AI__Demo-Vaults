#!/usr/bin/env bash
# Secret audit for a demo vault before publication.
#
# Usage:
#   scripts/audit_vault_export.sh <vault-clone-dir>    # audit a local sgit clone
#   scripts/audit_vault_export.sh <vault.zip>          # audit an exported archive
#
# Publication is permanent (a published read key cannot be withdrawn), so every
# check must pass BEFORE anything is committed to this repo. This is the mechanical
# layer only — the human content review in docs/PUBLISHING.md step 3b is still required.
#
# Checks (from the audited boundary in PUBLISHING-SGIT-VAULT-TO-GITHUB.md):
#   1. no local credential tier (.sg_vault/local/): vault_key, token, key-rnd-*.pem, config.json
#   2. no scratch tier (.sg_vault/work/) — may hold plaintext transiently
#   3. no unwrapped key material anywhere (BEGIN PRIVATE KEY / *.pem)
#   4. no credential-pattern hits in the plaintext working tree
#   5. bare/ opaque: no readable well-known names in the encrypted store

set -u
TARGET="${1:?usage: audit_vault_export.sh <clone-dir|vault.zip>}"
FAIL=0
note() { printf '  %-60s %s\n' "$1" "$2"; }
fail() { note "$1" "LEAK"; FAIL=1; }
ok()   { note "$1" "OK"; }

WORKDIR="$TARGET"
CLEANUP=""
if [[ -f "$TARGET" && "$TARGET" == *.zip ]]; then
  WORKDIR="$(mktemp -d)"; CLEANUP="$WORKDIR"
  unzip -q "$TARGET" -d "$WORKDIR" || { echo "cannot unzip $TARGET"; exit 2; }
fi
[[ -d "$WORKDIR" ]] || { echo "no such directory: $WORKDIR"; exit 2; }

echo "auditing: $TARGET"

# 1+2: credential and scratch tiers must be absent.
# Note both layouts: a clone has .sg_vault/local/; a `sgit vault backup` zip
# has local/ at the ARCHIVE ROOT (verified on sgit-ai v0.15.0, 2026-08-16).
if find "$WORKDIR" -type d -path "*.sg_vault/work" | grep -q .; then
  fail "scratch tier present: .sg_vault/work"
else
  ok "no .sg_vault/work"
fi
for f in vault_key token VAULT-KEY; do
  if find "$WORKDIR" -type f -name "$f" | grep -q .; then
    fail "credential file present: $f"
  else
    ok "no $f file"
  fi
done
# local/ config: allowed ONLY if it carries no key material (a read-only clone's
# config holds just mode metadata; anything key-shaped fails).
while IFS= read -r cfg; do
  if grep -qiE '("passphrase"|"vault_key"|"token"|[0-9a-f]{64})' "$cfg"; then
    fail "key material inside $(echo "$cfg" | sed "s|$WORKDIR/||")"
  else
    ok "no key material in $(echo "$cfg" | sed "s|$WORKDIR/||")"
  fi
done < <(find "$WORKDIR" -type f -path "*local/*")

# 3: unwrapped key material
if grep -rl "BEGIN PRIVATE KEY" "$WORKDIR" 2>/dev/null | grep -q .; then
  fail "unwrapped private key material found"
else
  ok "no 'BEGIN PRIVATE KEY'"
fi
if find "$WORKDIR" -name "*.pem" | grep -q .; then
  fail "*.pem file present"
else
  ok "no *.pem files"
fi

# 4: credential patterns in the plaintext working tree (excluding the encrypted store)
HITS=$(grep -rniE "(api[_-]?key|passwd|password|secret[_-]?key|bearer |vault_key|push[_-]?token)" \
        "$WORKDIR" --exclude-dir=".sg_vault" --exclude-dir="bare" \
        --include="*.md" --include="*.json" --include="*.js" --include="*.html" \
        --include="*.txt" --include="*.yml" --include="*.yaml" 2>/dev/null)
if [[ -n "$HITS" ]]; then
  echo "$HITS" | sed 's/^/    /'
  fail "credential-pattern hits in working tree (review each above)"
else
  ok "no credential patterns in working tree"
fi

# 5: encrypted store must be opaque — well-known names should not be greppable
BARE=$(find "$WORKDIR" -type d -name bare -path "*sg_vault*" | head -1)
[[ -z "$BARE" ]] && BARE=$(find "$WORKDIR" -type d -name bare | head -1)
if [[ -n "$BARE" ]]; then
  if grep -rl -e "index.html" -e "content.json" -e "app.json" "$BARE" 2>/dev/null | grep -q .; then
    fail "bare/ contains readable structure or content"
  else
    ok "bare/ opaque (no well-known names greppable)"
  fi
else
  note "bare/ store" "NOT FOUND — wrong layout? verify export"
  FAIL=1
fi

[[ -n "$CLEANUP" ]] && rm -rf "$CLEANUP"

echo
if [[ $FAIL -eq 0 ]]; then
  echo "RESULT: clean — proceed to human content review (PUBLISHING.md step 3b)"
else
  echo "RESULT: FAILED — do not publish. Fix, re-export, re-audit."
  exit 1
fi
