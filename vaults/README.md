# vaults/

One directory per published demo vault:

```
vaults/<slug>/
  vault.zip        the exported encrypted bare/ store — the vault itself
  manifest.json    machine-readable metadata (schema below)
  README.md        human-readable entry, derived by the publishing agent
```

## manifest.json schema

```json
{
  "slug": "field-notes",
  "title": "Field Notes",
  "one_line": "Single-file vault app with editable content.json",
  "shape": "application",
  "evidence_status": "demonstration",
  "copy_or_reference": "copy",
  "write_key_status": "escrowed",
  "vault_id": "4bshby5n",
  "read_key": "sgit_rk1_…64-hex…",
  "endpoints": ["https://dev.send.sgraph.ai"],
  "archive": "vault.zip",
  "archive_sha256": "…",
  "exported_at": "2026-08-16",
  "source": "exported from <server> with sgit export",
  "secret_audit": { "date": "2026-08-16", "result": "clean", "by": "<who>" },
  "sgit_commits": 0,
  "size_bytes": 0,
  "has_app": true,
  "last_verified": "2026-08-16",
  "superseded_by": null
}
```

Field meanings follow the catalogue column notes (`catalogue/index.md`). The example
values above are from the live embed demo at sgit.ai/demos/vault-app-embed.html.

Rules:

- `read_key` is the **only** key that ever appears. Write-key material of any form is
  forbidden in this repo.
- `archive_sha256` is verified before every deploy (`docs/DEPLOYMENT.md`).
- `vault.zip` is immutable once published — replacements get a new slug and a
  `superseded_by` pointer on the old one.
