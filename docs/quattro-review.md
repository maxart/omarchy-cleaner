# Historical review: Quattro support

This records the review of [PR #5 at `d268284`](https://github.com/maxart/omarchy-cleaner/tree/d268284cb1fbd5f6fdee3bdff9576943dd9056c3). For current support and live testing, see the [4.5.0 compatibility report](v4.5.0-compatibility.md).

## Findings and fixes

The review compared Omarchy 4.0.2 and Quattro `959e49d`, with older 4.0.0 and 3.8.4 fixtures. Exact revisions and source paths are in [fixture provenance](../tests/fixtures/README.md).

| Finding in the proposal | Fix |
| --- | --- |
| Any script mentioning mise could be removed. | Require complete known wrappers and command/package pairs, reject symlinks, and recheck ownership before deletion. Use only Hermes' read-only `--owns` contract. |
| Appended unbinds disabled personal replacement shortcuts; commented examples counted as active unbinds. | Prepend packaged unbinds before personal overrides and recognize only active standalone unbinds. |
| Backup/write failures did not stop edits; backups could collide. | Check unique backups, preserve file mode, replace atomically, detect concurrent changes, and report failures. |
| Shortcut cleanup preceded uninstall success. | Clean shortcuts only after successful removal. |
| Shortcut-only selections could report success without cleanup consent. | Label them, skip them when consent is declined, and count cleanup failures. |
| URL matching used unanchored regexes; removal interpolated shell commands. | Match URL hostnames and pass quoted arguments directly to commands. |

The catalogue added Quattro's CLI wrappers and retained older packages and Docker/Disk Usage launchers. Package removal became one transaction so selected dependencies did not block each other through removal order.

## Validation at the time

Bash syntax, ShellCheck, and isolated tests covered ownership, upstream templates, bindings, cancellation, failure handling, and the piped entrypoint. This review did not include live VM removals. Later live validation is recorded in the current report linked above.
