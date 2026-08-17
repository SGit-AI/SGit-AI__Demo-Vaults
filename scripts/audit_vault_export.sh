#!/usr/bin/env bash
# Secret audit for a demo vault before publication.
#
# Usage:
#   scripts/audit_vault_export.sh <vault-clone-dir>              # audit a local sgit clone
#   scripts/audit_vault_export.sh <vault.zip>                    # audit an exported archive
#   scripts/audit_vault_export.sh <target> <read-key-hex>        # ALSO sweep full history
#
# With a read key, the audit decrypts EVERY object in bare/data and sweeps the
# decrypted plaintext. That matters because an archive carries every past commit:
# a credential removed from the working tree is still readable in history by anyone
# holding the read key we are about to publish. It also flags any `shared`-tier LLM
# config, where the provider key is stored in clear and is extractable by any opener
# (the `owner` tier seals it under a write-key-derived key, which a read key cannot
# reach). Verified against vault 4zf6pf2z, 2026-08-17.
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

# 6: full-history sweep — only possible with the read key, and it is the check that
# catches a secret that was committed once and deleted later.
READ_KEY="${2:-}"
if [[ -n "$READ_KEY" ]]; then
  BARE_DIR=$(find "$WORKDIR" -type d -name bare | head -1)
  if [[ -n "$BARE_DIR" ]]; then
    if WD="$BARE_DIR" RK="$READ_KEY" python3 - <<'PY'
import os,glob,json,re,sys
try:
    from cryptography.hazmat.primitives.ciphers.aead import AESGCM
except ImportError:
    print("    (python 'cryptography' missing — history sweep skipped)"); sys.exit(0)
a=AESGCM(bytes.fromhex(os.environ['RK']))
pats=re.compile(rb"sk-or-v1-[A-Za-z0-9]{10,}|sk-[A-Za-z0-9]{24,}|AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}"
                rb"|ghp_[A-Za-z0-9]{20,}|github_pat_|xox[baprs]-|-----BEGIN [A-Z ]*PRIVATE KEY"
                rb"|eyJ[A-Za-z0-9_-]{15,}\.[A-Za-z0-9_-]{15,}\.")
files=glob.glob(os.path.join(os.environ['WD'],'data','*'))
ok=bad=0; hits=[]; shared=[]
for f in files:
    try: b=open(f,'rb').read(); pt=a.decrypt(b[:12],b[12:],None); ok+=1
    except Exception: bad+=1; continue
    for m in pats.finditer(pt): hits.append((os.path.basename(f), m.group()[:16].decode('utf-8','replace')))
    if b'sg-llm-config' in pt or b'keyTier' in pt:
        try: d=json.loads(pt)
        except Exception: continue
        if d.get('keyTier')!='owner' or 'key' in d or 'apiKey' in d:
            shared.append((os.path.basename(f), d.get('keyTier')))
print("    history: %d objects, %d decrypted with the read key, %d opaque"%(len(files),ok,bad))
for f,s in hits[:10]: print("    HIT %s: %s…"%(f,s))
for f,t in shared: print("    SHARED-TIER LLM CONFIG %s (keyTier=%r) — provider key readable by any read-key holder"%(f,t))
sys.exit(1 if (hits or shared) else 0)
PY
    then ok "history sweep (all objects, all past commits)"
    else fail "credentials or a shared-tier key found in history"
    fi
  else
    note "history sweep" "SKIPPED — no bare/ found"
  fi
else
  note "history sweep" "not run (pass the read key as arg 2)"
fi

[[ -n "$CLEANUP" ]] && rm -rf "$CLEANUP"

echo
if [[ $FAIL -eq 0 ]]; then
  echo "RESULT: clean — proceed to human content review (PUBLISHING.md step 3b)"
else
  echo "RESULT: FAILED — do not publish. Fix, re-export, re-audit."
  exit 1
fi
