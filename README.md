# Omarchy Cleaner

A text-based interactive shell script to remove unwanted default applications and webapps from Omarchy Linux installations.

![Screenshot of Omarchy Cleaner.](./screenshot.png)

## Quick Start

Run directly without downloading:

```bash
curl -fsSL https://raw.githubusercontent.com/maxart/omarchy-cleaner/main/omarchy-cleaner.sh | bash
```


## Features

- **Interactive Text Interface**: Clean, colorful text-based UI with item selection
- **Dual Removal**: Removes both regular packages (via pacman) and webapps (via omarchy-webapp-remove)
- **Selective Removal**: Choose which applications and webapps to remove using number keys
- **Safe Operation**: Multiple confirmation steps before removing packages

## Usage

The script will:
1. Check for installed packages and webapps from its removal lists
2. Present a checklist where you can select which items to remove
3. Display both regular apps and webapps in separate sections
4. Ask for confirmation before removal
5. Request sudo privileges if needed for package removal
6. Remove selected packages and webapps, showing the results

## Customizing the Lists

The script includes comprehensive lists of Omarchy's default packages and webapps. You can customize which items are offered for removal by editing the arrays in the script:

### Regular Applications
```bash
DEFAULT_APPS=(
    # Packages offered for removal
    "1password-beta"
    "1password-cli"
    "kdenlive"
    "libreoffice"
    "localsend"
    "obs-studio"
    "obsidian"
    "omarchy-chromium"
    "signal-desktop"
    "spotify"
    "xournalpp"
    
    # Additional packages can be uncommented to include them
    # See the full list of Omarchy default packages in the script
)
```

### Webapps
```bash
DEFAULT_WEBAPPS=(
    "HEY"
    "Basecamp"
    "WhatsApp"
    "Discord"
    # ...
)
```

Simply uncomment or comment out items in these lists to customize what the cleaner offers to remove. The script contains the full list of all Omarchy default packages (100+ items), with only commonly unwanted applications active by default.


## License

Omarchy Cleaner is released under the [MIT License](https://opensource.org/licenses/MIT).