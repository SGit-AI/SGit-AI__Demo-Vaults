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
  "links": [
    { "kind": "video", "label": "MVP walkthrough", "url": "https://youtu.be/…" }
  ],
  "last_verified": "2026-08-16",
  "superseded_by": null
}
```

`links` is optional: related material *outside* the vault — a walkthrough video, a
write-up, a case-study page. `kind` is `video` · `write_up` · `page` (it only picks the
icon; an unknown kind still renders). The catalogue app shows each one as an action
button that opens in a new tab. Keep the label descriptive enough to be worth a click,
and record in the manifest where the label came from if it was supplied rather than
verified.

Field meanings follow the catalogue column notes (`catalogue/index.md`). The example
values above are from the live embed demo at sgit.ai/demos/vault-app-embed.html.

Rules:

- `read_key` is the **only** key that ever appears. Write-key material of any form is
  forbidden in this repo.
- `archive_sha256` is verified before every deploy (`docs/DEPLOYMENT.md`).
- `vault.zip` is immutable once published — replacements get a new slug and a
  `superseded_by` pointer on the old one.
