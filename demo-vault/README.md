# Demo Vaults — the vault

This folder is itself an sgit vault. It contains:

- `index.html` + `app.json` — the **Demo Vaults catalogue app** (a vault app: opens
  automatically when the vault is browsed, renders `catalogue.json`)
- `catalogue.json` — the machine-readable read-key catalogue
- `vaults/<slug>/vault.zip` — the published demo vaults as encrypted archives, each with
  its `manifest.json`

The vault's own encrypted store (`.sg_vault/bare/`) is committed to git alongside the
plaintext working tree — git is a second untrusted server. The credential tier
(`.sg_vault/local/`) is git-ignored and must never be committed; the vault (write) key
is held out-of-band by the project lead only. The **read key** is published — that is
what makes this a demo.

The same content is therefore versioned twice, deliberately: once by git (this repo)
and once by sgit (the vault's own history) — an experiment in the performance and
workflow implications of the duality for our current number and size of demo vaults.

Deployed to GitHub Pages at **demos.sgit.ai** by CI on every push to `dev`: the site
serves this vault's `bare/` tree statically (path-mirrored under
`api/vault/read/<vault-id>/`), plus the host page that boots the catalogue app from it
with the published read key.

<!-- v1 -->
