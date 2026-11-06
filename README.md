# Omarchy Cleaner

Choose which default [Omarchy](https://github.com/omacom/omarchy) packages, webapps, terminal launchers, and CLI tools to remove through an interactive terminal menu.

## Run

Run as your normal user in an Omarchy terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/maxart/omarchy-cleaner/main/omarchy-cleaner.sh | bash
```

Type to filter, press Tab to select items, then Enter to review descriptions and confirm. Nothing is preselected.

Cleaner 3.3 is live-tested on Omarchy **4.5.0 and 4.0.6**. See the [compatibility and validation report](docs/v4.5.0-compatibility.md) for coverage and limitations.

## What removal does

- **Packages:** previews the complete removal, keeps packages still required by other installed packages, then runs one `pacman -Rns` transaction with sudo. This removes unused dependencies and package backup configs too. A failed preview aborts removal; a changed plan keeps packages and their shortcuts. Avoid running another package manager during cleanup.
- **Webapps and terminal launchers:** removes selected launchers through Omarchy's helpers. Items labelled **shortcut only** require shortcut-cleanup consent.
- **Individual CLI entries:** deletes recognized legacy wrappers in `~/.local/bin`. Customized files and symlinks stay.
- **Omarchy default CLI tools (all):** opts out of the entire 4.5 default mise tool set, **including Node.js and uv**. Confirmation lists every tool. Individual lazy defaults cannot be removed separately. Installed tools, caches, personal/project declarations, and unselected legacy wrappers stay.

Optional shortcut cleanup backs up your bindings, removes supported literal bindings, and disables packaged shortcuts before your personal overrides. It runs only for successful removals. Computed or multiline bindings need manual editing.

The CLI group also backs up existing mise settings and attempts recovery if shim refresh fails. Conflicting personal ignore lists and linked settings are refused.

## Customize the catalogue

Edit `DEFAULT_APPS`, `DEFAULT_WEBAPPS`, `DEFAULT_TUIS`, or `DEFAULT_NPM_CLIS` in the script. Uncomment package entries to expand the offering. Older entries remain available when detected; the 4.5 CLI group always covers the complete upstream declaration file.

Architecture-specific packages are grouped in a commented section. Some provide boot, firmware, graphics, or audio support; inclusion does not mean they are safe to remove.

## Development

Run the isolated checks:

```bash
bash -n omarchy-cleaner.sh
shellcheck omarchy-cleaner.sh
python3 -m unittest discover -s tests -v
```

Tests use temporary homes and stubbed removal commands. GitHub Actions runs these checks; real-gum selector tests run when `gum` is available. Runtime changes also require the [disposable VM workflow](skills/omarchy-vm-testing/SKILL.md).

See [contributor guidance](AGENTS.md), [fixture provenance](tests/fixtures/README.md), and [description sources](docs/item-descriptions.md).

## License

[MIT](LICENSE).
