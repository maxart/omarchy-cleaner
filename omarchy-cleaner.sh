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
if [[ -f "$HOME/.config/hypr/hyprland.lua" ]]; then
    BINDINGS_FILE="$HOME/.config/hypr/bindings.lua"
fi
REMOVE_BINDINGS=false

# App
# List from: https://github.com/omacom/omarchy/blob/quattro/install/omarchy-base.packages
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
    "opencode"

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
    # "neovim"
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
    # "vi"
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
# List from: https://github.com/omacom/omarchy/blob/quattro/applications
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

# TUI desktop launchers shipped alongside the webapps.
DEFAULT_TUIS=("Docker" "Disk Usage")

# CLI tools
# List from: https://github.com/omacom/omarchy/blob/quattro/install/user/mise.sh
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
    "cursor-agent"
    "ghui"
    "hunk"
    "muse"
    "hermes"
    # Installed by Quattro development builds but not by 4.0.4.
    "agy"
    "hey"
    "ori"
)

# Function to check if package is installed
is_package_installed() {
    local package="$1"
    pacman -Qi "$package" &>/dev/null
    return $?
}

# Helpers remove one named launcher. TUIs remain in the same selection section.
launcher_remove_helper() {
    case "$1" in
        "Docker"|"Disk Usage") printf '%s\n' omarchy-tui-remove ;;
        *) printf '%s\n' omarchy-webapp-remove ;;
    esac
}

# Reject native desktop entries or links that happen to share a default's name.
is_webapp_installed() {
    local name="$1"
    local desktop_file="$HOME/.local/share/applications/$name.desktop"
    [[ -n "$name" && "$name" != */* && -f "$desktop_file" && ! -L "$desktop_file" ]] || return 1
    case "$name" in
        "Docker")
            grep -qxF 'Exec=xdg-terminal-exec --app-id=TUI.tile -e omarchy-launch-docker-tui' "$desktop_file" ||
                grep -qxF 'Exec=xdg-terminal-exec --app-id=TUI.tile -e lazydocker' "$desktop_file" ;;
        "Disk Usage")
            grep -qxF 'Exec=xdg-terminal-exec --app-id=TUI.float -e bash -c "dua i /"' "$desktop_file" ||
                grep -qxF "Exec=xdg-terminal-exec --app-id=TUI.float -e bash -c 'dust -r; read -n 1 -s'" "$desktop_file" ;;
        *)
            grep -qE '^Exec=(omarchy-launch-webapp|omarchy-webapp-handler[-[:alnum:]]*)([[:space:]]|$)' "$desktop_file" ;;
    esac
}

# Known command/package pairs from Omarchy's mise and legacy npm installers.
# Matching the complete wrapper keeps personal scripts and binaries out of the list.
cli_packages_for() {
    case "$1" in
        codex)          printf '%s\n' codex @openai/codex ;;
        claude)         printf '%s\n' claude ;;
        crush)          printf '%s\n' crush ;;
        gemini)         printf '%s\n' gemini @google/gemini-cli ;;
        gh)             printf '%s\n' gh ;;
        copilot)        printf '%s\n' copilot @github/copilot ;;
        opencode)       printf '%s\n' opencode opencode-ai ;;
        playwright|playwright-cli) printf '%s\n' npm:playwright playwright ;;
        pi)             printf '%s\n' pi @earendil-works/pi-coding-agent @mariozechner/pi-coding-agent ;;
        omp)            printf '%s\n' github:can1357/oh-my-pi ;;
        grok)           printf '%s\n' npm:@xai-official/grok ;;
        cursor-agent)   printf '%s\n' cursor-agent ;;
        ghui)           printf '%s\n' npm:@kitlangton/ghui @kitlangton/ghui ;;
        hunk)           printf '%s\n' aqua:modem-dev/hunk ;;
        agy)            printf '%s\n' antigravity-cli ;;
        hey)            printf '%s\n' github:basecamp/hey-cli ;;
        ori)            printf '%s\n' github:OpenRouterLabs/ori-releases ;;
        muse)           printf '%s\n' 'http:muse[url=https://api.meta.ai/muse-launcher.sh,bin=muse,version_list_url=https://api.meta.ai/muse-code/channels/muse-stable,version_json_path=.version]' ;;
    esac
}

# Print the legacy 3.8.4 npx wrapper without executing any of its contents.
legacy_npx_stub() {
    printf '#!/bin/bash\npackage="%s"\ncommand="%s"\n' "$1" "$2"
    cat <<'STUB'

if ! node_root="$(mise where node@latest 2>/dev/null)"; then
  mise use -g node@latest >/dev/null
  node_root="$(mise where node@latest)"
fi

node_bin="$node_root/bin/node"
npx_bin="$node_root/bin/npx"

ensure_bin_runtime() {
  local bin_path=$1
  local shebang

  IFS= read -r shebang < "$bin_path"

  if [[ $shebang == "#!"*"/bun"* || $shebang == "#!"*"/env bun"* ]]; then
    if omarchy-cmd-missing bun; then
      echo "Installing bun runtime for $package..."
      omarchy-pkg-add bun
      hash -r
    fi
  fi
}

exec_package_bin() {
  local package_bin_path=$1
  shift

  if [[ -n $package_bin_path ]]; then
    ensure_bin_runtime "$package_bin_path"
    PATH="$node_root/bin:$PATH" exec "$package_bin_path" "$@"
  fi
}

# Resolve the package bin inside npx, then run it with node@latest available for node shebangs.
# Some wrappers are aliases, e.g. playwright-cli wraps the playwright bin.
"$node_bin" "$npx_bin" --yes --prefer-online --package "$package" -- true

package_bin_path=$("$node_bin" "$npx_bin" --yes --package "$package" -- which "$package" 2>/dev/null)
exec_package_bin "$package_bin_path" "$@"

# Scoped packages like @openai/codex expose an unscoped bin like codex.
package_bin_path=$("$node_bin" "$npx_bin" --yes --package "$package" -- which "$command" 2>/dev/null)
exec_package_bin "$package_bin_path" "$@"

echo "Could not resolve npm bin for $package / $command" >&2
exit 127
STUB
}

# Function to check if a CLI tool stub is installed.
is_npm_cli_installed() {
    local cmd="$1"
    local stub="$HOME/.local/bin/$cmd"
    [[ "$cmd" != */* && -f "$stub" && -r "$stub" && ! -L "$stub" ]] || return 1

    # Hermes has its own upstream ownership contract. --owns only checks the
    # wrapper marker; --remove would also delete its mise environment.
    if [[ "$cmd" == hermes ]]; then
        command -v omarchy-install-hermes-cli >/dev/null 2>&1 &&
            omarchy-install-hermes-cli --owns >/dev/null 2>&1
        return $?
    fi

    local package quiet
    while IFS= read -r package; do
        # 4.0.0 omitted --quiet; later releases include it.
        for quiet in '--quiet ' ''; do
            if cmp -s -- "$stub" <(printf '%s\n' '#!/bin/bash' \
                'export MISE_MINIMUM_RELEASE_AGE=0' \
                "mise use -g ${quiet}\"$package\" || exit 1" \
                "exec mise x \"$package\" -- \"$cmd\" \"\$@\""); then
                return 0
            fi
        done
        if cmp -s -- "$stub" <(legacy_npx_stub "$package" "$cmd"); then
            return 0
        fi
        # Older, minimal pnpm wrappers are accepted only as a complete file.
        if cmp -s -- "$stub" <(printf '#!/bin/bash\npnpm dlx %s "$@"\n' "$package") ||
            cmp -s -- "$stub" <(printf '#!/bin/bash\nexec pnpm dlx "%s" "$@"\n' "$package"); then
            return 0
        fi
    done < <(cli_packages_for "$cmd")
    return 1
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
    for webapp in "${DEFAULT_WEBAPPS[@]}" "${DEFAULT_TUIS[@]}"; do
        if is_webapp_installed "$webapp"; then
            echo "$webapp"
        elif [[ ! -e "$HOME/.local/share/applications/$webapp.desktop" &&
            ! -L "$HOME/.local/share/applications/$webapp.desktop" &&
            -n "$(find_packaged_unbind_keys "$webapp")" ]]; then
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
        "basecamp")        echo "basecamp.com|37signals.com" ;;
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

# A line-oriented matcher cannot safely interpret mixed Lua string expressions.
# Decline user-line deletion for ambiguous long-string layouts anywhere in a file.
# Default unbinds can still be prepended without changing that file's own lines.
bindings_support_line_cleanup() {
    local line opening prefix rest
    local simple_prefix='^[[:space:]]*(--|((local[[:space:]]+)?[[:alpha:]_][[:alnum:]_]*[[:space:]]*=[[:space:]]*))?$'
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ \[(=*)\[ ]]; then
            opening="${BASH_REMATCH[0]}"
            prefix="${line%%"$opening"*}"
            rest="${line#*"$opening"}"
            # Includes closers before the opener, quoted openers, and multiple
            # regions on one line. Keeping extra lines is safer than guessing.
            if [[ ! "$prefix" =~ $simple_prefix || "$line" =~ \]=*\] || "$rest" =~ \[=*\[ ]]; then
                return 1
            fi
        fi
    done < "$1"
}

# Match only complete, single-line bindings; never evaluate the user's config.
find_bindings_in_file() {
    local app_name="${1,,}"
    local bindings_file="$2"
    [[ -f "$bindings_file" ]] || return 0
    bindings_support_line_cleanup "$bindings_file" || return 0

    local domains
    domains=$(webapp_domains_for "$app_name")
    local -a tokens
    read -r -a tokens <<< "$(app_tokens_for "$app_name")"
    local quote="[\"']"
    local lua="^[[:space:]]*o[.]bind[[:space:]]*\([[:space:]]*${quote}[^\"']+${quote}[[:space:]]*,[[:space:]]*(${quote}[^\"']*${quote}|nil)[[:space:]]*,[[:space:]]*\{[[:space:]]*(launch|tui|omarchy|webapp)[[:space:]]*=[[:space:]]*${quote}([^\"']+)${quote}[^{}]*\}[[:space:]]*\)[[:space:]]*(--.*)?$"
    local legacy='^[[:space:]]*bindd[[:space:]]*=.*,[[:space:]]*exec[[:space:]]*,[[:space:]]*(.*)$'
    local line action command token host domain matched_line
    local line_number=0
    local comment_end=""
    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_number++))
        matched_line="$line"
        [[ "${3:-}" == line_numbers ]] && matched_line="$line_number"
        # Conservatively leave Lua long comments/strings and multiline bindings alone.
        if [[ -z "$comment_end" && "$line" =~ \[(=*)\[ ]]; then
            comment_end="]${BASH_REMATCH[1]}]"
        fi
        if [[ -n "$comment_end" ]]; then
            [[ "$line" == *"$comment_end"* ]] && comment_end=""
            continue
        fi
        action=""
        command=""
        if [[ "$line" =~ $lua ]]; then
            action="${BASH_REMATCH[2]}"
            command="${BASH_REMATCH[3]}"
        elif [[ "$line" =~ $legacy ]]; then
            command="${BASH_REMATCH[1]}"
            [[ "$command" == omarchy-launch-webapp\ * || "$command" == omarchy-launch-or-focus-webapp\ * ]] && action=webapp
        else
            continue
        fi

        if [[ -n "$domains" ]]; then
            [[ "$action" == webapp ]] || continue
            if [[ "$command" =~ https?://([^/\?\#\"\'[:space:]]+) ]]; then
                host="${BASH_REMATCH[1],,}"
                [[ "$host" != *@* ]] || continue
                host="${host%%:*}"
                local -a domain_list
                IFS='|' read -r -a domain_list <<< "$domains"
                for domain in "${domain_list[@]}"; do
                    if [[ "$host" == "$domain" || "$host" == *."$domain" ]]; then
                        printf '%s\n' "$matched_line"
                        break
                    fi
                done
            fi
        elif [[ "$action" != webapp ]]; then
            for token in "${tokens[@]}"; do
                if [[ -n "$action" ]]; then
                    if [[ "$command" == "$token" || "$command" == "$token "* ]]; then
                        printf '%s\n' "$matched_line"
                        break
                    fi
                else
                    # Literal command tokens, with the launchers used by legacy Omarchy.
                    local launcher
                    # shellcheck disable=SC2016 # Match the literal legacy $terminal variable.
                    for launcher in 'uwsm-app --' 'uwsm app --' 'omarchy-launch-or-focus' \
                        'omarchy-launch-tui' 'omarchy-launch-or-focus-tui' '$terminal -e'; do
                        if [[ "$command" == "$launcher $token" || "$command" == "$launcher $token "* ||
                            "$command" == "$launcher \"$token\"" || "$command" == "$launcher '$token'" ]]; then
                            printf '%s\n' "$matched_line"
                            break 2
                        fi
                    done
                fi
            done
        fi
    done < "$bindings_file"
}

find_app_bindings() {
    find_bindings_in_file "$1" "$BINDINGS_FILE"
}

# Packaged app defaults are relevant only to the Lua configuration. Respect
# Omarchy's documented global switches and Remove Preinstalls state marker.
packaged_applications_bindings_file() {
    [[ "$BINDINGS_FILE" == *.lua ]] || return 1
    local root="${OMARCHY_PATH:-/usr/share/omarchy}"
    local candidate="$root/default/hypr/bindings/applications.lua"
    [[ -f "$candidate" ]] || return 1
    local config="$HOME/.config/hypr/hyprland.lua"
    local line preinstalled="" defaults=""
    if [[ -f "$config" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ "$line" =~ ^[[:space:]]*omarchy_default_bindings[[:space:]]*=[[:space:]]*(true|false) ]]; then
                defaults="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^[[:space:]]*omarchy_preinstalled_bindings[[:space:]]*=[[:space:]]*(true|false) ]]; then
                preinstalled="${BASH_REMATCH[1]}"
            fi
        done < "$config"
    fi
    [[ "$defaults" == false || "$preinstalled" == false ]] && return 1
    if [[ "$preinstalled" != true && -f "$HOME/.local/state/omarchy/preinstalls-removed" ]]; then
        return 1
    fi
    printf '%s\n' "$candidate"
}

extract_lua_bind_key() {
    local pattern="^[[:space:]]*o[.]bind[[:space:]]*\([[:space:]]*[\"']([^\"']+)[\"']"
    if [[ "$1" =~ $pattern ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
    fi
}

# Only standalone active unbinds count; examples in comments do not.
lua_key_is_unbound() {
    [[ -f "$BINDINGS_FILE" ]] || return 1
    bindings_support_line_cleanup "$BINDINGS_FILE" || return 1
    local wanted="${1//[[:space:]]/}"
    local pattern="^hl[.]unbind[[:space:]]*\([[:space:]]*[\"']([^\"']+)[\"'][[:space:]]*\)[[:space:]]*(--.*)?$"
    local line key comment_end=""
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ -z "$comment_end" && "$line" =~ \[(=*)\[ ]]; then
            comment_end="]${BASH_REMATCH[1]}]"
        fi
        if [[ -n "$comment_end" ]]; then
            [[ "$line" == *"$comment_end"* ]] && comment_end=""
            continue
        fi
        if [[ "$line" =~ $pattern ]]; then
            key="${BASH_REMATCH[1]//[[:space:]]/}"
            [[ "${key^^}" == "${wanted^^}" ]] && return 0
        fi
    done < "$BINDINGS_FILE"
    return 1
}

find_packaged_unbind_keys() {
    local file line key
    file=$(packaged_applications_bindings_file) || return 0
    while IFS= read -r line; do
        key=$(extract_lua_bind_key "$line")
        # Keys are emitted as Lua strings. Reject anything needing escaping.
        [[ -n "$key" && "$key" != *\\* ]] || continue
        if ! lua_key_is_unbound "$key"; then
            printf '%s\n' "$key"
        fi
    done < <(find_bindings_in_file "$1" "$file")
}

item_has_bindings() {
    [[ -n "$(find_app_bindings "$1")$(find_packaged_unbind_keys "$1")" ]]
}

count_item_bindings() {
    local bindings
    bindings=$({ find_app_bindings "$1"; find_packaged_unbind_keys "$1"; } | sort -u)
    if [[ -n "$bindings" ]]; then
        printf '%s\n' "$bindings" | wc -l
    else
        printf '0\n'
    fi
}

# Apply both user-line removal and packaged unbinds in one backed-up replacement.
# Put unbinds BEFORE personal overrides so a replacement on the same key survives.
cleanup_bindings() {
    local -a line_numbers=() keys=()
    local original_checksum=""
    if [[ -f "$BINDINGS_FILE" ]]; then
        original_checksum=$(sha256sum < "$BINDINGS_FILE") || return 1
    fi
    local item line key
    for item in "$@"; do
        while IFS= read -r line; do
            [[ -n "$line" ]] && line_numbers+=("$line")
        done < <(find_bindings_in_file "$item" "$BINDINGS_FILE" line_numbers)
        while IFS= read -r key; do
            [[ -n "$key" ]] && keys+=("$key")
        done < <(find_packaged_unbind_keys "$item")
    done
    [[ ${#line_numbers[@]} -gt 0 || ${#keys[@]} -gt 0 ]] || return 0

    local file user_root packaged_root
    file=$(readlink -m -- "$BINDINGS_FILE") || return 1
    user_root=$(readlink -f -- "$HOME") || return 1
    packaged_root=$(readlink -m -- "${OMARCHY_PATH:-/usr/share/omarchy}") || return 1
    if [[ "$file" != "$user_root/"* || "$file" == "$packaged_root/"* ]]; then
        gum log --level error "Refusing to edit bindings outside your personal configuration: $file"
        return 1
    fi
    mkdir -p -- "$(dirname -- "$file")" || return 1
    local temp_file backup_file=""
    temp_file=$(mktemp "${file}.tmp.XXXXXXXX") || return 1
    if [[ -e "$file" ]]; then
        backup_file=$(mktemp "${file}.backup.$(date +%Y%m%d_%H%M%S).XXXXXXXX")
        if [[ -z "$backup_file" ]] || ! cp --preserve=mode -- "$file" "$backup_file" ||
            ! chmod --reference="$file" "$temp_file"; then
            gum log --level error "Could not back up bindings; shortcuts were kept"
            rm -f -- "$temp_file"
            return 1
        fi
        if [[ "$original_checksum" != "$(sha256sum < "$backup_file")" ]]; then
            gum log --level error "Bindings changed during discovery; shortcuts were kept"
            rm -f -- "$temp_file"
            return 1
        fi
        gum log --level info "Created backup: $backup_file"
    fi

    if ! (
        if [[ ${#keys[@]} -gt 0 ]]; then
            printf '%s\n' '-- Omarchy Cleaner: disable removed apps before personal overrides.' || exit 1
            while IFS= read -r key; do
                printf 'hl.unbind("%s")\n' "$key" || exit 1
            done < <(printf '%s\n' "${keys[@]}" | sort -u)
            printf '\n' || exit 1
        fi
        if [[ -n "$backup_file" ]]; then
            local line_number=0
            while IFS= read -r line || [[ -n "$line" ]]; do
                ((line_number++))
                local remove=false binding
                for binding in "${line_numbers[@]}"; do
                    [[ "$line_number" == "$binding" ]] && remove=true && break
                done
                if [[ "$remove" == false ]]; then
                    printf '%s\n' "$line" || exit 1
                fi
            done < "$backup_file"
        fi
    ) > "$temp_file"; then
        gum log --level error "Could not write bindings; shortcuts were kept"
        rm -f -- "$temp_file"
        return 1
    fi
    if { [[ -n "$backup_file" ]] && ! cmp -s -- "$file" "$backup_file"; } ||
        { [[ -z "$backup_file" ]] && [[ -e "$file" ]]; }; then
        gum log --level error "Bindings changed during cleanup; shortcuts were kept"
        rm -f -- "$temp_file"
        return 1
    fi
    if ! mv -f -- "$temp_file" "$file"; then
        gum log --level error "Could not replace bindings; shortcuts were kept"
        rm -f -- "$temp_file"
        return 1
    fi
    gum log --level info "✓ Cleaned up keyboard shortcuts"
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
        local suffix=""
        if [[ "${item_types[$i]}" == webapp ]] && ! is_webapp_installed "${all_items[$i]}"; then
            suffix=" (shortcut only)"
        fi
        local item_bindings=""
        if [[ "${item_types[$i]}" != "npmcli" ]]; then
            if item_has_bindings "${all_items[$i]}"; then
                item_bindings="yes"
            fi
        fi
        if [[ -n "$item_bindings" ]]; then
            bindings_found[i]=1
            display_items+=("${prefix}${all_items[$i]}${suffix} ⌨")
        else
            bindings_found[i]=0
            display_items+=("${prefix}${all_items[$i]}${suffix}")
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

        local counts_msg="Found $pkg_count packages and $webapp_count webapps/TUIs"
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
        
        if ! selected_items=$(printf '%s\n' "${display_items[@]}" | \
            gum filter \
                --limit 0 \
                --no-limit \
                --indicator " ▸" \
                --selected-prefix " ✓ " \
                --unselected-prefix "   " \
                --placeholder "Type to filter..." \
                --header "Select items to remove:" \
                --height 15); then
            # The selector was cancelled.
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
                read -r </dev/tty
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
        # Match the complete display row so equal names in different categories
        # (such as a pacman package and CLI wrapper) stay distinct.
        local clean_item
        # Find matching item in original arrays
        for i in "${!all_items[@]}"; do
            if [[ "${display_items[$i]}" == "$selected_item" ]]; then
                clean_item="${all_items[$i]}"
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

# Packages are removed together so selected dependencies (e.g. docker-buildx
# and docker) do not prevent each other from being removed in the wrong order.
remove_packages() {
    local packages=("$@")
    REMOVED_PACKAGES=()
    [[ ${#packages[@]} -gt 0 ]] || return 0
    gum style --foreground 39 --bold "📦 Removing ${#packages[@]} package(s)..."
    if ! sudo -n true 2>/dev/null; then
        gum style --foreground 214 "🔐 Administrator privileges required for package removal"
        if ! sudo true; then
            gum log --level error "Failed to obtain sudo privileges; packages were kept"
            return "${#packages[@]}"
        fi
    fi
    if gum spin --spinner dot --show-error --title "Removing selected packages..." -- \
        sudo pacman -Rns --noconfirm -- "${packages[@]}"; then
        REMOVED_PACKAGES=("${packages[@]}")
        gum log --level info "✓ Removed: ${packages[*]}"
        return 0
    fi
    gum log --level error "Package removal failed; their keyboard shortcuts will be kept"
    return "${#packages[@]}"
}

# Webapps and TUIs share the desktop-launcher section of the selector.
remove_webapps() {
    REMOVED_WEBAPPS=()
    SHORTCUT_ONLY_WEBAPPS=()
    local failed=0 current=0 webapp helper desktop_file
    for webapp in "$@"; do
        ((current++))
        gum style --foreground 51 "[$current/$#] Processing: $webapp"
        desktop_file="$HOME/.local/share/applications/$webapp.desktop"
        if is_webapp_installed "$webapp"; then
            helper=$(launcher_remove_helper "$webapp")
            if gum spin --spinner dot --show-error --title "Removing $webapp..." -- \
                "$helper" "$webapp" && [[ ! -e "$desktop_file" && ! -L "$desktop_file" ]]; then
                REMOVED_WEBAPPS+=("$webapp")
                gum log --level info "✓ Removed launcher: $webapp"
            else
                gum log --level error "✗ Failed to remove launcher: $webapp"
                ((failed++))
            fi
        elif [[ ! -e "$desktop_file" && ! -L "$desktop_file" && "$REMOVE_BINDINGS" == true &&
            -n "$(find_packaged_unbind_keys "$webapp")" ]]; then
            SHORTCUT_ONLY_WEBAPPS+=("$webapp")
        else
            gum log --level warn "Kept $webapp: launcher changed or shortcut cleanup was not selected"
            ((failed++))
        fi
    done
    return "$failed"
}

# Remove only a recognized stub, never mise installations, caches, or user data.
remove_npm_clis() {
    REMOVED_NPMCLIS=()
    local failed=0 current=0 cli
    for cli in "$@"; do
        ((current++))
        gum style --foreground 51 "[$current/$#] Processing CLI wrapper: $cli"
        if is_npm_cli_installed "$cli" &&
            gum spin --spinner dot --show-error --title "Removing $cli wrapper..." -- \
                rm -f -- "$HOME/.local/bin/$cli" &&
            [[ ! -e "$HOME/.local/bin/$cli" && ! -L "$HOME/.local/bin/$cli" ]]; then
            REMOVED_NPMCLIS+=("$cli")
            gum log --level info "✓ Removed CLI wrapper: $cli"
        else
            gum log --level error "✗ Kept $cli: wrapper changed, is unrecognized, or could not be removed"
            ((failed++))
        fi
    done
    return "$failed"
}

# Remove selected items, then clean shortcuts only for successful removals.
remove_items() {
    parse_sections "$@"
    local pkg_array=("${PARSED_PACKAGES[@]}")
    local webapp_array=("${PARSED_WEBAPPS[@]}")
    local npmcli_array=("${PARSED_NPMCLIS[@]}")
    local total_attempted=$((${#pkg_array[@]} + ${#webapp_array[@]} + ${#npmcli_array[@]}))
    local total_failed=0 failures=0 binding_failed=false

    remove_packages "${pkg_array[@]}"
    failures=$?
    total_failed=$((total_failed + failures))
    remove_webapps "${webapp_array[@]}"
    failures=$?
    total_failed=$((total_failed + failures))
    remove_npm_clis "${npmcli_array[@]}"
    failures=$?
    total_failed=$((total_failed + failures))

    if [[ "$REMOVE_BINDINGS" == true ]]; then
        if ! cleanup_bindings "${REMOVED_PACKAGES[@]}" "${REMOVED_WEBAPPS[@]}" "${SHORTCUT_ONLY_WEBAPPS[@]}"; then
            binding_failed=true
            total_failed=$((total_failed + ${#SHORTCUT_ONLY_WEBAPPS[@]}))
            gum log --level error "Keyboard shortcut cleanup failed; see the backup/error above"
        fi
    fi

    local successful_count=$((total_attempted - total_failed))
    local title color background status=0
    local -a summary
    if [[ "$total_failed" -eq 0 && "$binding_failed" == false ]]; then
        title="✅ SUCCESS"; color=82; background=22
        summary=("Completed all $total_attempted selected removal(s).")
    elif [[ "$successful_count" -gt 0 ]]; then
        title="⚠️  PARTIAL SUCCESS"; color=214; background=94; status=1
        summary=("Completed $successful_count of $total_attempted selected removal(s).")
    else
        title="❌ FAILED"; color=196; background=52; status=2
        summary=("Could not complete any selected removals.")
    fi
    if [[ "$binding_failed" == true ]]; then
        summary+=("Keyboard shortcut cleanup could not be completed.")
    fi
    gum style --border double --border-foreground "$color" --background "$background" \
        --foreground 15 --bold --padding "1 2" --margin "1" --width 60 --align center \
        "$title" "" "${summary[@]}"
    return "$status"
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
        "    \____/_/\___/\__,_/_/ /_/\___/_/          "
    
    echo ""
    
    gum style --foreground 240 "Omarchy Cleaner $VERSION"

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
    local selected_package_lines="$SELECTED_PACKAGES"
    local selected_webapp_lines="$SELECTED_WEBAPPS"
    local selected_npmcli_lines="$SELECTED_NPMCLIS"

    # Convert to arrays properly - these are newline-delimited strings from the
    # selection function (newline-delimited to preserve names with spaces)
    local packages_array=()
    local webapps_array=()
    local npmclis_array=()

    if [[ -n "$selected_package_lines" ]]; then
        readarray -t packages_array <<< "$selected_package_lines"
    fi

    if [[ -n "$selected_webapp_lines" ]]; then
        readarray -t webapps_array <<< "$selected_webapp_lines"
    fi

    if [[ -n "$selected_npmcli_lines" ]]; then
        readarray -t npmclis_array <<< "$selected_npmcli_lines"
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
        read -r </dev/tty
    fi
    
    # A shortcut-only item has no launcher to remove if cleanup was declined.
    if [[ "$REMOVE_BINDINGS" != true ]]; then
        local kept_webapps=()
        for webapp in "${webapps_array[@]}"; do
            if is_webapp_installed "$webapp"; then
                kept_webapps+=("$webapp")
            else
                gum log --level info "Skipped $webapp (shortcut cleanup was declined)"
            fi
        done
        webapps_array=("${kept_webapps[@]}")
    fi
    if [[ $((${#packages_array[@]} + ${#webapps_array[@]} + ${#npmclis_array[@]})) -eq 0 ]]; then
        gum log --level info "No removals selected"
        return 0
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
            "🌐 Webapps / TUIs (${#webapps_array[@]}):"

        for webapp in "${webapps_array[@]}"; do
            local label="$webapp"
            is_webapp_installed "$webapp" || label="$webapp (shortcut only)"
            gum style --foreground 214 "   • $label"
        done
        echo ""
    fi

    # Show CLI tools if any
    if [[ ${#npmclis_array[@]} -gt 0 ]]; then
        gum style \
            --foreground 39 \
            --bold \
            "⬢ CLI wrappers (${#npmclis_array[@]}):"

        for cli in "${npmclis_array[@]}"; do
            gum style \
                --foreground 214 \
                "   • $cli"
        done
        echo ""
    fi

    if [[ ${#packages_array[@]} -gt 0 ]]; then
        gum style --foreground 240 --italic "Pacman also removes unused dependencies and package backup configs."
    fi
    if [[ ${#npmclis_array[@]} -gt 0 ]]; then
        gum style --foreground 240 --italic "CLI removal deletes launcher wrappers; installed runtimes and caches are kept."
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
        local removal_status=$?
        echo ""
        gum style --foreground 240 "Press Enter to exit..."
        read -r </dev/tty
        return "$removal_status"
    else
        echo ""
        gum log --level info "Operation cancelled"
    fi
}

# Sourcing defines functions for regression checks. An empty BASH_SOURCE is the
# supported curl | bash entry point and must still run main.
if [[ -z "${BASH_SOURCE[0]}" || "${BASH_SOURCE[0]}" == "$0" ]]; then
    trap 'echo ""; gum log --level info "Operation cancelled"; exit 1' INT
    main "$@"
fi
