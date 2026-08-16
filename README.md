# SGit-AI — Demo Vaults

The public, git-backed store for **read-only demo vaults**: sgit vaults published as
archives of their encrypted `bare/` store, deployable to any server, browsable by anyone
holding the published **read key**.

This repo is the inventory answer to vault sprawl: vaults accumulate faster than they can
be managed, and each one lives in its own environment. Here they get one canonical,
versioned, replicable home.

## The model

```
                     THIS REPO (public git)
   vault (live) ──sgit export──▶ vaults/<slug>/vault.zip     (encrypted bare/ store)
                                 vaults/<slug>/manifest.json (metadata + read key)
                                 catalogue/index.md          (the read-key catalogue)
                                        │
                                        └──deploy──▶ any server / static host / air-gap
                                                     (path-mirror the bare/ tree)
                                                            │
                                                     browser + read key
                                                     = decrypts client-side
```

Three properties make this work:

1. **The `bare/` store is designed to live in public locations.** Every object in it is
   ciphertext protected by the key, not by where it sits. Git exposure of `bare/` is
   equivalent to server exposure, which the zero-knowledge model already accepts. A git
   repo is just a second untrusted server — one that gives distribution, replication and
   history for free.
2. **Reads need no backend.** Opening a vault is deterministic GETs against the `bare/`
   tree (file IDs are computed client-side from the key — no listing, no manifest). Any
   static file host that path-mirrors the tree serves the vault. Writes are simply not
   possible without the write key, which this repo never holds.
3. **Only the read key is needed.** These are demo vaults: read-only by design. The read
   key is one-way derived from the vault (write) key and cannot be converted back. To
   "edit" a published demo vault, you publish a new one and update the catalogue.

This means the entire estate can be republished to a fresh server — including an
air-gapped one — from a `git clone` of this repo alone, as often as weekly or on every
change.

## Hard rules

| # | Rule |
|---|------|
| 1 | **Read keys yes, write keys never.** The catalogue lists read keys — a public vault's read key is published by definition. Vault (write) keys, push tokens, and the `.sg_vault/local/` tier must NEVER appear in this repo, in any file, commit message, or issue. |
| 2 | **Escrow before publishing.** A vault whose write key is lost is *frozen*: readable forever, never updatable, never correctable, never revocable. Escrow the write key (secret manager or unpublished admin vault — never here) **before** the vault is published, and record the status (`escrowed` / `lost`) in its manifest. |
| 3 | **Secret audit before commit.** Every archive passes `scripts/audit_vault_export.sh` and a human content review before it lands. Publishing here is permanent: a published read key cannot be withdrawn, and anyone who fetched keeps a working copy. |
| 4 | **Evidence status stated per vault.** `production`, `demonstration`, or `sketch` — a reader who cannot tell will guess wrong. |
| 5 | **Frozen vaults are marked publicly.** A reader deserves to know an entry will never be corrected. |
| 6 | **Sort by shape, not domain.** Gallery, report, structured analysis, multi-agent collaboration, record-keeping, application. Healthcare is an instance of a shape, not a shape. |

## Repo layout

```
demo-vault/           ← itself an sgit vault (id 2a8d3n2z, read key published; write
  index.html            key held out-of-band by the project lead, NEVER in this repo)
  app.json              the Demo Vaults catalogue app (a vault app)
  catalogue.json        the machine-readable read-key catalogue
  vaults/<slug>/        each published demo vault: vault.zip (encrypted bare/ store)
                        + manifest.json — stored in git AND in the vault (deliberate
                        duplication experiment: git and sgit each version the estate)
  .sg_vault/bare/       the vault's own encrypted store, committed (git = second
                        untrusted server); .sg_vault/local/ is git-ignored, always
site/                 the demos.sgit.ai host page + embed host (boots the catalogue
                      app from this site's own static mirror of the vault)
catalogue/
  index.md            the human-readable read-key catalogue
  pending/            submission queue: one small file per vault awaiting publication
docs/
  PUBLISHING.md       the per-vault publishing runbook (intake → audit → export → commit)
  DEPLOYMENT.md       deploying and republishing vaults to any server
scripts/
  audit_vault_export.sh   secret audit run on every archive before commit
version               owned by CI: every push to dev bumps minor, main bumps major
.github/workflows/ci-pipeline.yml   validate → increment-tag → build → deploy Pages
                                    (demos.sgit.ai)
```

## Quick start (consuming)

Anyone can:

```bash
git clone https://github.com/SGit-AI/SGit-AI__Demo-Vaults
# browse catalogue/index.md, pick a vault, open its read key at the listed host —
# or deploy the whole estate to your own server: see docs/DEPLOYMENT.md
```

## One-time setup still needed (repo admin)

The pipeline is green except the final step: **GITHUB_TOKEN cannot create a Pages
site**, so an admin must do this once — Settings → Pages → Build and deployment →
Source: **GitHub Actions**. Then set custom domain `demos.sgit.ai` (and add the DNS
CNAME record `demos` → `sgit-ai.github.io`). Every subsequent push to `dev`
deploys automatically.

## Where the catalogue vault is served

The vault is published on the SG/API host and *also* mirrored statically by CI, so the
same read key opens it from either place:

| Endpoint | How | Status |
|---|---|---|
| `https://send.sgraph.ai` | the SG/API host, `sgit push`ed 2026-08-16 | **live** — what the demos site fetches from |
| `https://demos.sgit.ai/api/vault/read/<vault-id>/` | static path-mirror built by CI | the static-hosting demonstration and offline/air-gap copy |

**The site page reads from the API host, not from its own mirror.** Two reasons: the
API is the canonical, always-current copy; and this site is served from a repo subpath
(`sgit-ai.github.io/SGit-AI__Demo-Vaults/`), so an endpoint of `location.origin` builds
read URLs above the site root and 404s. To open the vault from the mirror instead, the
endpoint must carry the subpath — see the comment in `site/index.html`.

## Provenance

The design comes from the 14 August 2026 brief set in the SGraph Send corpus
(`team/humans/dinis_cruz/briefs/08/14/sgit-site-and-hub/`, v0.33.58), in particular:

- *Topic sections … publish read keys, never write keys, and a vault whose write key is
  lost is frozen rather than broken* — the catalogue schema and the escrow precondition.
- *The serialised pull request is the headline: publish the sample vaults* — publish both
  ways (archive + browsable embed), evidence status, shapes over domains.
- `PUBLISHING-SGIT-VAULT-TO-GITHUB.md` and `HOSTING-ON-STATIC-STORAGE.md`
  (`library/guides/vault-html/` in the SGraph-AI__App__Send repo) — the credential
  boundary, the secret audit, and the static path-mirror deployment contract.
