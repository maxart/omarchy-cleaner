# Historical catalogue: Quattro at 10f1cbf

This records the comparison after PR #7 with [Quattro commit `10f1cbf7cfbeb8771697dbd493d2f2562db99d7b`](https://github.com/omacom/omarchy/tree/10f1cbf7cfbeb8771697dbd493d2f2562db99d7b). It describes a development snapshot. For current release support, see the [4.5.0 compatibility report](v4.5.0-compatibility.md).

## Catalogue changes

| Source | Change and cleaner behavior |
| --- | --- |
| `install/user/mise.sh` | Add `basecamp` and `cf` wrappers; retain both `grok` and `npm:@xai-official/grok` package mappings. Basecamp CLI and webapp selections remain separate. |
| `bin/omarchy-remove-preinstalls` | Add `hype` and `monologue` to active packages. |
| `install/omarchy-base.packages` | Add 18 missing names to the commented catalogue. The pinned list is in `catalogues.json`. |
| `applications/*.desktop` | Keep historical Docker/Disk Usage detection despite their removal upstream. Reject native Foot, imv, and mpv overrides. The 11 webapps match 4.0.4. |

Older package and wrapper entries were retained. The mise installer was byte-identical to the 4.0.4 fixture, so complete-template ownership checks remained sufficient. Account shims were not treated as owned wrappers.

## Bindings and Hermes

The snapshot retained default/preinstall binding switches, the removal marker, and personal overrides after packaged defaults. Omawrite and the changed Google Messages formatting matched existing cleanup rules. No speculative aliases were added for Hype or Monologue.

Its Hermes installer no longer supported `--owns`; unsupported modes exited before installation or retirement. Cleaner therefore preserved Hermes. It never invoked `--now` or `--retire-mise`, or removed Hermes runtimes.

## Validation at the time

Syntax, ShellCheck 0.11.0, whitespace checks, and 43 isolated tests passed. The five new tests covered CLI discovery, category independence, native desktops, binding override order, and a Hermes helper without `--owns`. Catalogue tests failed before the missing entries were added.

Fixtures came from the pinned checkout without executing provisioning or removal scripts. This standalone patch did not include PR #8's additional tests or a live VM smoke test. See [fixture provenance](../tests/fixtures/README.md).
