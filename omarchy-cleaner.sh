#!/bin/bash

# Omarchy Cleaner - Remove unwanted default applications from Omarchy
# Enhanced with gum for a better TUI experience

# Version
VERSION="3.0"

# Configuration
# Omarchy migrated Hyprland config from *.conf to *.lua; support whichever the
# user has (prefer the current .lua format, fall back to legacy .conf).
BINDINGS_FILE=""
for candidate in "$HOME/.config/hypr/bindings.lua" "$HOME/.config/hypr/bindings.conf"; do
    if [[ -f "$candidate" ]]; then
        BINDINGS_FILE="$candidate"
        break
    fi
done
REMOVE_BINDINGS=false

# App
# List from: https://github.com/basecamp/omarchy/blob/master/install/omarchy-base.packages
# Apps Omarchy itself offers to drop live in: bin/omarchy-remove-preinstalls
DEFAULT_APPS=(
    # Packages offered for removal. Floor is Omarchy 4's omarchy-remove-preinstalls
    # drop list; extra reach (docker, chromium, …) stays offered too.
    "aether"
    "cliamp"
    "kdenlive"
    "libreoffice-fresh"
    "xournalpp"
    "pinta"
    "obsidian"
    "obs-studio"
    "moonlight-qt"
    "lazydocker"
    "omacut"
    "omacalc"
    "omawrite"

    "localsend"
    "chromium"
    "docker"
    "docker-buildx"
    "docker-compose"
    "gpu-screen-recorder"

    # No longer in Omarchy 4 base (moved to on-demand installs or replaced).
    # Only offered if actually installed — 3.x upgrades and optional installs.
    "1password-beta"
    "1password-cli"
    "signal-desktop"
    "spotify"
    "typora"
    "claude-code"

    # Terminals from older Omarchy versions (current default is foot).
    # Only offered if actually installed; remove only if you use another terminal.
    "ghostty"
    "alacritty"

    # Uncomment to include in removal list
    # "alsa-utils"
    # "asdcontrol"
    # "asdcontrol-git"
    # "avahi"
    # "bash-completion"
    # "bat"
    # "bluez"
    # "bluez-tools"
    # "bluez-utils"
    # "bluetui"
    # "bolt"
    # "brightnessctl"
    # "btop"
    # "clang"
    # "cups"
    # "cups-browsed"
    # "cups-filters"
    # "cups-pdf"
    # "cups-pk-helper"
    # "ddcutil"
    # "dosfstools"
    # "dotnet-runtime"
    # "dotnet-runtime-9.0"
    # "dua-cli"
    # "dust"
    # "evince"
    # "exfatprogs"
    # "expac"
    # "eza"
    # "fakeroot"
    # "fastfetch"
    # "fcitx5"
    # "fcitx5-gtk"
    # "fcitx5-qt"
    # "fd"
    # "ffmpegthumbnailer"
    # "fontconfig"
    # "foot"
    # "fzf"
    # "git"
    # "github-cli"
    # "gnome-calculator"
    # "gnome-disk-utility"
    # "gnome-keyring"
    # "gnome-themes-extra"
    # "grim"
    # "gum"
    # "gvfs-mtp"
    # "gvfs-nfs"
    # "gvfs-smb"
    # "herdr"
    # "hypridle"
    # "hyprland"
    # "hyprland-guiutils"
    # "hyprland-preview-share-picker"
    # "hyprlock"
    # "hyprpicker"
    # "hyprsunset"
    # "imagemagick"
    # "impala"
    # "imv"
    # "inetutils"
    # "inotify-tools"
    # "inxi"
    # "iwd"
    # "jq"
    # "kernel-modules-hook"
    # "kvantum-qt5"
    # "lazygit"
    # "less"
    # "libqalculate"
    # "libsecret"
    # "libvips"
    # "libyaml"
    # "llvm"
    # "lua51"
    # "luarocks"
    # "mako"
    # "man-db"
    # "mariadb-libs"
    # "mise"
    # "mise-bin"
    # "mpv"
    # "mpv-mpris"
    # "nautilus"
    # "nautilus-python"
    # "networkmanager"
    # "noto-fonts"
    # "noto-fonts-cjk"
    # "noto-fonts-emoji"
    # "noto-fonts-extra"
    # "nss-mdns"
    # "nvim"
    # "omarchy-nvim"
    # "omarchy-walker"
    # "pacman-contrib"
    # "pamixer"
    # "playerctl"
    # "plocate"
    # "plymouth"
    # "polkit-gnome"
    # "postgresql-libs"
    # "power-profiles-daemon"
    # "python-gobject"
    # "python-poetry-core"
    # "python-terminaltexteffects"
    # "qemu-user-static-binfmt"
    # "qrencode"
    # "qt5-wayland"
    # "qt6-imageformats"
    # "quickshell"
    # "quickshell-git"
    # "ripgrep"
    # "ruby"
    # "rust"
    # "satty"
    # "sddm"
    # "slurp"
    # "socat"
    # "starship"
    # "sushi"
    # "swaybg"
    # "swayosd"
    # "system-config-printer"
    # "tensaku"
    # "tesseract"
    # "tesseract-data-eng"
    # "tldr"
    # "tmux"
    # "tobi-try"
    # "tree-sitter-cli"
    # "ttf-cascadia-mono-nerd"
    # "ttf-ia-writer"
    # "ttf-jetbrains-mono-nerd"
    # "ttf-jetbrains-mono-nerd-basic"
    # "ttfx"
    # "tzupdate"
    # "udiskie"
    # "ufw"
    # "ufw-docker"
    # "unzip"
    # "usage"
    # "uwsm"
    # "waybar"
    # "wayfreeze"
    # "whois"
    # "wireless-regdb"
    # "wiremix"
    # "wireplumber"
    # "wl-clipboard"
    # "woff2-font-awesome"
    # "wtype"
    # "xdg-desktop-portal-gtk"
    # "xdg-desktop-portal-hyprland"
    # "xdg-terminal-exec"
    # "xmlstarlet"
    # "yaru-icon-theme"
    # "yay"
    # "yt-dlp"
    # "zbar"
    # "zoxide"
)

# Webapps
# List from: https://github.com/basecamp/omarchy/blob/master/applications
# (packaged .desktop files copied to ~/.local/share/applications).
DEFAULT_WEBAPPS=(
    "HEY"
    "Basecamp"
    "WhatsApp"
    "Google Photos"
    "Google Contacts"
    "Google Messages"
    "Google Maps"
    "YouTube"
    "X"
    "Zoom"
    "Discord"
    "Grok"
    # Dropped from Omarchy 4 defaults; still offered if a leftover .desktop exists.
    "ChatGPT"
    "GitHub"
    "Figma"
    "Fizzy"
)

# CLI tools
# List from: https://github.com/basecamp/omarchy/blob/master/install/user/mise.sh
# These are installed as mise (Omarchy 4) or pnpm-dlx (Omarchy 3) wrapper stubs
# in ~/.local/bin (not pacman), so they are removed by deleting the stub.
DEFAULT_NPM_CLIS=(
    "codex"
    "claude"
    "crush"
    "gemini"
    "gh"
    "copilot"
    "opencode"
    "playwright"
    "playwright-cli"
    "pi"
    "omp"
    "grok"
    "ghui"
    "hunk"
)

# Function to check if package is installed
is_package_installed() {
    local package="$1"
    pacman -Qi "$package" &>/dev/null
    return $?
}

# Function to check if webapp is installed
is_webapp_installed() {
    local webapp="$1"
    # Check if .desktop file exists for the webapp
    local desktop_file="$HOME/.local/share/applications/$webapp.desktop"
    [[ -f "$desktop_file" ]]
    return $?
}

# Function to check if a CLI tool stub is installed
is_npm_cli_installed() {
    local cmd="$1"
    local stub="$HOME/.local/bin/$cmd"
    [[ -f "$stub" ]] || return 1
    # Only treat Omarchy-generated wrappers as removable, so we never delete
    # an unrelated binary the user dropped in ~/.local/bin. Omarchy 4 uses
    # mise stubs; Omarchy 3 used pnpm dlx.
    grep -Eq "pnpm dlx|(^|[[:space:]])mise([[:space:]/\"']|$)" "$stub" 2>/dev/null
}

# Function to get list of installed packages from our removal list
get_installed_packages() {
    for app in "${DEFAULT_APPS[@]}"; do
        if is_package_installed "$app"; then
            echo "$app"
        fi
    done
}

# Function to get list of installed webapps from our removal list
get_installed_webapps() {
    for webapp in "${DEFAULT_WEBAPPS[@]}"; do
        if is_webapp_installed "$webapp"; then
            echo "$webapp"
        elif [[ -n "$(find_packaged_unbind_keys "$webapp")" ]]; then
            # Omarchy 4 dropped some launcher entries (ChatGPT, Grok) but kept
            # packaged keybinds — still offer those for unbind-only cleanup.
            echo "$webapp"
        fi
    done
}

# Function to get list of installed CLI tools from our removal list
get_installed_npm_clis() {
    for cli in "${DEFAULT_NPM_CLIS[@]}"; do
        if is_npm_cli_installed "$cli"; then
            echo "$cli"
        fi
    done
}

# Splits a combined "items + sentinel sections" array into globals.
# Layout: packages, then optional "--webapps--" section, then optional
# "--npmclis--" section. Used by both the selector and the remover.
parse_sections() {
    PARSED_PACKAGES=()
    PARSED_WEBAPPS=()
    PARSED_NPMCLIS=()
    local section="package"
    local item
    for item in "$@"; do
        case "$item" in
            "--webapps--") section="webapp"; continue ;;
            "--npmclis--") section="npmcli"; continue ;;
        esac
        case "$section" in
            package) PARSED_PACKAGES+=("$item") ;;
            webapp)  PARSED_WEBAPPS+=("$item") ;;
            npmcli)  PARSED_NPMCLIS+=("$item") ;;
        esac
    done
}

# Map a webapp name to the URL domain(s) that identify its binding.
webapp_domains_for() {
    case "$1" in
        "hey")             echo "app.hey.com|hey.com" ;;
        "basecamp")        echo "basecamp.com|37signals.com|launchpad" ;;
        "whatsapp")        echo "web.whatsapp.com|whatsapp.com" ;;
        "google photos")   echo "photos.google.com" ;;
        "google contacts") echo "contacts.google.com" ;;
        "google messages") echo "messages.google.com" ;;
        "chatgpt")         echo "chatgpt.com|chat.openai.com" ;;
        "youtube")         echo "youtube.com|youtu.be" ;;
        "github")          echo "github.com" ;;
        "x")               echo "x.com|twitter.com" ;;
        "figma")           echo "figma.com" ;;
        "discord")         echo "discord.com|discord.gg" ;;
        "fizzy")           echo "app.fizzy.do|fizzy.do" ;;
        "google maps")     echo "maps.google.com" ;;
        "zoom")            echo "zoom.us|zoom.com" ;;
        "grok")            echo "grok.com" ;;
        *)                 echo "" ;;
    esac
}

# Map a package name to the token(s) its keybinding references. Packages and
# their launch tokens don't always match (1password-beta -> 1password). Docker
# was bound as lazydocker in Omarchy 4.0.0 and as omarchy-launch-docker-tui
# from 4.0.1 (polkit wrapper after docker-group membership became opt-in).
app_tokens_for() {
    case "$1" in
        1password-beta|1password-cli)                         echo "1password" ;;
        docker|docker-buildx|docker-compose|lazydocker)       echo "docker lazydocker omarchy-launch-docker-tui" ;;
        moonlight-qt)                                         echo "moonlight" ;;
        signal-desktop)                                       echo "signal" ;;
        herdr)                                                echo "herdr terminal-herdr" ;;
        *)                                                    echo "$1" ;;
    esac
}

# Function to find keyboard bindings for an app/webapp in a single file.
# Handles both the current Lua format (o.bind("...", "...", { launch = "app" }))
# and the legacy bindings.conf format (bindd = ..., exec, uwsm-app -- app).
find_bindings_in_file() {
    local app_name="$1"
    local bindings_file="$2"
    local bindings=()

    if [[ ! -f "$bindings_file" ]]; then
        echo ""
        return
    fi

    local app_lower
    app_lower=$(echo "$app_name" | tr '[:upper:]' '[:lower:]')

    local webapp_domains
    webapp_domains=$(webapp_domains_for "$app_lower")

    local -a tokens
    read -r -a tokens <<< "$(app_tokens_for "$app_lower")"

    while IFS= read -r line; do
        # Skip blanks and comments (.conf '#' and .lua '--')
        [[ -z "${line// }" ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ ^[[:space:]]*-- ]] && continue

        # Only consider actual binding lines in either format
        [[ "$line" =~ ^[[:space:]]*bindd[[:space:]]*= ]] || [[ "$line" =~ o\.bind\( ]] || continue

        local line_lower
        line_lower=$(echo "$line" | tr '[:upper:]' '[:lower:]')

        if [[ -n "$webapp_domains" ]]; then
            # Webapp: the line must invoke a webapp launcher (.conf command or
            # .lua `webapp =`) AND reference a URL on a matching domain.
            if [[ "$line_lower" =~ (omarchy-launch-webapp|omarchy-launch-or-focus-webapp|webapp[[:space:]]*=) ]]; then
                if [[ "$line" =~ (https?://[^\"\ ]+) ]]; then
                    local url="${BASH_REMATCH[1]}"
                    if [[ "$url" =~ ($webapp_domains) ]]; then
                        bindings+=("$line")
                    fi
                fi
            fi
        else
            # Native app: match a launcher verb followed by one of the tokens,
            # across both config formats (including Omarchy 4's `omarchy =`).
            local tok
            for tok in "${tokens[@]}"; do
                local boundary="([\"[:space:]]|\$)"
                if [[ "$line_lower" =~ (launch|tui|omarchy)[[:space:]]*=[[:space:]]*\"$tok$boundary ]] \
                   || [[ "$line_lower" =~ or-focus[[:space:]]+$tok$boundary ]] \
                   || [[ "$line_lower" =~ omarchy-launch-tui[[:space:]]+$tok$boundary ]] \
                   || [[ "$line_lower" =~ omarchy-launch-or-focus-tui[[:space:]]+$tok$boundary ]] \
                   || [[ "$line_lower" =~ uwsm[-[:space:]]+app[[:space:]]+--[[:space:]]+$tok$boundary ]] \
                   || [[ "$line_lower" =~ \$terminal[[:space:]]+-e[[:space:]]+$tok$boundary ]]; then
                    bindings+=("$line")
                    break
                fi
            done
        fi
    done < "$bindings_file"

    if [[ ${#bindings[@]} -gt 0 ]]; then
        printf '%s\n' "${bindings[@]}" | sort -u
    fi
}

# User bindings file (overrides on Omarchy 4; full binds on 3.x).
find_app_bindings() {
    find_bindings_in_file "$1" "$BINDINGS_FILE"
}

# Packaged Omarchy 4 defaults live here, not in the user's bindings.lua.
packaged_applications_bindings_file() {
    local root="${OMARCHY_PATH:-/usr/share/omarchy}"
    local candidate="$root/default/hypr/bindings/applications.lua"
    if [[ -f "$candidate" ]]; then
        printf '%s\n' "$candidate"
        return 0
    fi
    return 1
}

extract_lua_bind_key() {
    local line="$1"
    if [[ "$line" =~ o\.bind\([[:space:]]*\"([^\"]+)\" ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
    fi
}

# Keys of packaged default binds for this app, to disable via hl.unbind.
find_packaged_unbind_keys() {
    local app_name="$1"
    local file
    file=$(packaged_applications_bindings_file) || return 0
    [[ -n "$file" ]] || return 0

    local keys=()
    local line key
    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        key=$(extract_lua_bind_key "$line")
        [[ -n "$key" ]] && keys+=("$key")
    done < <(find_bindings_in_file "$app_name" "$file")

    if [[ ${#keys[@]} -gt 0 ]]; then
        printf '%s\n' "${keys[@]}" | sort -u
    fi
}

item_has_bindings() {
    local item="$1"
    [[ -n "$(find_app_bindings "$item")" ]] && return 0
    [[ -n "$(find_packaged_unbind_keys "$item")" ]] && return 0
    return 1
}

count_item_bindings() {
    local item="$1"
    local n=0
    local bindings
    bindings=$(find_app_bindings "$item")
    if [[ -n "$bindings" ]]; then
        n=$((n + $(printf '%s\n' "$bindings" | wc -l)))
    fi
    bindings=$(find_packaged_unbind_keys "$item")
    if [[ -n "$bindings" ]]; then
        n=$((n + $(printf '%s\n' "$bindings" | wc -l)))
    fi
    printf '%s\n' "$n"
}

# Function to remove bindings from the config file
remove_bindings_from_file() {
    local bindings_to_remove=("$@")
    
    if [[ ${#bindings_to_remove[@]} -eq 0 ]]; then
        return 0
    fi
    
    if [[ ! -f "$BINDINGS_FILE" ]]; then
        gum log --level warn "Bindings file not found at $BINDINGS_FILE"
        return 1
    fi
    
    # Create backup
    local backup_file="${BINDINGS_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$BINDINGS_FILE" "$backup_file"
    gum log --level info "Created backup: $backup_file"
    
    # Create temporary file
    local temp_file=$(mktemp)
    local removed_count=0
    
    # Process the file line by line
    while IFS= read -r line; do
        local should_remove=false
        
        # Check if this line should be removed
        for binding in "${bindings_to_remove[@]}"; do
            if [[ "$line" == "$binding" ]]; then
                should_remove=true
                ((removed_count++))
                break
            fi
        done
        
        # Write line to temp file if not removing
        if [[ "$should_remove" == false ]]; then
            echo "$line" >> "$temp_file"
        fi
    done < "$BINDINGS_FILE"
    
    # Replace original file with temp file
    mv "$temp_file" "$BINDINGS_FILE"
    
    gum log --level info "✓ Removed $removed_count keyboard binding(s)"
    return 0
}

# Append hl.unbind(...) to the user's Lua bindings file for packaged defaults.
# Never edits the packaged applications.lua.
append_lua_unbinds() {
    local keys=("$@")
    local key lua_file
    local to_add=()

    if [[ ${#keys[@]} -eq 0 ]]; then
        return 0
    fi

    lua_file="$HOME/.config/hypr/bindings.lua"
    if [[ "$BINDINGS_FILE" == *.lua && -n "$BINDINGS_FILE" ]]; then
        lua_file="$BINDINGS_FILE"
    fi

    mkdir -p "$(dirname "$lua_file")"
    if [[ ! -f "$lua_file" ]]; then
        cat > "$lua_file" <<'EOF'
-- Keep only your personal keybinding overrides here.
EOF
    fi

    for key in "${keys[@]}"; do
        [[ -n "$key" ]] || continue
        if grep -Fq "hl.unbind(\"$key\")" "$lua_file" 2>/dev/null; then
            continue
        fi
        to_add+=("$key")
    done

    if [[ ${#to_add[@]} -eq 0 ]]; then
        gum log --level info "Packaged shortcuts already unbound"
        return 0
    fi

    local backup_file="${lua_file}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$lua_file" "$backup_file"
    gum log --level info "Created backup: $backup_file"

    {
        echo ""
        echo "-- Omarchy Cleaner: unbind packaged defaults for removed apps ($(date +%Y-%m-%d))"
        for key in "${to_add[@]}"; do
            printf 'hl.unbind("%s")\n' "$key"
        done
    } >> "$lua_file"

    gum log --level info "✓ Unbound ${#to_add[@]} packaged keyboard shortcut(s)"
    return 0
}


# Enhanced selection menu using gum with integrated keyboard toggle
enhanced_select_packages() {
    local installed_packages=("$@")
    local all_items=()
    local item_types=()
    local display_items=()
    local bindings_found=()
    
    # Split the combined argument list (packages, --webapps--, --npmclis--) into
    # typed items.
    parse_sections "${installed_packages[@]}"
    for item in "${PARSED_PACKAGES[@]}"; do
        all_items+=("$item")
        item_types+=("package")
    done
    for item in "${PARSED_WEBAPPS[@]}"; do
        all_items+=("$item")
        item_types+=("webapp")
    done
    for item in "${PARSED_NPMCLIS[@]}"; do
        all_items+=("$item")
        item_types+=("npmcli")
    done

    # Build display items with type indicators and binding markers
    for i in "${!all_items[@]}"; do
        local prefix=""
        case "${item_types[$i]}" in
            webapp) prefix="🌐 " ;;
            npmcli) prefix="⬢ " ;;
            *)      prefix="📦 " ;;
        esac

        # Check if this item has keyboard bindings (CLI stubs have none)
        local item_bindings=""
        if [[ "${item_types[$i]}" != "npmcli" ]]; then
            if item_has_bindings "${all_items[$i]}"; then
                item_bindings="yes"
            fi
        fi
        if [[ -n "$item_bindings" ]]; then
            bindings_found[$i]=1
            display_items+=("${prefix}${all_items[$i]} ⌨")
        else
            bindings_found[$i]=0
            display_items+=("${prefix}${all_items[$i]}")
        fi
    done
    
    # Check if any items have bindings
    local has_bindings=false
    for bf in "${bindings_found[@]}"; do
        [[ $bf -eq 1 ]] && has_bindings=true && break
    done
    
    # Function to display the main interface header
    show_main_header() {
        # Show header with style
        clear
        gum style \
            --foreground 39 \
            --align center \
            "   ____                            __         " \
            "  / __ \____ ___  ____ ___________/ /_  __  __" \
            " / / / / __ \`__ \/ __ \`/ ___/ ___/ __ \/ / / /" \
            "/ /_/ / / / / / / /_/ / /  / /__/ / / / /_/ / " \
            "\____/_/_/_/_/_/\__,_/_/   \___/_/ /_/\__, /  " \
            "      / ____/ /__  ____ _____  ___  _/____/   " \
            "     / /   / / _ \/ __ \`/ __ \/ _ \/ ___/     " \
            "    / /___/ /  __/ /_/ / / / /  __/ /         " \
            "    \____/_/\___/\__,_/_/ /_/\___/_/          "

        echo ""

        gum style \
            --foreground 237 \
            "═════════════════════════════════════════════════"
        
        echo ""
        
        # Show item counts
        local pkg_count=0
        local webapp_count=0
        local npm_count=0
        for type in "${item_types[@]}"; do
            case "$type" in
                package) ((pkg_count++)) ;;
                webapp)  ((webapp_count++)) ;;
                npmcli)  ((npm_count++)) ;;
            esac
        done

        local counts_msg="Found $pkg_count packages and $webapp_count webapps"
        if [[ $npm_count -gt 0 ]]; then
            counts_msg="$counts_msg and $npm_count CLI tools"
        fi
        gum style \
            --foreground 214 \
            --bold \
            "$counts_msg"
        
        echo ""
    }
    
    # App selection interface - no keyboard toggle here anymore
    while true; do
        show_main_header
        
        # Show help text for selection
        gum style \
            --foreground 51 \
            --italic \
            "Select items to remove (Tab to select, Enter to confirm)"
        
        if [[ "$has_bindings" == true ]]; then
            gum style \
                --foreground 39 \
                --italic \
                "(⌨ = has keyboard shortcuts - you'll be asked about cleanup next)"
        fi
        
        echo ""
        
        selected_items=$(printf '%s\n' "${display_items[@]}" | \
            gum filter \
                --limit 0 \
                --no-limit \
                --indicator " ▸" \
                --selected-prefix " ✓ " \
                --unselected-prefix "   " \
                --placeholder "Type to filter..." \
                --header "Select items to remove:" \
                --height 15)
        
        # Check if user cancelled
        if [[ $? -ne 0 ]]; then
            return 1
        fi
        
        # Check if no items selected
        if [[ -z "$selected_items" ]]; then
            echo ""
            gum style \
                --foreground 214 \
                "No items selected! Please select at least one item."
            echo ""
            echo "Press Enter to try again or Ctrl+C to exit..."
            if [[ -t 0 ]]; then
                read </dev/tty
            else
                echo "(Non-interactive mode, retrying...)"
                sleep 1
            fi
            # Continue loop to try again
            continue
        fi
        
        # Valid selection made, break out of loop
        break
    done
    
    # Parse selected items back to original names
    local selected_packages=()
    local selected_webapps=()
    local selected_npmclis=()

    while IFS= read -r selected_item; do
        # Remove emoji prefix (📦/🌐/⬢) and keyboard marker (⌨)
        local clean_item=$(echo "$selected_item" | sed 's/^[📦🌐⬢] //' | sed 's/ ⌨$//')

        # Find matching item in original arrays
        for i in "${!all_items[@]}"; do
            if [[ "${all_items[$i]}" == "$clean_item" ]]; then
                case "${item_types[$i]}" in
                    webapp) selected_webapps+=("$clean_item") ;;
                    npmcli) selected_npmclis+=("$clean_item") ;;
                    *)      selected_packages+=("$clean_item") ;;
                esac
                break
            fi
        done
    done <<< "$selected_items"

    # Use newline-delimited strings to preserve items with spaces
    SELECTED_PACKAGES=$(printf '%s\n' "${selected_packages[@]}")
    SELECTED_WEBAPPS=$(printf '%s\n' "${selected_webapps[@]}")
    SELECTED_NPMCLIS=$(printf '%s\n' "${selected_npmclis[@]}")
    return 0
}

# Function to remove webapps
remove_webapps() {
    local webapps=("$@")
    local failed_webapps=()
    local removed_webapps=()
    
    if [[ ${#webapps[@]} -eq 0 ]]; then
        return 0
    fi
    
    echo ""
    gum style \
        --foreground 39 \
        --bold \
        "🌐 Removing ${#webapps[@]} webapp(s)..."
    echo ""
    
    local current=0
    local total=${#webapps[@]}
    
    for webapp in "${webapps[@]}"; do
        ((current++))
        
        # Show current progress
        gum style --foreground 51 "[$current/$total] Processing: $webapp"

        local desktop_file="$HOME/.local/share/applications/$webapp.desktop"
        local remove_ok=false
        if [[ -f "$desktop_file" ]]; then
            if gum spin --spinner dot --title "Removing $webapp..." -- bash -c "omarchy-webapp-remove '$webapp' >/dev/null 2>&1"; then
                remove_ok=true
            fi
        else
            # Packaged bind with no launcher entry (ChatGPT/Grok on Omarchy 4).
            remove_ok=true
        fi

        if [[ "$remove_ok" == true ]]; then
            gum log --level info "✓ Removed: $webapp"
            removed_webapps+=("$webapp")
        else
            gum log --level error "✗ Failed: $webapp"
            failed_webapps+=("$webapp")
        fi
        
        # Show progress bar
        local percentage=$(( (current * 100) / total ))
        local filled=$(( percentage / 5 ))
        local empty=$(( (100 - percentage) / 5 ))
        
        printf "Progress: "
        printf '\033[92m█%.0s\033[0m' $(seq 1 $filled)
        printf '\033[90m░%.0s\033[0m' $(seq 1 $empty)
        printf " %d%% (%d/%d)\n" "$percentage" "$current" "$total"
        echo ""
    done
    
    # Summary for webapps
    echo ""
    if [[ ${#removed_webapps[@]} -gt 0 ]]; then
        gum style --foreground 82 "Successfully removed: ${removed_webapps[*]}"
    fi
    if [[ ${#failed_webapps[@]} -gt 0 ]]; then
        gum style --foreground 214 "Could not remove: ${failed_webapps[*]}"
    fi

    # Return the number of failed webapps as exit code
    return ${#failed_webapps[@]}
}

# Function to remove CLI tool stubs in ~/.local/bin
remove_npm_clis() {
    local clis=("$@")
    local failed_clis=()
    local removed_clis=()

    if [[ ${#clis[@]} -eq 0 ]]; then
        return 0
    fi

    echo ""
    gum style \
        --foreground 39 \
        --bold \
        "⬢ Removing ${#clis[@]} CLI tool(s)..."
    echo ""

    local current=0
    local total=${#clis[@]}

    for cli in "${clis[@]}"; do
        ((current++))

        # Show current progress
        gum style --foreground 51 "[$current/$total] Processing: $cli"

        # These are unprivileged stubs in the user's home; no sudo needed.
        if gum spin --spinner dot --title "Removing $cli..." -- bash -c "rm -f '$HOME/.local/bin/$cli'"; then
            gum log --level info "✓ Removed: $cli"
            removed_clis+=("$cli")
        else
            gum log --level error "✗ Failed: $cli"
            failed_clis+=("$cli")
        fi

        # Show progress bar
        local percentage=$(( (current * 100) / total ))
        local filled=$(( percentage / 5 ))
        local empty=$(( (100 - percentage) / 5 ))

        printf "Progress: "
        printf '\033[92m█%.0s\033[0m' $(seq 1 $filled)
        printf '\033[90m░%.0s\033[0m' $(seq 1 $empty)
        printf " %d%% (%d/%d)\n" "$percentage" "$current" "$total"
        echo ""
    done

    # Summary for CLI tools
    echo ""
    if [[ ${#removed_clis[@]} -gt 0 ]]; then
        gum style --foreground 82 "Successfully removed: ${removed_clis[*]}"
    fi
    if [[ ${#failed_clis[@]} -gt 0 ]]; then
        gum style --foreground 214 "Could not remove: ${failed_clis[*]}"
    fi

    # Return the number of failed CLIs as exit code
    return ${#failed_clis[@]}
}

# Function to remove packages
remove_packages() {
    local packages=("$@")
    local failed_packages=()
    local removed_packages=()
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        return 0
    fi
    
    echo ""
    gum style \
        --foreground 39 \
        --bold \
        "📦 Removing ${#packages[@]} package(s)..."
    echo ""

    # Ensure we have sudo credentials before starting
    if ! sudo -n true 2>/dev/null; then
        gum style --foreground 214 "🔐 Administrator privileges required for package removal"
        if ! sudo true; then
            gum log --level error "Failed to obtain sudo privileges"
            return 1
        fi
        echo ""
    fi
    
    local current=0
    local total=${#packages[@]}
    
    for pkg in "${packages[@]}"; do
        ((current++))
        
        # Show current progress
        gum style --foreground 51 "[$current/$total] Processing: $pkg"
        
        if gum spin --spinner dot --title "Removing $pkg..." -- bash -c "sudo pacman -Rns --noconfirm '$pkg' 2>/dev/null"; then
            gum log --level info "✓ Removed: $pkg"
            removed_packages+=("$pkg")
        else
            gum log --level warn "✗ Failed: $pkg (may have dependencies)"
            failed_packages+=("$pkg")
        fi
        
        # Show progress bar
        local percentage=$(( (current * 100) / total ))
        local filled=$(( percentage / 5 ))
        local empty=$(( (100 - percentage) / 5 ))
        
        printf "Progress: "
        printf '\033[92m█%.0s\033[0m' $(seq 1 $filled)
        printf '\033[90m░%.0s\033[0m' $(seq 1 $empty)
        printf " %d%% (%d/%d)\n" "$percentage" "$current" "$total"
        echo ""
    done
    
    # Summary for packages
    echo ""
    if [[ ${#removed_packages[@]} -gt 0 ]]; then
        gum style --foreground 82 "Successfully removed: ${removed_packages[*]}"
    fi
    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        gum style --foreground 214 "Could not remove: ${failed_packages[*]}"
    fi

    # Return the number of failed packages as exit code
    return ${#failed_packages[@]}
}

# Function to remove both packages and webapps
remove_items() {
    local all_bindings_to_remove=()

    # Global success tracking
    local total_attempted=0
    local total_failed=0

    # Split combined list into packages / webapps / npm CLIs
    parse_sections "$@"
    local pkg_array=("${PARSED_PACKAGES[@]}")
    local webapp_array=("${PARSED_WEBAPPS[@]}")
    local npmcli_array=("${PARSED_NPMCLIS[@]}")

    # Collect and remove keyboard shortcuts first (CLI stubs have none)
    if [[ "$REMOVE_BINDINGS" == true ]]; then
        echo ""
        gum style --foreground 51 "Checking for keyboard shortcuts..."

        local unbind_keys=()
        for item in "${pkg_array[@]}" "${webapp_array[@]}"; do
            local item_bindings
            item_bindings=$(find_app_bindings "$item")
            if [[ -n "$item_bindings" ]]; then
                while IFS= read -r binding; do
                    if [[ -n "$binding" ]]; then
                        all_bindings_to_remove+=("$binding")
                    fi
                done <<< "$item_bindings"
            fi
            local packaged_keys
            packaged_keys=$(find_packaged_unbind_keys "$item")
            if [[ -n "$packaged_keys" ]]; then
                while IFS= read -r key; do
                    if [[ -n "$key" ]]; then
                        unbind_keys+=("$key")
                    fi
                done <<< "$packaged_keys"
            fi
        done

        if [[ ${#all_bindings_to_remove[@]} -gt 0 ]]; then
            echo ""
            gum style --foreground 51 "Removing ${#all_bindings_to_remove[@]} keyboard shortcut(s) from user config..."
            remove_bindings_from_file "${all_bindings_to_remove[@]}"
        fi

        if [[ ${#unbind_keys[@]} -gt 0 ]]; then
            echo ""
            gum style --foreground 51 "Unbinding ${#unbind_keys[@]} packaged keyboard shortcut(s)..."
            # Unique keys
            local unique_keys=()
            while IFS= read -r key; do
                [[ -n "$key" ]] && unique_keys+=("$key")
            done < <(printf '%s\n' "${unbind_keys[@]}" | sort -u)
            append_lua_unbinds "${unique_keys[@]}"
        fi

        if [[ ${#all_bindings_to_remove[@]} -eq 0 && ${#unbind_keys[@]} -eq 0 ]]; then
            echo ""
            gum log --level info "No keyboard shortcuts found"
        fi
    fi

    total_attempted=$((${#pkg_array[@]} + ${#webapp_array[@]} + ${#npmcli_array[@]}))

    # Remove packages and capture failure count
    local pkg_failures=0
    if [[ ${#pkg_array[@]} -gt 0 ]]; then
        remove_packages "${pkg_array[@]}"
        pkg_failures=$?
    fi

    # Remove webapps and capture failure count
    local webapp_failures=0
    if [[ ${#webapp_array[@]} -gt 0 ]]; then
        remove_webapps "${webapp_array[@]}"
        webapp_failures=$?
    fi

    # Remove npm CLIs and capture failure count
    local npmcli_failures=0
    if [[ ${#npmcli_array[@]} -gt 0 ]]; then
        remove_npm_clis "${npmcli_array[@]}"
        npmcli_failures=$?
    fi

    total_failed=$((pkg_failures + webapp_failures + npmcli_failures))

    # Hero-style completion summary
    echo ""
    local successful_count=$((total_attempted - total_failed))

    if [[ $total_failed -eq 0 ]]; then
        # All successful - green hero
        gum style \
            --border double \
            --border-foreground 82 \
            --background 22 \
            --foreground 15 \
            --bold \
            --padding "1 2" \
            --margin "1" \
            --width 60 \
            --align center \
            "✅ SUCCESS" \
            "" \
            "All $total_attempted item(s) removed successfully!"

        # Return success
        return 0
    elif [[ $successful_count -gt 0 ]]; then
        # Partial success - orange hero
        gum style \
            --border double \
            --border-foreground 214 \
            --background 94 \
            --foreground 15 \
            --bold \
            --padding "1 2" \
            --margin "1" \
            --width 60 \
            --align center \
            "⚠️  PARTIAL SUCCESS" \
            "" \
            "$successful_count of $total_attempted item(s) removed" \
            "$total_failed item(s) could not be removed" \
            "" \
            "Some items may have dependencies"

        # Return partial failure
        return 1
    else
        # All failed - red hero
        gum style \
            --border double \
            --border-foreground 196 \
            --background 52 \
            --foreground 15 \
            --bold \
            --padding "1 2" \
            --margin "1" \
            --width 60 \
            --align center \
            "❌ FAILED" \
            "" \
            "Could not remove any items" \
            "" \
            "Check dependencies and permissions"

        # Return failure
        return 2
    fi
}

# Main function
main() {
    clear
    
    # Show ASCII logo
    gum style \
        --foreground 39 \
        "   ____                            __         " \
        "  / __ \____ ___  ____ ___________/ /_  __  __" \
        " / / / / __ \`__ \/ __ \`/ ___/ ___/ __ \/ / / /" \
        "/ /_/ / / / / / / /_/ / /  / /__/ / / / /_/ / " \
        "\____/_/_/_/_/_/\__,_/_/   \___/_/ /_/\__, /  " \
        "      / ____/ /__  ____ _____  ___  _/____/   " \
        "     / /   / / _ \/ __ \`/ __ \/ _ \/ ___/     " \
        "    / /___/ /  __/ /_/ / / / /  __/ /         " \
        "    \____/_/\___/\__,_/_/ /_/\___/_/          " \
        "                                              "
    
    echo ""
    
    # Show scanning message
    gum style --foreground 51 "🔍 Scanning for installed packages, webapps, and CLI tools..."
    echo ""

    # Show spinners while scanning (the actual functions are fast, so we add a small delay for visual feedback)
    gum spin --spinner globe --title "Checking packages..." -- sleep 0.8
    readarray -t installed_packages < <(get_installed_packages)

    gum spin --spinner globe --title "Checking webapps..." -- sleep 0.8
    readarray -t installed_webapps < <(get_installed_webapps)

    gum spin --spinner globe --title "Checking CLI tools..." -- sleep 0.8
    readarray -t installed_npmclis < <(get_installed_npm_clis)

    if [[ ${#installed_packages[@]} -eq 0 ]] && [[ ${#installed_webapps[@]} -eq 0 ]] && [[ ${#installed_npmclis[@]} -eq 0 ]]; then
        echo ""
        gum style \
            --foreground 82 \
            --border rounded \
            --border-foreground 82 \
            --padding "1 2" \
            --margin "1" \
            "✓ System is clean!" \
            "" \
            "No removable packages, webapps, or CLI tools found."
        echo ""
        exit 0
    fi

    # Go directly to selection

    # Combine packages, webapps, and npm CLIs with section separators
    local all_items=()
    all_items+=("${installed_packages[@]}")
    if [[ ${#installed_webapps[@]} -gt 0 ]]; then
        all_items+=("--webapps--")
        all_items+=("${installed_webapps[@]}")
    fi
    if [[ ${#installed_npmclis[@]} -gt 0 ]]; then
        all_items+=("--npmclis--")
        all_items+=("${installed_npmclis[@]}")
    fi
    
    # Use enhanced selection menu
    enhanced_select_packages "${all_items[@]}"
    local result=$?
    
    if [[ $result -ne 0 ]]; then
        clear
        echo ""
        gum log --level info "Operation cancelled"
        exit 0
    fi
    
    # The function will set global variables with selected items
    local selected_packages="$SELECTED_PACKAGES"
    local selected_webapps="$SELECTED_WEBAPPS"
    local selected_npmclis="$SELECTED_NPMCLIS"

    # Convert to arrays properly - these are newline-delimited strings from the
    # selection function (newline-delimited to preserve names with spaces)
    local packages_array=()
    local webapps_array=()
    local npmclis_array=()

    if [[ -n "$selected_packages" ]]; then
        readarray -t packages_array <<< "$selected_packages"
    fi

    if [[ -n "$selected_webapps" ]]; then
        readarray -t webapps_array <<< "$selected_webapps"
    fi

    if [[ -n "$selected_npmclis" ]]; then
        readarray -t npmclis_array <<< "$selected_npmclis"
    fi
    
    # Check if any selected items have keyboard shortcuts (user file and/or
    # packaged Omarchy 4 defaults).
    local selected_items_have_bindings=false
    local total_bindings=0

    for pkg in "${packages_array[@]}"; do
        if item_has_bindings "$pkg"; then
            selected_items_have_bindings=true
            total_bindings=$((total_bindings + $(count_item_bindings "$pkg")))
        fi
    done

    for webapp in "${webapps_array[@]}"; do
        if item_has_bindings "$webapp"; then
            selected_items_have_bindings=true
            total_bindings=$((total_bindings + $(count_item_bindings "$webapp")))
        fi
    done
    
    # Ask about keyboard shortcut cleanup if selected items have bindings
    if [[ "$selected_items_have_bindings" == true ]]; then
        clear
        
        gum style \
            --border double \
            --border-foreground 51 \
            --padding "1 2" \
            --width 60 \
            --align center \
            "⌨  KEYBOARD SHORTCUTS DETECTED"
        
        echo ""
        
        gum style \
            --foreground 51 \
            --bold \
            "Found $total_bindings keyboard shortcut(s) for the selected items:"
        
        echo ""
        
        # Show items with bindings
        for pkg in "${packages_array[@]}"; do
            if item_has_bindings "$pkg"; then
                gum style \
                    --foreground 214 \
                    "📦 $pkg"
            fi
        done
        
        for webapp in "${webapps_array[@]}"; do
            if item_has_bindings "$webapp"; then
                gum style \
                    --foreground 214 \
                    "🌐 $webapp"
            fi
        done
        
        echo ""
        
        local bindings_target="${BINDINGS_FILE/#$HOME/\~}"
        if [[ -z "$BINDINGS_FILE" ]]; then
            bindings_target="~/.config/hypr/bindings.lua"
        fi

        gum style \
            --foreground 51 \
            --italic \
            "Do you want to remove their keyboard shortcuts from ${bindings_target}?"
        
        gum style \
            --foreground 240 \
            --italic \
            "(A backup will be created before making changes)"
        
        echo ""
        
        if gum confirm "Remove keyboard shortcuts?"; then
            REMOVE_BINDINGS=true
            gum style \
                --foreground 82 \
                "✓ Keyboard shortcuts will be removed"
        else
            REMOVE_BINDINGS=false
            gum style \
                --foreground 214 \
                "✓ Keyboard shortcuts will be kept"
        fi
        
        echo ""
        gum style \
            --foreground 240 \
            --italic \
            "Press Enter to continue..."
        read </dev/tty
    fi
    
    # Create combined array for removal function
    local items_to_remove=()
    items_to_remove+=("${packages_array[@]}")
    if [[ ${#webapps_array[@]} -gt 0 ]]; then
        items_to_remove+=("--webapps--")
        items_to_remove+=("${webapps_array[@]}")
    fi
    if [[ ${#npmclis_array[@]} -gt 0 ]]; then
        items_to_remove+=("--npmclis--")
        items_to_remove+=("${npmclis_array[@]}")
    fi

    # Final confirmation
    clear

    # Build confirmation content using separate lines
    local total_count=$((${#packages_array[@]} + ${#webapps_array[@]} + ${#npmclis_array[@]}))
    
    # Show confirmation header
    gum style \
        --border double \
        --border-foreground 196 \
        --background 52 \
        --foreground 15 \
        --bold \
        --padding "1 2" \
        --margin "1" \
        --width 60 \
        --align center \
        "CONFIRMATION REQUIRED"
    
    echo ""
    
    gum style \
        --bold \
        "Ready to remove $total_count item(s):"
    
    echo ""
    
    # Show packages if any
    if [[ ${#packages_array[@]} -gt 0 ]]; then
        gum style \
            --foreground 39 \
            --bold \
            "📦 Packages (${#packages_array[@]}):"
        
        for pkg in "${packages_array[@]}"; do
            gum style \
                --foreground 214 \
                "   • $pkg"
        done
        echo ""
    fi
    
    # Show webapps if any
    if [[ ${#webapps_array[@]} -gt 0 ]]; then
        gum style \
            --foreground 39 \
            --bold \
            "🌐 Webapps (${#webapps_array[@]}):"

        for webapp in "${webapps_array[@]}"; do
            gum style \
                --foreground 214 \
                "   • $webapp"
        done
        echo ""
    fi

    # Show CLI tools if any
    if [[ ${#npmclis_array[@]} -gt 0 ]]; then
        gum style \
            --foreground 39 \
            --bold \
            "⬢ CLI tools (${#npmclis_array[@]}):"

        for cli in "${npmclis_array[@]}"; do
            gum style \
                --foreground 214 \
                "   • $cli"
        done
        echo ""
    fi

    # Show keyboard shortcuts info if applicable
    if [[ "$REMOVE_BINDINGS" == true ]]; then
        local total_bindings=0
        for pkg in "${packages_array[@]}"; do
            total_bindings=$((total_bindings + $(count_item_bindings "$pkg")))
        done
        for webapp in "${webapps_array[@]}"; do
            total_bindings=$((total_bindings + $(count_item_bindings "$webapp")))
        done
        
        if [[ $total_bindings -gt 0 ]]; then
            gum style \
                --foreground 51 \
                --bold \
                "⌨  Also removing $total_bindings keyboard shortcut(s)"
            echo ""
        fi
    fi
    
    echo ""
    
    # Show confirmation prompt with integrated warning
    echo "Proceed with removal? $(gum style --foreground 240 --italic "(This action cannot be undone!)")"
    echo ""
    
    if gum confirm; then
        clear
        remove_items "${items_to_remove[@]}"
        echo ""
        echo "Press Enter to exit..."
        read </dev/tty
    else
        echo ""
        gum log --level info "Operation cancelled"
    fi
}

# Handle Ctrl+C gracefully
trap 'echo ""; gum log --level info "Operation cancelled"; exit 1' INT

# Run main function
main "$@"