# Publishing a read-only demo vault

The per-vault runbook. Designed as a **submission queue**: the human supplies only what
a human knows; the publishing agent derives everything else by opening the vault with the
read key it was just given. Getting a vault into the queue should take under a minute;
the agent does the rest.

```
   WHAT THE HUMAN SUPPLIES              WHAT THE AGENT DERIVES
   read key                             file listing and structure
   one line: what it is for             object count, size, commit count
   shape tag                            last-updated date
   evidence status                      whether an app (index.html) is present
   copy or reference                    whether it renders in the browser
   write-key status                     archive sha256, vault README
```

## Step 0 — Intake (human, < 1 minute)

Append one file to `catalogue/pending/`:

```
catalogue/pending/<slug>.md
```

```markdown
read_key: <the read key>
one_line: <what this vault is for>
shape: gallery | report | structured-analysis | multi-agent | record-keeping | application
evidence_status: production | demonstration | sketch
copy_or_reference: copy | reference
write_key_status: escrowed | lost
```

Nothing else. The four non-derivable fields (shape, evidence status, copy/reference,
write-key status) are captured at submission because getting them later is much harder.

## Step 1 — Precondition: the write key is settled

- `escrowed`: the write key is in the secret manager / admin vault (**never** this repo).
- `lost`: the vault will be published **frozen** — readable forever, never correctable.
  This is a deliberate decision, recorded in the manifest and shown in the catalogue,
  not a default.

**Do not proceed past this step until the status is true.** Escrow before publishing is
a precondition, not good practice: publication is permanent.

## Step 2 — Clone and derive (agent)

```bash
pip install sgit-ai
sgit clone <read-key>        # read-only clone; no credential beyond the read key
```

Derive: file listing, structure, total size, commit count (`sgit log`), last-updated,
presence of `index.html` (vault app). This becomes `vaults/<slug>/README.md`.

## Step 3 — Secret audit (agent + human)

Two layers, both mandatory. **A published vault cannot be corrected** — if something
should not be public, this is the last exit.

**3a. Mechanical audit** — run `scripts/audit_vault_export.sh <clone-dir>`:

- no `.sg_vault/local/` tier present in anything that will be archived
  (`vault_key`, `token`, `key-rnd-*.pem`, `config.json`)
- no unwrapped key material anywhere (`BEGIN PRIVATE KEY`)
- no credential patterns in the plaintext working tree
  (`api_key`, `secret`, `password`, `bearer `, vault-key-shaped strings)
- `bare/` is fully opaque: no greppable filenames, paths, or content

**3b. Human content review** — the mechanical sweep cannot judge meaning. Read the
working tree as a stranger would: names, addresses, internal hostnames, screenshots
with credentials in them, anything told in confidence. Demo vaults are public forever.

Record the audit date, result, and reviewer in the manifest.

## Step 4 — Export the archive

```bash
sgit vault backup          # sgit-ai v0.15.0; prints the zip path and its sha256
```

**Never use `--include-key`** — it embeds a `VAULT-KEY` file in the zip, which this
repo must never hold.

Verified layout (pilot run, sgit-ai v0.15.0, 2026-08-16): the zip root contains
`bare/**` (the encrypted store: data, refs, indexes, keys, branches, pending),
`local/config.json` (mode metadata only in a read-only clone — the audit script fails
the zip if anything key-shaped is inside it), and sgit's own `manifest.json`.
Rename/copy the zip to `vaults/<slug>/vault.zip` and record the printed sha256.

Run the audit script against the zip as well as the clone.

## Step 5 — Commit

```
vaults/<slug>/vault.zip
vaults/<slug>/manifest.json     (see vaults/README.md for the schema)
vaults/<slug>/README.md
```

- Update `catalogue/index.md` with the new row.
- Delete `catalogue/pending/<slug>.md` in the same commit.
- Commit message: `publish vault: <slug> (<shape>, <evidence_status>)`.

## Step 6 — Deploy and verify

Follow `docs/DEPLOYMENT.md`. The entry is not done until the vault has been opened
in a browser **from the deployed copy** using only the published read key.

Then set `last_verified` in the manifest.

## Republishing

Because only read keys are needed, the whole estate can be redeployed at any time —
weekly, or on every commit — from this repo alone. See `docs/DEPLOYMENT.md` §
"Republish everything".

## Replacing a vault

Published vaults are immutable. To "update" one:

1. Create the new vault (new keys), publish it via this runbook under a new slug or a
   version-suffixed slug.
2. Mark the old catalogue row `superseded by <new-slug>` — do not delete it; anyone
   holding the old read key still has a working copy, and the row should say what it is.
