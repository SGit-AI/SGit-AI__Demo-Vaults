# Submission queue

One file per vault awaiting publication. Smallest possible per-entry cost: the human
supplies only what cannot be derived; the agent opening the vault with the read key
derives the rest.

Create `catalogue/pending/<slug>.md`:

```markdown
read_key: <the read key — publishing it here starts the publication, so be sure>
one_line: <what this vault is for>
shape: gallery | report | structured-analysis | multi-agent | record-keeping | application
evidence_status: production | demonstration | sketch
copy_or_reference: copy | reference
write_key_status: escrowed | lost
```

Optional extras if known: `vault_id`, `endpoint`, `title`.

**Never put a write key, vault key, push token, or share-with-write token in this
folder or anywhere else in this repo.**

The publishing agent processes entries per [docs/PUBLISHING.md](../../docs/PUBLISHING.md)
and deletes the pending file in the same commit that publishes the vault.
