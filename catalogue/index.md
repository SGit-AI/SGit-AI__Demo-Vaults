# Read-Key Catalogue

One row per published demo vault. **Read keys only — write keys are never listed here
or anywhere in this repo** (see the hard rules in the [README](../README.md)).

A row is not added until the vault has passed the publishing runbook
([docs/PUBLISHING.md](../docs/PUBLISHING.md)), including the secret audit and a
verified deploy.

| Slug | One line | Shape | Evidence | Copy/Ref | Write key | Vault ID | Endpoint | Read key | Last verified |
|------|----------|-------|----------|----------|-----------|----------|----------|----------|---------------|
| _none yet_ | | | | | | | | | |

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
