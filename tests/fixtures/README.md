# Upstream fixtures

Fixtures pin [Omarchy](https://github.com/omacom/omarchy) sources for offline tests. Executable fixtures run only in temporary homes: generators create wrappers without executing them, and the default-tools helper uses a stubbed shim refresh. The upstream [MIT license](OMARCHY-LICENSE) is retained.

## Revisions

Catalogue entries record full commit IDs in `catalogues.json`:

| Revision | Commit | Fixtures |
| --- | --- | --- |
| 3.8.4 | [8fcc9d6](https://github.com/omacom/omarchy/tree/8fcc9d6048af4cb0e3af8512c78049857a3b53dd) | `npx-install.sh` |
| 4.0.0 | [f002044](https://github.com/omacom/omarchy/tree/f0020448ca87329199de7cb12f2015ebc4a3e5e7) | `applications-4.0.0.lua`, `mise-install-4.0.0.sh` |
| 4.0.2 | [346e69e](https://github.com/omacom/omarchy/tree/346e69e1cec6c4e8924531874af6ba010a1bc99e) | Catalogue, `applications.lua` |
| Quattro | [959e49d](https://github.com/omacom/omarchy/tree/959e49dc52a60d35b299d4e13372bc74dd0797ae) | Catalogue |
| 4.0.4 | [c668141](https://github.com/omacom/omarchy/tree/c668141e9c42b13c80c9ca4ea108e11708c5e8a5) | Catalogue, `mise-install.sh` |
| Quattro | [10f1cbf](https://github.com/omacom/omarchy/tree/10f1cbf7cfbeb8771697dbd493d2f2562db99d7b) | Catalogue, `applications-10f1cbf.lua` |
| 4.0.6 | [237f1b4](https://github.com/omacom/omarchy/tree/237f1b4071a0bff2296c6d740ba2b9fd695ebfa0) | Catalogue |
| 4.5.0 | [ac2690c](https://github.com/omacom/omarchy/tree/ac2690cd7be4f47e4a255f5e2e78d904d436b068) | Catalogue and all `*-4.5.0.*` source fixtures |

## Source paths and shared data

The catalogue extracts base packages from `install/omarchy-base.packages`, removable packages from `bin/omarchy-remove-preinstalls`, CLI tuples from `install/user/mise.sh`, and desktops from `applications/*.desktop`.

The 4.5 snapshot also records `platform_additions` from `install/omarchy-aarch64*.packages` and the separate `x86_64_only` exclusion list. These follow `bin/omarchy-pkg-defaults`: base, shared architecture additions, then platform additions. The `omarchy-other.packages` ISO availability list is not a default set. Older snapshots omit these fields.

Binding fixtures copy `default/hypr/bindings/applications.lua`; installer fixtures copy `bin/omarchy-mise-install` or `bin/omarchy-npx-install`. The 4.5 fixtures also copy `etc/mise/conf.d/omarchy-tools.toml` and `bin/omarchy-mise-default-tools`.

Shared fixtures preserve these verified equivalences:

- `applications.lua` is identical in 4.0.2, 4.0.4, and 4.0.6.
- `mise-install.sh` is identical in 4.0.4, 4.0.6, and Quattro `10f1cbf`. It emits the same wrappers as the 4.0.2 generator for all 18 distinct tuples recorded in 4.0.2, 4.0.4, and Quattro `959e49d`.
- The 4.0.6 package, drop, CLI, and launcher lists match 4.0.4. Native fixtures add the browser link handler.

`native_desktops` contains ownership-rejection cases; the first three catalogue snapshots did not record this field. In 4.5, `clis` is empty because provisioning no longer creates wrappers. `lazy_clis` and `runtimes` record declarations separately; aliases and Qwen's binary were checked against mise v2026.11.1.

## Refresh fixtures

Use Python 3.11+ to extract a pinned revision from a local Omarchy checkout:

```bash
python3 tests/fixtures/extract_catalogue.py your_omarchy_checkout v4.5.0
```

All five older catalogue entries were reproduced before adding 4.5. Recheck shared-generator equivalence when changing tuples, and refresh snapshots deliberately. Tests must not depend on floating upstream content. The cleaner itself remains self-contained Bash.
