# AGENTS.md

## Project Overview

Omarchy Cleaner is an interactive shell script that removes unwanted default
applications and webapps from [Omarchy](https://github.com/basecamp/omarchy)
installations. It is a single self-contained Bash script meant to be run on a
freshly installed Omarchy system — typically piped straight from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/maxart/omarchy-cleaner/main/omarchy-cleaner.sh | bash
```

It uses [`gum`](https://github.com/charmbracelet/gum) (which ships with Omarchy)
for the whole TUI: the ASCII banner, the fuzzy multi-select list, spinners,
confirmation dialogs, and the success/partial/failure "hero" summary. There is
no compiled binary and no dependencies beyond what Omarchy already installs
(`gum`, `pacman`, and Omarchy's own `omarchy-webapp-remove` helper).

## Code Architecture

Everything lives in **`omarchy-cleaner.sh`**. The notable pieces, top to bottom:

```
Config block            VERSION; BINDINGS_FILE auto-detected (.lua preferred,
                        legacy .conf fallback); REMOVE_BINDINGS flag.
DEFAULT_APPS[]          pacman packages offered for removal (active + a large
                        commented catalogue of every other Omarchy default).
DEFAULT_WEBAPPS[]       Omarchy webapps offered for removal (by display name).
DEFAULT_NPM_CLIS[]      Omarchy npm CLI tools (codex, gemini, opencode, ...),
                        installed as pnpm-dlx stubs in ~/.local/bin (not pacman).

is_package_installed    pacman -Qi probe.
is_webapp_installed     Checks ~/.local/share/applications/<name>.desktop.
is_npm_cli_installed    Checks ~/.local/bin/<cmd> AND that it's a pnpm-dlx stub
                        (greps "pnpm dlx") so unrelated user binaries are safe.
get_installed_*         Filter each DEFAULT_* list down to what's installed.
parse_sections          Splits a combined "items + --webapps-- + --npmclis--"
                        array into PARSED_PACKAGES/WEBAPPS/NPMCLIS globals. Used
                        by both the selector and the remover.

webapp_domains_for      Maps a webapp name -> URL domain(s) that identify it.
app_tokens_for          Maps a package -> the token(s) its keybind references
                        (1password-beta -> 1password; docker* -> docker lazydocker).
find_app_bindings       Finds keybinds that launch a given app/webapp, in BOTH
                        the current Lua format (o.bind(..., { launch/tui/webapp }))
                        and the legacy .conf format (bindd = ..., exec, ...).
remove_bindings_from_file  Backs up $BINDINGS_FILE, then strips matched lines.

enhanced_select_packages   The gum fuzzy multi-select. Items arrive in one array
                        split by "--webapps--"/"--npmclis--" sentinels; prefixed
                        📦/🌐/⬢ and marked ⌨ if they have a keybind. Sets globals
                        SELECTED_PACKAGES / SELECTED_WEBAPPS / SELECTED_NPMCLIS
                        (newline-delimited, to survive names with spaces).
remove_webapps          Loops omarchy-webapp-remove with progress bar.
remove_npm_clis         Deletes the ~/.local/bin stubs (no sudo) with progress bar.
remove_packages         Acquires sudo, loops sudo pacman -Rns with progress bar.
remove_items            parse_sections, then binding removal + all three removers,
                        then prints the success / partial / failure hero box.
main                    Banner → scan → select → keybind prompt → confirm → remove.
```

There are no functions outside this file and no test suite — verification is by
running the script (see Build & Run).

## Design and Concepts

### What "Omarchy default" means

The two lists are the heart of the tool and must track upstream Omarchy. The
sources of truth, in the cloned Omarchy repo (`~/dev/omarchy`):

- **`install/omarchy-base.packages`** — the canonical default package list.
- **`install/packaging/webapps.sh`** — the default webapps (display names are the
  first argument to `omarchy-webapp-install`).
- **`bin/omarchy-remove-preinstalls`** — Omarchy's *own* "remove the preinstalls"
  command. Its `omarchy-pkg-drop ...` list is the best signal for which packages
  Omarchy itself considers safely removable; keep `DEFAULT_APPS`' active entries
  aligned with it. It also drops npm CLI stubs and all webapps/TUIs.

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
*every* webapp and TUI, replaces `bindings.lua` wholesale with `plain-bindings.lua`,
and drops a fixed package set. Omarchy Cleaner deliberately goes further:

- **Selective** — fuzzy multi-select exactly which packages / webapps / npm CLIs
  to remove, nothing pre-selected.
- **Surgical binding cleanup** — instead of replacing the whole bindings file, it
  finds and strips only the keybinds belonging to the items being removed (with a
  timestamped backup), and supports both the `.lua` and legacy `.conf` formats.
- **Three categories in one pass** — pacman packages, webapps, and npm-CLI stubs.

Keep parity with Omarchy's drop list as a *floor*, not a ceiling: when syncing,
make sure everything `omarchy-remove-preinstalls` removes is offered here too, then
keep the extra reach.

### Privilege model

The script runs unprivileged. Only `pacman -Rns` needs root, so `remove_packages`
prompts for `sudo` once up front (`sudo -n true` check, then `sudo true`) and
reuses the cached credential for the loop. Webapp removal, npm-stub deletion, and
binding edits are all in the user's `$HOME` and never touch root. Keep this split
— do not run the whole script under sudo.

### Selection plumbing

Packages, webapps, and npm CLIs travel together through one array, separated by
the literal `--webapps--` and `--npmclis--` sentinels (always in that order),
because Bash can't pass several arrays cleanly. `parse_sections` is the single
place that splits them back out — use it rather than re-scanning for sentinels.
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
`bindings.conf`. `find_app_bindings` matches both formats:

- **Lua**: `o.bind("KEY", "Label", { launch/tui/omarchy = "app", ... })` and
  `{ webapp = "https://..." }`.
- **.conf**: `bindd = ..., exec, <launcher> ...` (`uwsm-app --`,
  `omarchy-launch-or-focus`, `omarchy-launch-tui`, `omarchy-launch-webapp`, etc.).

Native apps are matched via `app_tokens_for` (handles `1password-*` → `1password`
and `docker*` → `docker`/`lazydocker`); webapps via `webapp_domains_for` (the
binding must invoke a webapp launcher *and* carry a URL on a matching domain).
Removal is line-based, which is safe for both formats since each binding is one
line. npm CLIs have no keybinds and are skipped.

### Safety

Removal is irreversible (`pacman -Rns` purges configs + unused deps), so there is
a final itemised confirmation before anything is touched, nothing is selected by
default, and bindings.conf is always backed up before edits. Preserve these
guardrails.

## Build & Run

There is nothing to build. To exercise changes:

```bash
bash -n omarchy-cleaner.sh        # syntax check (run this after every edit)
shellcheck omarchy-cleaner.sh     # lint, if installed
./omarchy-cleaner.sh              # run the real TUI (will offer to remove pkgs!)
```

When testing logic that would actually uninstall things, test on a throwaway
Omarchy VM/container or stub `pacman`/`omarchy-webapp-remove`, rather than on a
working machine.

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
  webapps go in `DEFAULT_WEBAPPS` by display name (first arg to
  `omarchy-webapp-install`); npm CLIs go in `DEFAULT_NPM_CLIS` by command name
  (second arg to `omarchy-npm-install`, defaulting to the package name). A webapp
  that's added also needs a `webapp_domains_for` entry for binding cleanup to
  find it.

## Agent behaviour

- **Never** add `Co-Authored-By` or other tool-attribution trailers to commit
  messages. Keep messages concise: a clear subject line and a short body
  explaining the why when it isn't obvious.
- Commit and push only when asked; otherwise leave the tree for the maintainer.
- When syncing the app/webapp lists, re-read the three upstream sources above
  from the local Omarchy clone rather than trusting this file — Omarchy changes
  its defaults frequently (packages get renamed, moved to npm, or dropped).
- After any edit, run `bash -n omarchy-cleaner.sh` before reporting done.
