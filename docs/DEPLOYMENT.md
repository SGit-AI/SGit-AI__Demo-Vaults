# Deploying demo vaults to any server

A published vault is consumed with a triple — **endpoint + vault ID + read key** — as
demonstrated live at [sgit.ai/demos/vault-app-embed.html](https://sgit.ai/demos/vault-app-embed.html).
Deployment means making the vault's encrypted `bare/` tree reachable at an endpoint.
Because everything in `bare/` is ciphertext and all read paths are deterministic
(computed client-side from the key — no listing call), *any* server that can serve
files works: an SG/Send server, GitHub Pages, S3, an nginx box, or an air-gapped host.

## Target 1 — SG/Send server (live endpoint)

The normal home: the vault's objects live on a SG/Send server
(e.g. `https://dev.send.sgraph.ai`) and the consumer opens
`<vault-browser>#<read-key>` or embeds the app with the triple.

Restoring a vault from this repo onto a server requires a write path, i.e. the
escrowed write key — retrieve it from escrow (never from this repo), reconstitute
locally, `sgit push` to the new server, then discard the local credential tier.

> First-onboarding note: the memo references a "new deployment mode" for moving vaults
> onto sgit.ai. Verify the exact procedure during the first vault onboarding and
> record it here.

## Target 2 — Static host (no backend at all)

Per the static-hosting contract ([sgit.ai/vault/static-hosting.md](https://sgit.ai/vault/static-hosting.md)):
the live API serves `GET /api/vault/read/<vaultId>/<filePath>` from the vault's `bare/`
tree, so a static host that **path-mirrors** that tree serves the vault with zero
backend:

```
<static root>/
└── api/vault/read/<vaultId>/
    └── bare/
        ├── data/       obj-cas-imm-*   immutable — cache forever
        ├── refs/       ref-pid-muw-*   mutable head — no-store / short max-age
        ├── indexes/    idx-pid-muw-*   mutable — no-store / short max-age
        └── keys/       key-rnd-imm-*   immutable
```

Steps per vault:

1. Unzip `vaults/<slug>/vault.zip` — `bare/` sits at the zip root (verified layout,
   sgit-ai v0.15.0).
2. Place that `bare/` tree at `api/vault/read/<vault_id>/bare/` under the static root
   (`vault_id` is in the manifest). Path-mirroring is the one hard requirement.
3. Host page sets `window.SG_STATIC = true` and `window.SG_ENDPOINT = '<static base>'`,
   opens the vault with the read key, no access token → clean read-only
   (`sg.app.writable === false`, writes rejected with `EREADONLY`).
4. Verify in a browser with only the published read key.

This is the air-gap path too: `git clone` this repo inside the enclave, unzip, serve
the tree with any web server. No SG/Send backend, no outbound network needed beyond
the vault-web static assets (mirror those inside the enclave as well if fully offline).

## Target 3 — Embedded in a page

The sgit.ai pattern (`assets/vault-embed.js`, ~170 lines): the page fetches ciphertext
over CORS from the endpoint, decrypts with Web Crypto using the read key, boots the
vault's `index.html` in a sandboxed iframe (`sandbox="allow-scripts"`), and bridges
`sg.vfs` calls via postMessage. No copy of the content exists on the embedding site —
only encrypted objects are fetched, decrypted client-side.

To embed a vault from this catalogue, a page needs only the manifest's triple.

## Republish everything

The point of holding only read keys: **the whole estate redeploys from this repo alone.**

```bash
git clone https://github.com/SGit-AI/SGit-AI__Demo-Vaults && cd SGit-AI__Demo-Vaults
for m in vaults/*/manifest.json; do
  slug=$(dirname "$m"); vid=$(python3 -c "import json;print(json.load(open('$m'))['vault_id'])")
  sha=$(python3 -c "import json;print(json.load(open('$m'))['archive_sha256'])")
  echo "$sha  $slug/vault.zip" | sha256sum -c -          # integrity before serving
  mkdir -p "$DEST/api/vault/read/$vid"
  unzip -o "$slug/vault.zip" -d /tmp/vault-$vid && cp -r /tmp/vault-$vid/**/bare "$DEST/api/vault/read/$vid/"
done
```

(Sketch — promote to `scripts/deploy_static.sh` once the exact `sgit export` zip layout
is confirmed on the first onboarding.) Run it weekly, on every commit via CI, or once
into a new enclave: the result is identical, because CAS objects are immutable and the
archives carry their own integrity hashes.

## What deployment can never do

- **Grant write access.** No write key exists anywhere in this pipeline.
- **Withdraw a published key.** Removing objects from servers you control does not
  revoke the copies others hold. Publication is permanent; see the frozen-vault rule
  in `docs/PUBLISHING.md`.

## Custom domain (demos.sgit.ai) — not yet active

The site is live at `https://sgit-ai.github.io/SGit-AI__Demo-Vaults/`. `demos.sgit.ai`
does **not** resolve yet (`DNS_PROBE_FINISHED_NXDOMAIN`), so:

- there is deliberately **no `site/CNAME` file** — deploying one would tell Pages to
  serve the custom domain and could take the working github.io URL down with it;
- `catalogue.json` sets `site` to the github.io base, so archive download links work.

To switch over, in this order: add DNS `CNAME demos → sgit-ai.github.io`, wait for it to
resolve, then add `site/CNAME` containing `demos.sgit.ai`, set the custom domain in
Settings → Pages, and change `site` (and `site_note`) in `demo-vault/catalogue.json`.
