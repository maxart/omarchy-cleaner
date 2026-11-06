# Contributor and agent guidance

Omarchy Cleaner is a self-contained Bash script using gum for its terminal interface. Runtime code lives in `omarchy-cleaner.sh`; isolated tests and pinned upstream fixtures live in `tests/`. Read [README.md](README.md) for usage and [4.5 compatibility](docs/v4.5.0-compatibility.md) for the current support boundary.

## Code map

| Area | Functions and data |
| --- | --- |
| Catalogues | `DEFAULT_APPS`, `DEFAULT_WEBAPPS`, `DEFAULT_TUIS`, `DEFAULT_NPM_CLIS` |
| Detection | `is_package_installed`, `is_webapp_installed`, `is_npm_cli_installed`, `get_installed_*` |
| Selection | `parse_sections`, `enhanced_select_packages`; exact display-row mapping to newline-delimited `SELECTED_*` globals |
| Descriptions | `load_package_descriptions`, `curated_description_for`, `print_confirmation_items`, `print_mise_default_tools` |
| Package plan | `preview_package_removal`, `find_blocked_packages`; `PLANNED_PACKAGES` records the complete recursive removal set |
| CLI group | `get_mise_default_tools`, `mise_defaults_state`, `plan_mise_defaults`, `remove_mise_defaults` |
| Bindings | `webapp_domains_for`, `app_tokens_for`, `find_bindings_in_file`, `find_app_bindings`, `find_packaged_unbind_keys`, `cleanup_bindings` |
| Removal | `remove_packages`, `remove_webapps`, `remove_npm_clis`, then successful-item binding cleanup in `remove_items` |
| Entry point | `main`: scan, select, preview, shortcut consent, final confirmation, removal and summary |

## Catalogue maintenance

Compare against the exact Omarchy tag being claimed, using an available local upstream checkout. A Quattro development snapshot does not establish release compatibility. Re-read these sources when syncing:

- `install/omarchy-base.packages`: default package names
- `bin/omarchy-remove-preinstalls`: minimum active removable package set
- `applications/*.desktop`: webapp and terminal-launcher names and commands
- `etc/mise/conf.d/omarchy-tools.toml`, `bin/omarchy-mise-default-tools`: 4.5 lazy defaults and opt-out contract
- `install/user/mise.sh`, `bin/omarchy-mise-install`, `bin/omarchy-install-hermes-cli`: older CLI names, wrappers and ownership contracts
- `default/hypr/bindings/applications.lua`: packaged shortcuts
- Legacy `install/packaging/webapps.sh`, `install/packaging/npx.sh`, `bin/omarchy-npx-install`: older launcher and wrapper formats

Keep every upstream removable package active, plus Cleaner's additional offerings. Other base packages belong in the commented catalogue. Retain older names such as `ghostty`, `alacritty`, and `xournalpp`; offer them only when detected.

Use exact package names, desktop basenames, and CLI command names. New webapps need `webapp_domains_for` entries. CLI wrappers need verified complete templates and explicit `cli_packages_for` mappings. Every webapp, terminal launcher, and CLI needs a functional description with a source in [item descriptions](docs/item-descriptions.md); packages use pacman's description. Keep descriptions out of fuzzy name search.

## Removal and privilege rules

Nothing is preselected. Require final itemized confirmation before mutation, including every additional dependency pacman plans to remove.

Only the package transaction uses sudo. Run `pacman -Rs --print` without root first; keep selected packages required by unselected installed packages. Never remove dependents implicitly to force removal. Unknown preview failures abort all mutations; a changed package plan prevents package removal and its shortcut cleanup. Acquire sudo once and remove eligible packages in one `pacman -Rns` transaction. Do not run the whole cleaner under sudo.

Launcher removal, legacy-wrapper deletion, mise opt-out, and binding edits stay unprivileged. Pass quoted arguments directly to commands, never interpolated `bash -c` code. Recheck ownership before removal; preserve customized wrappers, symlinks, and same-name native desktops. Legacy wrappers require complete known templates. Hermes uses only the upstream read-only `--owns` contract; never invoke installation or runtime-retirement modes.

### Omarchy 4.5 CLI group

Offer `Omarchy default CLI tools (all)` as an explicit, unselected group. Confirmation must show all declarations, including Node.js, uv, and unknown future keys. Individual CLI entries remove only legacy wrappers and must never trigger whole-set opt-out.

Do not infer ownership from arbitrary shims or use `disable_tools`, which also blocks personal/project tools. Recheck the confirmed list and configuration before mutation. Back up existing mise settings and recover after a failed expected helper edit. Refuse linked settings, redirected parents, and conflicting ignore lists. Preserve personal/project declarations, installed runtimes, caches, and application data; report recovery failures.

## Selection and binding rules

Use `parse_sections` for the combined array: packages, `--webapps--`, then `--npmclis--`. Terminal launchers share the webapp section. Keep selected results newline-delimited and names quoted so spaces survive. Map selected display rows by exact match, preserving category distinctions.

Prefer personal `bindings.lua`, with legacy `bindings.conf` fallback. Packaged defaults live under `${OMARCHY_PATH:-/usr/share/omarchy}/default/hypr/bindings/`. Never edit packaged config or set the global `preinstalls-removed` marker.

Preserve these cleanup constraints:

- Respect global default/preinstall switches, the removal marker, and active unbinds.
- Match supported literal single-line Lua string/table dispatchers and legacy `bindd` launcher commands. Preserve computed/multiline Lua, escaped strings, unsupported fields, and ambiguous layouts. Skip long comments/strings by their exact delimiters.
- Match webapp launcher URLs by hostname, not substrings. Match native commands through `app_tokens_for`, retaining subcommands and catalogue case.
- Removing Docker plugins must preserve Docker/lazydocker shortcuts; removing `1password-cli` must preserve GUI shortcuts. The `Docker` launcher must not claim `docker` engine bindings.
- Remove matching user lines by line number. Prepend packaged `hl.unbind` calls before personal overrides so replacement shortcuts survive.
- Create a checked, unique backup and atomic replacement; preserve file mode and detect concurrent changes. Abort on backup/write/replacement failure and report partial success when removal already succeeded.
- Clean shortcuts only for successful removals. Shortcut-only selections require cleanup consent; CLI entries skip binding cleanup.

## Validation

After every edit, run the syntax check. Runtime changes also need lint and isolated regressions:

```bash
bash -n omarchy-cleaner.sh
shellcheck omarchy-cleaner.sh
python3 -m unittest discover -s tests -v
```

Use stubbed system commands for isolated removal tests. Real removals belong only inside the configured disposable **VM guest**, never on the working host or in a container hosting its hypervisor.

Runtime changes and PR reviews must follow the [VM testing skill](skills/omarchy-vm-testing/SKILL.md). Run the exact candidate's regression suite inside the guest and exercise the affected real workflow before claiming live compatibility. Host tests and CI alone are insufficient. Documentation-only changes need no VM boot or reset.

Read `.local/omarchy-vm.md` for private access and recovery details. If it or VM access is missing, complete independent checks and report live validation as blocked. Preserve unrelated guest work before reset. Keep machine-specific paths, identities, credential locations, and recovery history in Git-ignored `.local/`; never put credential values in documentation or public reports.

## Style and repository rules

- Use plain Bash, four-space indentation, `snake_case` functions, and quoted variables. Do not add strict mode without auditing existing nonzero-exit and empty-array control flow.
- Use gum for user-facing output and retain the existing palette: 39/51 blue/cyan, 82 green, 214 orange, 196 red. Keep the banner identical in `main` and `show_main_header`.
- Keep runtime code self-contained. Refresh fixtures deliberately; see [fixture provenance](tests/fixtures/README.md).
- Commit and push only when asked; otherwise leave changes for the maintainer.
- Use concise commit messages without `Co-Authored-By` or other tool-attribution trailers.
