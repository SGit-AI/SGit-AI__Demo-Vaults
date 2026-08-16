# Read-Key Catalogue

One row per published demo vault. **Read keys only — write keys are never listed here
or anywhere in this repo** (see the hard rules in the [README](../README.md)).

A row is not added until the vault has passed the publishing runbook
([docs/PUBLISHING.md](../docs/PUBLISHING.md)), including the secret audit and a
verified deploy.

| Slug | One line | Shape | Evidence | Copy/Ref | Write key | Vault ID | Endpoint | Read key | Last verified |
|------|----------|-------|----------|----------|-----------|----------|----------|----------|---------------|
| `demo-vaults-catalogue` | The catalogue itself: app + data + every published archive — a vault listing vaults, including itself | application | production | reference | escrowed | `2a8d3n2z` | https://send.sgraph.ai | `e6136dab44fecf12b440d6f827419fcb5d51e244576116336c5bef0c42adaa1a` | 2026-08-16 |
| `field-notes-embed-demo` | The sgit.ai vault-app-embed demo: six small studies served as a vault app with a deliberately published read key | application | demonstration | copy | escrowed | `4bshby5n` | https://send.sgraph.ai | `2848993a68c02a33ea5582902c391901191e53680d35b36c0e76185d4107ad81` | 2026-08-16 |

The machine-readable version of this table is `demo-vault/catalogue.json` — that file is
what the catalogue app at [demos.sgit.ai](https://demos.sgit.ai) renders, so it is the
canonical one; keep this table in sync with it.

**Column notes**

- **Shape** — `gallery` · `report` · `structured-analysis` · `multi-agent` ·
  `record-keeping` · `application`. Sort and browse by shape; domain is incidental.
- **Evidence** — `production` · `demonstration` · `sketch`. Stated so a reader does not
  have to guess.
- **Copy/Ref** — `copy` (archive in this repo; diverges from any live original the
  moment it lands) or `reference` (live sub-vault link; changes underneath the reader).
- **Write key** — `escrowed` or `lost`. A `lost` entry is **frozen**: readable forever,
  never correctable. Frozen entries are marked so readers know.
- **Superseded** — replaced vaults keep their row, marked `superseded by <slug>`,
  because anyone holding the old read key still has a working copy.

## Submission queue

Drop a minimal entry in [`pending/`](pending/README.md) — read key, one line, four
fields. The publishing agent derives everything else.
