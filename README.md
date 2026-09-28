# Omarchy Cleaner

> If Omarchy is the omakase of Linux distros, a curated feast of pre-installed apps and webapps, Omarchy Cleaner is your trusty pair of chopsticks to pluck away the unwanted wasabi for a perfectly tailored system. 🥢

An interactive shell script to remove unwanted default applications and webapps from Omarchy installations with a clean, visual interface.

![Screenshot of Omarchy Cleaner.](./screenshot.png)

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/maxart/omarchy-cleaner/main/omarchy-cleaner.sh | bash
```

## How It Works

The script scans for Omarchy's default **packages**, **desktop launchers (webapps and TUIs)**, and **CLI wrappers**, then lets you choose what to remove. Nothing is preselected, and an itemized confirmation comes before removal.

Omarchy 4 (Quattro) is supported alongside older installations. Shortcut cleanup removes matching single-line bindings from your personal config and disables packaged defaults in your `bindings.lua`, before your personal overrides. Packaged Omarchy files stay intact. Existing configs receive a unique timestamped backup before edits, and shortcuts are cleaned only after the associated removal succeeds. Multiline/computed Lua bindings and ambiguous long-string layouts are left for manual editing.

Items marked **shortcut only** have a packaged shortcut but no desktop launcher. They are skipped if you decline shortcut cleanup. CLI removal deletes only recognized Omarchy wrappers in `~/.local/bin`; installed mise/npm runtimes, caches, and application data remain. Customized wrappers and symlinks are left alone.

Packages are removed in one `pacman -Rns` transaction, including unused dependencies and package backup configs. Only this step uses sudo; the script runs as your normal user.

## Customization

Edit `DEFAULT_APPS`, `DEFAULT_WEBAPPS`, `DEFAULT_TUIS`, and `DEFAULT_NPM_CLIS` in the script to customize the offering. The active package list covers Omarchy's own removable defaults, with additional applications and detected leftovers from older releases. Other default packages remain as commented entries you can uncomment.

## Upstream sources

The catalogues track Omarchy's [base packages](https://github.com/omacom/omarchy/blob/quattro/install/omarchy-base.packages), [desktop launchers](https://github.com/omacom/omarchy/tree/quattro/applications), [CLI installers](https://github.com/omacom/omarchy/blob/quattro/install/user/mise.sh), and [Remove Preinstalls command](https://github.com/omacom/omarchy/blob/quattro/bin/omarchy-remove-preinstalls). Packaged shortcuts come from [applications.lua](https://github.com/omacom/omarchy/blob/quattro/default/hypr/bindings/applications.lua).

## Verification

```bash
bash -n omarchy-cleaner.sh
shellcheck omarchy-cleaner.sh
python3 -m unittest discover -s tests -v
```

Tests use temporary home directories and stubbed system commands, so they do not uninstall software. Their upstream fixtures cover Quattro 4.0.0/4.0.2/4.0.4, current Quattro catalogue additions, and the legacy 3.8.4 npx installer. See [fixture provenance](tests/fixtures/README.md) and the [Quattro review](docs/quattro-review.md). A live TUI/removal smoke test belongs on a disposable Omarchy VM.

## License

 Omarchy Cleaner is released under the [MIT License](https://opensource.org/licenses/MIT).
