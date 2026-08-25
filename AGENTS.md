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
DEFAULT_NPM_CLIS[]      Omarchy CLI tools (codex, gemini, opencode, ...),
                        installed as mise (Omarchy 4) or pnpm-dlx (Omarchy 3)
                        stubs in ~/.local/bin (not pacman). Internal sentinel
                        remains --npmclis--.

is_package_installed    pacman -Qi probe.
is_webapp_installed     Checks ~/.local/share/applications/<name>.desktop.
is_npm_cli_installed    Checks ~/.local/bin/<cmd> AND that it's an Omarchy
                        stub (greps "pnpm dlx" or "mise") so unrelated user
                        binaries are safe.
get_installed_*         Filter each DEFAULT_* list down to what's installed.
                        Webapps also appear if a packaged default keybind
                        exists (ChatGPT/Grok on Omarchy 4 have binds but no
                        .desktop).
parse_sections          Splits a combined "items + --webapps-- + --npmclis--"
                        array into PARSED_PACKAGES/WEBAPPS/NPMCLIS globals. Used
                        by both the selector and the remover.

webapp_domains_for      Maps a webapp name -> URL domain(s) that identify it.
app_tokens_for          Maps a package -> the token(s) its keybind references
                        (1password-beta -> 1password; docker*/lazydocker ->
                        docker, lazydocker, omarchy-launch-docker-tui;
                        moonlight-qt -> moonlight).
find_bindings_in_file   Shared matcher for one file: Lua o.bind (launch/tui/
                        omarchy/webapp) and legacy bindd = lines.
find_app_bindings       User bindings.lua / bindings.conf.
find_packaged_unbind_keys  Keys from packaged default/hypr/bindings/
                        applications.lua (Omarchy 4).
remove_bindings_from_file  Backs up $BINDINGS_FILE, then strips matched lines
                        (3.x / user overrides).
append_lua_unbinds      Appends hl.unbind("KEY") to the user bindings.lua for
                        packaged defaults. Never edits packaged files.

enhanced_select_packages   The gum fuzzy multi-select. Items arrive in one array
                        split by "--webapps--"/"--npmclis--" sentinels; prefixed
                        📦/🌐/⬢ and marked ⌨ if they have a keybind. Sets globals
                        SELECTED_PACKAGES / SELECTED_WEBAPPS / SELECTED_NPMCLIS
                        (newline-delimited, to survive names with spaces).
remove_webapps          Loops omarchy-webapp-remove with progress bar (skips
                        if no .desktop — unbind-only).
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
- **`applications/*.desktop`** — the default webapps (display names are the
  `.desktop` basename; copied to `~/.local/share/applications` by
  `omarchy-refresh-applications`).
- **`install/user/mise.sh`** — default CLI stubs (`omarchy-mise-install`).
- **`bin/omarchy-remove-preinstalls`** — Omarchy's *own* "remove the preinstalls"
  command. Its `omarchy-pkg-drop ...` list is the best signal for which packages
  Omarchy itself considers safely removable; keep `DEFAULT_APPS`' active entries
  aligned with it. It also drops CLI stubs and all webapps/TUIs.
- **`default/hypr/bindings/applications.lua`** — packaged app/webapp keybinds
  (user `~/.config/hypr/bindings.lua` is overrides only on Omarchy 4).

`DEFAULT_APPS` keeps an *active* set (uncommented, the common "I don't want this"
apps) plus a large *commented* catalogue of every remaining Omarchy default, so a
user can uncomment to expand the offering. Webapps are matched by `.desktop`
filename (or a packaged default keybind), packages by `pacman -Qi`, CLI tools
by their `~/.local/bin` stub — so each entry must be the exact package name /
webapp display name / command name Omarchy uses.

Some entries are intentionally kept even though they're no longer in the *current*
`omarchy-base.packages` — e.g. the `ghostty` / `alacritty` terminals, which older
Omarchy installs shipped before `foot` became the default. Every entry is gated on
detection (`pacman -Qi` / `.desktop` / stub), so a package that isn't installed is
simply never offered. When syncing the list against upstream, **add** newly-default
packages but don't blindly **drop** ones that vanished from base — older systems
may still have them.

### Beyond Omarchy's own remover

Omarchy ships `omarchy-remove-preinstalls`, but it is **all-or-nothing**: it wipes
*every* webapp and TUI, sets `~/.local/state/omarchy/preinstalls-removed` (which
disables *all* packaged preinstall binds), and drops a fixed package set.
Omarchy Cleaner deliberately goes further:

- **Selective** — fuzzy multi-select exactly which packages / webapps / CLI tools
  to remove, nothing pre-selected.
- **Surgical binding cleanup** — instead of disabling every preinstall bind, it
  strips matching lines from the user bindings file (3.x / overrides) and
  appends `hl.unbind("KEY")` for packaged Omarchy 4 defaults (timestamped
  backup). Supports both `.lua` and legacy `.conf`.
- **Three categories in one pass** — pacman packages, webapps, and CLI stubs.

Keep parity with Omarchy's drop list as a *floor*, not a ceiling: when syncing,
make sure everything `omarchy-remove-preinstalls` removes is offered here too, then
keep the extra reach.

### Privilege model

The script runs unprivileged. Only `pacman -Rns` needs root, so `remove_packages`
prompts for `sudo` once up front (`sudo -n true` check, then `sudo true`) and
reuses the cached credential for the loop. Webapp removal, CLI-stub deletion, and
binding edits are all in the user's `$HOME` and never touch root. Keep this split
— do not run the whole script under sudo.

### Selection plumbing

Packages, webapps, and CLI tools travel together through one array, separated by
the literal `--webapps--` and `--npmclis--` sentinels (always in that order),
because Bash can't pass several arrays cleanly. `parse_sections` is the single
place that splits them back out — use it rather than re-scanning for sentinels.
Selected results come back as **newline-delimited strings** (`SELECTED_PACKAGES` /
`SELECTED_WEBAPPS` / `SELECTED_NPMCLIS`), not space-separated, specifically so
webapp names with spaces ("Google Photos") survive. Preserve that when touching
the select/parse code, and keep quoting names everywhere they're passed to a
command.

### Keyboard-binding cleanup (user file + packaged defaults)

If selected apps have Hyprland keybinds, the script offers to clean them up
(timestamped backup first). `BINDINGS_FILE` is auto-detected at startup: Omarchy
migrated Hyprland config from `*.conf` to `*.lua`, so it prefers
`~/.config/hypr/bindings.lua` and falls back to the legacy `bindings.conf`.

On **Omarchy 4**, default app/webapp binds live in packaged
`$OMARCHY_PATH/default/hypr/bindings/applications.lua` (typically
`/usr/share/omarchy/...`). The user file is overrides only, so stripping lines
there does nothing for stock binds. For those, append `hl.unbind("KEY")` to the
user `bindings.lua`. Do **not** edit packaged files, and do **not** set
`omarchy_preinstalled_bindings = false` (that kills every preinstall bind).

`find_bindings_in_file` matches both formats:

- **Lua**: `o.bind("KEY", "Label", { launch/tui/omarchy = "app", ... })` and
  `{ webapp = "https://..." }`.
- **.conf**: `bindd = ..., exec, <launcher> ...` (`uwsm-app --`,
  `omarchy-launch-or-focus`, `omarchy-launch-tui`, `omarchy-launch-webapp`, etc.).

Native apps are matched via `app_tokens_for` (handles `1password-*` → `1password`,
`docker*`/`lazydocker` → `docker`/`lazydocker`/`omarchy-launch-docker-tui`,
`moonlight-qt` → `moonlight`, `signal-desktop` → `signal`); webapps via
`webapp_domains_for` (the binding must
invoke a webapp launcher *and* carry a URL on a matching domain). User-file
removal is line-based. CLI stubs have no keybinds and are skipped.

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
  webapps go in `DEFAULT_WEBAPPS` by display name (`.desktop` basename under
  `applications/`); CLI tools go in `DEFAULT_NPM_CLIS` by command name (second
  arg to `omarchy-mise-install`, defaulting to the package name). A webapp
  that's added also needs a `webapp_domains_for` entry for binding cleanup to
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
