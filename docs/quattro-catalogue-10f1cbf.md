# Quattro catalogue comparison

This refresh compares Cleaner after merged PR #7 with [Omarchy Quattro at `10f1cbf7cfbeb8771697dbd493d2f2562db99d7b`](https://github.com/omacom/omarchy/tree/10f1cbf7cfbeb8771697dbd493d2f2562db99d7b). It is a pinned development-branch snapshot, not a claim that every change belongs to release 4.0.4.

## Catalogue changes

| Source | Finding | Cleaner behavior |
| --- | --- | --- |
| `install/user/mise.sh` | Adds `github:basecamp/basecamp-cli` as `basecamp`, and `npm:cf` as `cf`. | Offer their complete recognized mise wrappers. Basecamp's CLI and webapp remain separate selections. |
| `install/user/mise.sh` | Grok now uses package `grok` instead of `npm:@xai-official/grok`. | Recognize both package identifiers; preserve customized wrappers. |
| `bin/omarchy-remove-preinstalls` | Adds `hype` and `monologue` to its package drop list. | Add both as active packages, gated by `pacman -Qi`. |
| `install/omarchy-base.packages` | Adds 18 other names missing from the commented catalogue. | Add them commented out: `base-devel`, `disktree-bin`, `fcitx5-chewing`, `fcitx5-chinese-addons`, `fcitx5-hangul`, `fcitx5-mozc`, `ffmpeg`, `gliff`, `omasnap`, `owe`, `owe-lockfeed`, `qt6-base`, `qt6-declarative`, `qt6-multimedia`, `qt6-svg`, `qt6-wayland`, `superwhisper-bin`, `usbguard`. |
| `applications/*.desktop` | Docker and Disk Usage launchers are absent; Foot, imv, and mpv native overrides are present. | Retain historical TUI detection. Native overrides are not treated as removable webapps. The 11 current webapps are already covered and their contents match the 4.0.4 snapshot. |

Previous packages and wrappers remain in the catalogue for older or optionally configured installations. In particular, removing packages from upstream's current base/drop list does not cause Cleaner to discard their detection. No changes to package-removal commands, privileges, confirmation, or wrapper ownership rules are needed for this refresh.

## Ownership and binding compatibility

The current `bin/omarchy-mise-install` is byte-identical to the pinned 4.0.4 fixture, so the existing full-template comparison handles the new CLI tuples. The existing tests still exercise older Grok wrappers. Unknown formats, symlinks, altered package/bin values, and appended commands remain unrecognized.

Current `bin/omarchy-install-hermes-cli` installs Hermes Desktop and accepts `--check`, `--now`, and `--retire-mise`; it no longer provides `--owns`. Inspection confirms an unsupported mode exits before installation or retirement. Cleaner continues to request only `--owns` and leaves Hermes untouched when that query fails. Older installations whose helper still provides the ownership contract remain supported. Cleaner does not invoke `--now` or `--retire-mise`, duplicate ownership markers as an alternative contract, or delete Hermes runtimes.

Provisioning now also calls `mise reshim` for account dispatchers. This does not authorize removing arbitrary mise shims or account configuration; CLI ownership remains limited to known wrappers under `~/.local/bin`.

Inspected `default/hypr/bindings/applications.lua`, `default/hypr/helpers.lua`, `default/hypr/omarchy.lua`, and `config/hypr/hyprland.lua`. The default-binding switch, preinstall-binding switch, and removal marker are still supported. Personal bindings load after packaged defaults. Current application bindings include Omawrite and slightly different formatting for Google Messages, both recognized by the existing matcher. No packaged application bindings for `hype` or `monologue` were found; no speculative token aliases or new unbind behavior were added.

## Validation

- Syntax check, ShellCheck 0.11.0, and whitespace checks pass.
- All 43 regression tests on this standalone patch pass, including five new tests covering current CLI discovery/preservation, Basecamp category independence, native desktop preservation, current binding cleanup/override ordering, and a Hermes helper without an ownership contract.
- Before the runtime catalogue changes, the new snapshot failed catalogue coverage for the 20 missing base-package names, and current CLI discovery failed.
- Snapshot data was extracted from the local pinned upstream checkout without executing provisioning or removal scripts. Current desktop and binding fixtures are copied verbatim; the generator's byte identity was checked separately.
- Tests use disposable homes and stubbed system commands. No live Omarchy VM/TUI smoke test has been performed.

PR #8 adds a separate set of five 4.0.4 regression tests. The count above describes this patch independently, without assuming that PR is merged.
