# AGENTS.md

## Project Overview

Omarchy Cleaner is an interactive shell script that removes unwanted default
applications and webapps from [Omarchy](https://github.com/omacom/omarchy)
installations. It is a single self-contained Bash script meant to be run on a
freshly installed Omarchy system — typically piped straight from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/maxart/omarchy-cleaner/main/omarchy-cleaner.sh | bash
```

It uses [`gum`](https://github.com/charmbracelet/gum) (which ships with Omarchy)
for the whole TUI: the ASCII banner, the fuzzy multi-select list, spinners,
confirmation dialogs, and the success/partial/failure "hero" summary. There is
no compiled binary and no dependencies beyond what Omarchy already installs
(`gum`, `pacman`, and Omarchy's `omarchy-webapp-remove` / `omarchy-tui-remove` helpers).

## Code Architecture

Everything lives in **`omarchy-cleaner.sh`**. The notable pieces, top to bottom:

```
Config block            VERSION; BINDINGS_FILE auto-detected (.lua preferred,
                        legacy .conf fallback); REMOVE_BINDINGS flag.
DEFAULT_APPS[]          pacman packages offered for removal (active + a large
                        commented catalogue of every other Omarchy default).
DEFAULT_WEBAPPS[]       Omarchy webapps offered for removal (by display name).
DEFAULT_TUIS[]          Known TUI desktop launchers (Docker and Disk Usage).
DEFAULT_NPM_CLIS[]      Omarchy npm CLI tools (codex, gemini, opencode, ...),
                        installed as mise/npx/pnpm wrappers in ~/.local/bin.
                        Complete known templates are checked, or Hermes' upstream
                        read-only --owns contract. Customized files/links stay.

is_package_installed    pacman -Qi probe.
is_webapp_installed     Checks a regular desktop file and its launcher command.
is_npm_cli_installed    Checks a regular non-symlink wrapper against complete
                        known templates and command/package mappings.
get_installed_*         Filter each DEFAULT_* list down to what's installed.
parse_sections          Splits a combined "items + --webapps-- + --npmclis--"
                        array into PARSED_PACKAGES/WEBAPPS/NPMCLIS globals. Used
                        by both the selector and the remover.

webapp_domains_for      Maps a webapp name -> URL domain(s) that identify it.
app_tokens_for          Maps a package -> newline-delimited commands its keybind
                        references, preserving subcommands (docker compose).
find_bindings_in_file   Matches supported single-line Lua/conf bindings; can
                        return line numbers so identical comment text survives.
find_app_bindings       Matches the user's bindings file.
find_packaged_unbind_keys  Matches packaged applications.lua, respecting global
                        disable flags, the removal marker, and active unbinds.
cleanup_bindings        Creates a checked, unique backup and atomic replacement;
                        removes matched user lines and PREPENDS packaged unbinds
                        so personal overrides on the same keys still work.

enhanced_select_packages   The gum fuzzy multi-select. Items arrive in one array
                        split by "--webapps--"/"--npmclis--" sentinels; prefixed
                        📦/🌐/⬢ and marked ⌨ if they have a keybind. Sets globals
                        SELECTED_PACKAGES / SELECTED_WEBAPPS / SELECTED_NPMCLIS
                        (newline-delimited, to survive names with spaces).
remove_webapps          Removes one selected webapp/TUI launcher with its helper;
                        shortcut-only selections require cleanup consent.
remove_npm_clis         Rechecks ownership and deletes selected stubs (no sudo).
find_blocked_packages   Rootless `pacman -Rs --print` dry run; sets aside selected
                        packages still required by installed ones outside the
                        selection (ufw-docker -> docker), so the rest can go.
remove_packages         Acquires sudo, removes selected packages in one transaction.
remove_items            parse_sections, all three removers, then binding cleanup
                        only for successful removals, followed by the hero box.
main                    Banner → scan → select → dry run → keybind prompt → confirm
                        → remove.
```

Runtime code is self-contained in this file. Regression tests live in `tests/`
and use disposable homes and stubbed system commands (see Build & Run).

## Design and Concepts

### What "Omarchy default" means

The catalogues are the heart of the tool and must track upstream Omarchy. The
sources of truth, in an available clone of the upstream Omarchy repo:

- **`install/omarchy-base.packages`** — the canonical default package list.
- **`applications/*.desktop`** — current webapp and TUI launchers.
- **`install/user/mise.sh`** and **`bin/omarchy-mise-install`** — current CLI
  names and wrapper contents. Also check `bin/omarchy-install-hermes-cli`.
- **`default/hypr/bindings/applications.lua`** — packaged application bindings.
- Legacy sources include `install/packaging/webapps.sh`,
  `install/packaging/npx.sh`, and `bin/omarchy-npx-install`.
- **`bin/omarchy-remove-preinstalls`** — Omarchy's *own* "remove the preinstalls"
  command. Its `omarchy-pkg-drop ...` list is the best signal for which packages
  Omarchy itself considers safely removable; keep `DEFAULT_APPS`' active entries
  aligned with it. It also drops CLI stubs and all webapps/TUIs.

Released `v4.0.x` tags come from a release branch that descends from v4.0.0,
while `quattro` carries the next feature release. Compare against the tag for the
version you are claiming; a `quattro` snapshot does not describe a release.

`DEFAULT_APPS` keeps an *active* set (uncommented, the common "I don't want this"
apps) plus a large *commented* catalogue of every remaining Omarchy default, so a
user can uncomment to expand the offering. Webapps are matched by `.desktop`
filename, packages by `pacman -Qi`, npm CLIs by their `~/.local/bin` stub — so
each entry must be the exact package name / webapp display name / command name
Omarchy uses.

Some entries are intentionally kept even though they're no longer in the *current*
`omarchy-base.packages` — e.g. the `ghostty` / `alacritty` terminals, which older
Omarchy installs shipped before `foot` became the default. Every entry is gated on
detection (`pacman -Qi` / `.desktop` / stub), so a package that isn't installed is
simply never offered. When syncing the list against upstream, **add** newly-default
packages but don't blindly **drop** ones that vanished from base — older systems
may still have them.

### Beyond Omarchy's own remover

Omarchy ships `omarchy-remove-preinstalls`, but it is **all-or-nothing**: it wipes
*every* webapp and TUI, sets the `preinstalls-removed` state marker to disable
all preinstalled app bindings, and drops a fixed package set. Omarchy Cleaner
deliberately goes further:

- **Selective** — fuzzy multi-select exactly which packages / webapps / npm CLIs
  to remove, nothing pre-selected.
- **Surgical binding cleanup** — instead of replacing the whole bindings file, it
  strips only matching user bindings and prepends unbinds for packaged defaults
  (with a timestamped backup), supporting Lua and legacy `.conf` formats.
- **Three categories in one pass** — packages, webapp/TUI launchers, and CLI wrappers.

Keep parity with Omarchy's drop list as a *floor*, not a ceiling: when syncing,
make sure everything `omarchy-remove-preinstalls` removes is offered here too, then
keep the extra reach.

### Privilege model

The script runs unprivileged. Only `pacman -Rns` needs root, so `remove_packages`
prompts for `sudo` once up front (`sudo -n true` check, then `sudo true`) and
reuses the cached credential for one transaction containing all selected packages.
Before that, `find_blocked_packages` runs a `pacman -Rs --print` dry run without
sudo; packages it reports as still required are kept and explained, never
removed by also removing their dependents.
Webapp/TUI removal, CLI-wrapper deletion, and
binding edits are all in the user's `$HOME` and never touch root. Keep this split
— do not run the whole script under sudo.

### Selection plumbing

Packages, desktop launchers, and CLI wrappers travel through one array, separated by
the literal `--webapps--` and `--npmclis--` sentinels (always in that order),
because Bash can't pass several arrays cleanly. TUIs share the `--webapps--`
section; its internal variable names are retained for compatibility.
`parse_sections` is the single place that splits them back out — use it rather than re-scanning for sentinels.
Selected results come back as **newline-delimited strings** (`SELECTED_PACKAGES` /
`SELECTED_WEBAPPS` / `SELECTED_NPMCLIS`), not space-separated, specifically so
webapp names with spaces ("Google Photos") survive. Preserve that when touching
the select/parse code, and keep quoting names everywhere they're passed to a
command.

### Keyboard-binding cleanup (dual-format)

If selected apps have Hyprland keybinds, the script offers to strip them from the
user's bindings file (timestamped backup first). `BINDINGS_FILE` is auto-detected
at startup: Omarchy migrated Hyprland config from `*.conf` to `*.lua`, so it
prefers `~/.config/hypr/bindings.lua` and falls back to the legacy
`bindings.conf`.

On Quattro, defaults live under `$OMARCHY_PATH/default/hypr/bindings/` (falling
back to `/usr/share/omarchy`), and the user file contains overrides. Prepend
`hl.unbind("KEY")` before those overrides; appending would disable replacement
shortcuts. Never edit packaged config or disable every preinstall binding.

`find_app_bindings` matches both formats:

- **Lua**: `o.bind("KEY", "Label", { launch/tui/omarchy = "app", ... })` and
  `{ webapp = "https://..." }`.
- **.conf**: `bindd = ..., exec, <launcher> ...` (`uwsm-app --`,
  `omarchy-launch-or-focus`, `omarchy-launch-tui`, `omarchy-launch-webapp`, etc.).

Native apps are matched via `app_tokens_for` (`1password-cli` → `op`, Docker
plugins → their own commands/subcommands). Removing a plugin must preserve
Docker/lazydocker shortcuts; removing the CLI must preserve 1Password GUI
shortcuts. Keep the exact catalogue case when mapping commands: the `Docker`
desktop launcher must not claim the `docker` engine's bindings. Webapps are
matched via `webapp_domains_for` (the
binding must invoke a webapp launcher *and* carry a URL on a matching domain).
Removal uses matched line numbers and leaves multiline/computed Lua alone.
Long comments and strings are skipped using their exact delimiters. Webapp URLs
are matched by hostname, not substrings. CLI wrappers skip binding cleanup.

### Safety

Removal is irreversible (`pacman -Rns` purges configs + unused deps), so there is
a final itemised confirmation before anything is touched, nothing is selected by
default, and existing bindings files are always backed up before edits. Abort
binding edits if backup, write, or replacement fails; report partial success if
removal succeeded but cleanup did not. Never clean shortcuts for failed removals.
Pass removal targets as quoted arguments, never interpolated `bash -c` code.
Preserve these guardrails.

## Build & Run

There is nothing to build. To exercise changes:

```bash
bash -n omarchy-cleaner.sh        # syntax check (run this after every edit)
shellcheck omarchy-cleaner.sh     # lint, if installed
python3 -m unittest discover -s tests -v  # isolated regression checks
./omarchy-cleaner.sh              # real TUI: use a disposable Omarchy VM
```

When testing logic that would actually uninstall things, test on a throwaway
Omarchy VM/container or stub `pacman`/`omarchy-webapp-remove`, rather than on a
working machine.

### Required VM validation for runtime changes and PR reviews

Use the [omarchy-vm-testing skill](skills/omarchy-vm-testing/SKILL.md) when
changing or reviewing runtime behavior: catalogue/detection, selection,
confirmation, removal, privileges, bindings, or TUI output. Run the isolated
regression suite inside a configured disposable Omarchy VM and exercise the
affected real workflow before reporting the change as validated. Host tests alone do not
establish live Omarchy compatibility. Documentation-only changes do not require
booting or resetting the VM.

Read `.local/omarchy-vm.md` at the repository root for this machine's VM access
and recovery instructions. This file and other `.local/` contents are Git-ignored.
Keep machine-specific paths, host/container names, connection details, credential
locations, and local recovery history there, never in committed files or public
test reports. Never store credential values in documentation. If the local file
is missing, report VM setup as unavailable rather than guessing access details.

Run the cleaner inside the **VM guest**. A container hosting a hypervisor may
still access host files; do not run real removals in that container or on the host.

Test the exact PR revision or current working-tree files, including uncommitted
changes. Follow the skill for safe snapshot use, credential handling, evidence,
and recovery. Preserve unrelated guest work before resetting it. If the VM is
unavailable, complete independent checks and explicitly report live validation
as blocked; do not claim a VM pass from stubbed tests.

## Coding Style

- Plain Bash, 4-space indent, `snake_case` function names. The script does **not**
  use `set -euo pipefail` — several routines rely on empty-array expansion and
  non-zero exits as control flow, so don't add strict mode without auditing those.
- All user-facing output goes through `gum` (`gum style`, `gum log --level
  info|warn|error`, `gum spin`, `gum confirm`, `gum filter`). Match the existing
  256-colour palette (e.g. 39 blue, 51 cyan, 82 green, 214 orange, 196 red).
- Keep the ASCII banner identical between `main` and `show_main_header`.
- Quote every variable, and keep webapp names quoted through removal — names
  contain spaces.
- When adding items, match Omarchy's own naming exactly: packages go in
  `DEFAULT_APPS` (active or commented) as they appear in `omarchy-base.packages`;
  webapps go in `DEFAULT_WEBAPPS` and TUIs in `DEFAULT_TUIS` by desktop basename.
  CLI wrappers go in `DEFAULT_NPM_CLIS` by command name (second arg to
  `omarchy-mise-install`, defaulting to the package name); update the explicit
  mapping in `cli_packages_for` and verify the full upstream wrapper template.
  A webapp that's added also needs a `webapp_domains_for` entry for binding cleanup to
  find it.

## Agent behaviour

- **Never** add `Co-Authored-By` or other tool-attribution trailers to commit
  messages. Keep messages concise: a clear subject line and a short body
  explaining the why when it isn't obvious.
- Commit and push only when asked; otherwise leave the tree for the maintainer.
- When syncing the app/webapp lists, re-read the upstream sources above
  from the local Omarchy clone rather than trusting this file — Omarchy changes
  its defaults frequently (packages get renamed, moved to mise, or dropped).
- After any edit, run `bash -n omarchy-cleaner.sh` before reporting done.
