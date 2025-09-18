#!/bin/bash

# Omarchy Cleaner - Remove unwanted default applications from Omarchy
# Enhanced with gum for a better TUI experience

# Version
VERSION="2.0"

# Configuration
BINDINGS_FILE="$HOME/.config/hypr/bindings.conf"
REMOVE_BINDINGS=false

# App
# List from: https://github.com/basecamp/omarchy/blob/master/install/packages.sh
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
    "docker"
    "docker-buildx"
    "docker-compose"
    
    # Uncomment to include in removal list
    # "asdcontrol-git"
    # "alacritty"
    # "avahi"
    # "bash-completion"
    # "bat"
    # "blueberry"
    # "brightnessctl"
    # "btop"
    # "cargo"
    # "clang"
    # "cups"
    # "cups-browsed"
    # "cups-filters"
    # "cups-pdf"
    # "dust"
    # "evince"
    # "eza"
    # "fastfetch"
    # "fcitx5"
    # "fcitx5-gtk"
    # "fcitx5-qt"
    # "fd"
    # "ffmpegthumbnailer"
    # "fontconfig"
    # "fzf"
    # "gcc14"
    # "github-cli"
    # "gnome-calculator"
    # "gnome-keyring"
    # "gnome-themes-extra"
    # "gum"
    # "gvfs-mtp"
    # "gvfs-smb"
    # "hypridle"
    # "hyprland"
    # "hyprland-qtutils"
    # "hyprlock"
    # "hyprpicker"
    # "hyprshot"
    # "hyprsunset"
    # "imagemagick"
    # "impala"
    # "imv"
    # "inetutils"
    # "iwd"
    # "jq"
    # "kvantum-qt5"
    # "lazydocker"
    # "lazygit"
    # "less"
    # "libyaml"
    # "libqalculate"
    # "llvm"
    # "luarocks"
    # "mako"
    # "man"
    # "mariadb-libs"
    # "mise"
    # "mpv"
    # "nautilus"
    # "noto-fonts"
    # "noto-fonts-cjk"
    # "noto-fonts-emoji"
    # "noto-fonts-extra"
    # "nss-mdns"
    # "omarchy-lazyvim"
    # "nvim"
    # "pamixer"
    # "pinta"
    # "playerctl"
    # "plocate"
    # "plymouth"
    # "polkit-gnome"
    # "postgresql-libs"
    # "power-profiles-daemon"
    # "python-gobject"
    # "python-poetry-core"
    # "python-terminaltexteffects"
    # "qt5-wayland"
    # "ripgrep"
    # "satty"
    # "slurp"
    # "starship"
    # "sushi"
    # "swaybg"
    # "swayosd"
    # "system-config-printer"
    # "tldr"
    # "tree-sitter-cli"
    # "ttf-cascadia-mono-nerd"
    # "ttf-ia-writer"
    # "ttf-jetbrains-mono-nerd"
    # "typora"
    # "tzupdate"
    # "ufw"
    # "ufw-docker"
    # "unzip"
    # "uwsm"
    # "walker-bin"
    # "waybar"
    # "wf-recorder"
    # "whois"
    # "wireless-regdb"
    # "wiremix"
    # "wireplumber"
    # "wl-clip-persist"
    # "wl-clipboard"
    # "wl-screenrec"
    # "woff2-font-awesome"
    # "xdg-desktop-portal-gtk"
    # "xdg-desktop-portal-hyprland"
    # "xmlstarlet"
    # "yaru-icon-theme"
    # "yay"
    # "zoxide"
)

# Webapps
# List from: https://github.com/basecamp/omarchy/blob/master/install/packaging/webapps.sh
DEFAULT_WEBAPPS=(
    "HEY"
    "Basecamp"
    "WhatsApp"
    "Google Photos"
    "Google Contacts"
    "Google Messages"
    "ChatGPT"
    "YouTube"
    "GitHub"
    "X"
    "Figma"
    "Discord"
    "Zoom"
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
        fi
    done
}

# Function to find keyboard bindings for an app/webapp
find_app_bindings() {
    local app_name="$1"
    local bindings=()
    
    if [[ ! -f "$BINDINGS_FILE" ]]; then
        echo ""
        return
    fi
    
    # Convert app name to lowercase for case-insensitive matching
    local app_lower=$(echo "$app_name" | tr '[:upper:]' '[:lower:]')
    
    # Define webapp URL patterns for known webapps
    local webapp_domains=""
    case "$app_lower" in
        "hey")
            webapp_domains="app.hey.com|hey.com"
            ;;
        "basecamp")
            webapp_domains="basecamp.com|3.basecamp.com"
            ;;
        "whatsapp")
            webapp_domains="web.whatsapp.com|whatsapp.com"
            ;;
        "google photos")
            webapp_domains="photos.google.com"
            ;;
        "google contacts")
            webapp_domains="contacts.google.com"
            ;;
        "google messages")
            webapp_domains="messages.google.com"
            ;;
        "chatgpt")
            webapp_domains="chatgpt.com|chat.openai.com"
            ;;
        "youtube")
            webapp_domains="youtube.com|youtu.be"
            ;;
        "github")
            webapp_domains="github.com"
            ;;
        "x")
            webapp_domains="x.com|twitter.com"
            ;;
        "figma")
            webapp_domains="figma.com"
            ;;
        "discord")
            webapp_domains="discord.com|discord.gg"
            ;;
        "zoom")
            webapp_domains="zoom.us|zoom.com"
            ;;
    esac
    
    # Read the bindings file and find matching lines
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        
        # Check if this is a bindd line
        if [[ "$line" =~ ^bindd[[:space:]]*= ]]; then
            local line_lower=$(echo "$line" | tr '[:upper:]' '[:lower:]')
            
            # Check for app matches in various formats
            # Direct app name match (e.g., "spotify", "obsidian", "signal-desktop")
            if [[ "$line_lower" =~ uwsm[[:space:]]+app[[:space:]]+--[[:space:]]+$app_lower([[:space:]]|$) ]]; then
                bindings+=("$line")
            # Terminal app match (e.g., "btop", "lazydocker", "nvim")
            elif [[ "$line_lower" =~ \$terminal[[:space:]]+-e[[:space:]]+$app_lower([[:space:]]|$) ]]; then
                bindings+=("$line")
            # Webapp match - check by URL domain if defined
            elif [[ "$line_lower" =~ omarchy-launch-webapp ]]; then
                if [[ -n "$webapp_domains" ]]; then
                    # Extract URL from the line
                    if [[ "$line" =~ omarchy-launch-webapp[[:space:]]+\"([^\"]+)\" ]]; then
                        local url="${BASH_REMATCH[1]}"
                        # Check if URL matches any of the webapp domains
                        if [[ "$url" =~ ($webapp_domains) ]]; then
                            bindings+=("$line")
                        fi
                    fi
                else
                    # Fallback to label matching for unknown webapps
                    if [[ "$line" =~ ,[[:space:]]*([^,]+),[[:space:]]*exec ]]; then
                        local label=$(echo "$line" | sed -n 's/.*,[[:space:]]*\([^,]*\),[[:space:]]*exec.*/\1/p' | xargs)
                        local label_lower=$(echo "$label" | tr '[:upper:]' '[:lower:]')
                        if [[ "$label_lower" == "$app_lower" ]]; then
                            bindings+=("$line")
                        fi
                    fi
                fi
            # Docker special case
            elif [[ "$app_lower" == "docker" ]] && [[ "$line_lower" =~ (docker|lazydocker) ]]; then
                bindings+=("$line")
            # 1password special cases
            elif [[ "$app_lower" == "1password-beta" || "$app_lower" == "1password-cli" ]] && [[ "$line_lower" =~ 1password ]]; then
                bindings+=("$line")
            # Nautilus (File manager)
            elif [[ "$app_lower" == "nautilus" ]] && [[ "$line_lower" =~ nautilus ]]; then
                bindings+=("$line")
            fi
        fi
    done < "$BINDINGS_FILE"
    
    # Return unique bindings
    printf '%s\n' "${bindings[@]}" | sort -u
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


# Enhanced selection menu using gum with integrated keyboard toggle
enhanced_select_packages() {
    local installed_packages=("$@")
    local all_items=()
    local item_types=()
    local display_items=()
    local bindings_found=()
    
    # Parse arguments - first determine where packages end and webapps begin
    local separator_index=-1
    for i in "${!installed_packages[@]}"; do
        if [[ "${installed_packages[$i]}" == "--webapps--" ]]; then
            separator_index=$i
            break
        fi
    done
    
    if [[ $separator_index -ge 0 ]]; then
        # Split into packages and webapps
        for ((i=0; i<separator_index; i++)); do
            all_items+=("${installed_packages[$i]}")
            item_types+=("package")
        done
        for ((i=separator_index+1; i<${#installed_packages[@]}; i++)); do
            all_items+=("${installed_packages[$i]}")
            item_types+=("webapp")
        done
    else
        # All are packages
        for item in "${installed_packages[@]}"; do
            all_items+=("$item")
            item_types+=("package")
        done
    fi
    
    # Build display items with type indicators and binding markers
    for i in "${!all_items[@]}"; do
        local prefix=""
        if [[ "${item_types[$i]}" == "webapp" ]]; then
            prefix="🌐 "
        else
            prefix="📦 "
        fi
        
        # Check if this item has keyboard bindings
        local item_bindings=$(find_app_bindings "${all_items[$i]}")
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
        for type in "${item_types[@]}"; do
            if [[ "$type" == "package" ]]; then
                ((pkg_count++))
            else
                ((webapp_count++))
            fi
        done
        
        gum style \
            --foreground 214 \
            --bold \
            "Found $pkg_count packages and $webapp_count webapps"
        
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
    
    while IFS= read -r selected_item; do
        # Remove emoji prefix (📦 or 🌐) and keyboard marker (⌨)
        local clean_item=$(echo "$selected_item" | sed 's/^[📦🌐] //' | sed 's/ ⌨$//')
        
        # Find matching item in original arrays
        for i in "${!all_items[@]}"; do
            if [[ "${all_items[$i]}" == "$clean_item" ]]; then
                if [[ "${item_types[$i]}" == "webapp" ]]; then
                    selected_webapps+=("$clean_item")
                else
                    selected_packages+=("$clean_item")
                fi
                break
            fi
        done
    done <<< "$selected_items"
    
    # Use newline-delimited strings to preserve items with spaces
    SELECTED_PACKAGES=$(printf '%s\n' "${selected_packages[@]}")
    SELECTED_WEBAPPS=$(printf '%s\n' "${selected_webapps[@]}")
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
        
        if gum spin --spinner dot --title "Removing $webapp..." -- bash -c "omarchy-webapp-remove '$webapp' >/dev/null 2>&1"; then
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
    local packages=("$@")
    local webapps=()
    local all_bindings_to_remove=()

    # Global success tracking
    local total_attempted=0
    local total_failed=0
    
    # Parse arguments - find separator
    local separator_index=-1
    for i in "${!packages[@]}"; do
        if [[ "${packages[$i]}" == "--webapps--" ]]; then
            separator_index=$i
            break
        fi
    done
    
    if [[ $separator_index -ge 0 ]]; then
        # Split into packages and webapps arrays
        local pkg_array=()
        local webapp_array=()
        
        for ((i=0; i<separator_index; i++)); do
            pkg_array+=("${packages[$i]}")
        done
        for ((i=separator_index+1; i<${#packages[@]}; i++)); do
            webapp_array+=("${packages[$i]}")
        done
        
        # Collect bindings to remove if enabled
        if [[ "$REMOVE_BINDINGS" == true ]]; then
            echo ""
            gum style --foreground 51 "Checking for keyboard shortcuts..."
            
            for pkg in "${pkg_array[@]}"; do
                local pkg_bindings=$(find_app_bindings "$pkg")
                if [[ -n "$pkg_bindings" ]]; then
                    while IFS= read -r binding; do
                        if [[ -n "$binding" ]]; then
                            all_bindings_to_remove+=("$binding")
                        fi
                    done <<< "$pkg_bindings"
                fi
            done
            
            for webapp in "${webapp_array[@]}"; do
                local webapp_bindings=$(find_app_bindings "$webapp")
                if [[ -n "$webapp_bindings" ]]; then
                    while IFS= read -r binding; do
                        if [[ -n "$binding" ]]; then
                            all_bindings_to_remove+=("$binding")
                        fi
                    done <<< "$webapp_bindings"
                fi
            done
            
            # Remove bindings first
            if [[ ${#all_bindings_to_remove[@]} -gt 0 ]]; then
                echo ""
                gum style --foreground 51 "Removing ${#all_bindings_to_remove[@]} keyboard shortcut(s)..."
                remove_bindings_from_file "${all_bindings_to_remove[@]}"
            else
                echo ""
                gum log --level info "No keyboard shortcuts found"
            fi
        fi
        
        # Track package removal results
        total_attempted=$((${#pkg_array[@]} + ${#webapp_array[@]}))

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

        total_failed=$((pkg_failures + webapp_failures))
    else
        # All are packages
        # Collect bindings to remove if enabled
        if [[ "$REMOVE_BINDINGS" == true ]]; then
            echo ""
            gum style --foreground 51 "Checking for keyboard shortcuts..."
            
            for pkg in "${packages[@]}"; do
                local pkg_bindings=$(find_app_bindings "$pkg")
                if [[ -n "$pkg_bindings" ]]; then
                    while IFS= read -r binding; do
                        if [[ -n "$binding" ]]; then
                            all_bindings_to_remove+=("$binding")
                        fi
                    done <<< "$pkg_bindings"
                fi
            done
            
            # Remove bindings first
            if [[ ${#all_bindings_to_remove[@]} -gt 0 ]]; then
                echo ""
                gum style --foreground 51 "Removing ${#all_bindings_to_remove[@]} keyboard shortcut(s)..."
                remove_bindings_from_file "${all_bindings_to_remove[@]}"
            else
                echo ""
                gum log --level info "No keyboard shortcuts found"
            fi
        fi

        # Track package removal results
        total_attempted=${#packages[@]}
        remove_packages "${packages[@]}"
        total_failed=$?
    fi
    
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
    gum style --foreground 51 "🔍 Scanning for installed packages and webapps..."
    echo ""
    
    # Show spinners while scanning (the actual functions are fast, so we add a small delay for visual feedback)
    gum spin --spinner globe --title "Checking packages..." -- sleep 0.8
    readarray -t installed_packages < <(get_installed_packages)
    
    gum spin --spinner globe --title "Checking webapps..." -- sleep 0.8
    readarray -t installed_webapps < <(get_installed_webapps)
    
    if [[ ${#installed_packages[@]} -eq 0 ]] && [[ ${#installed_webapps[@]} -eq 0 ]]; then
        echo ""
        gum style \
            --foreground 82 \
            --border rounded \
            --border-foreground 82 \
            --padding "1 2" \
            --margin "1" \
            "✓ System is clean!" \
            "" \
            "No removable packages or webapps found."
        echo ""
        exit 0
    fi
    
    # Go directly to selection
    
    # Combine packages and webapps with separator
    local all_items=()
    all_items+=("${installed_packages[@]}")
    if [[ ${#installed_webapps[@]} -gt 0 ]]; then
        all_items+=("--webapps--")
        all_items+=("${installed_webapps[@]}")
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
    
    # Convert to arrays properly - these are space-separated strings from the selection function
    local packages_array=()
    local webapps_array=()
    
    # Parse newline-delimited strings into arrays
    if [[ -n "$selected_packages" ]]; then
        readarray -t packages_array <<< "$selected_packages"
    fi
    
    if [[ -n "$selected_webapps" ]]; then
        readarray -t webapps_array <<< "$selected_webapps"
    fi
    
    # Check if any selected items have keyboard shortcuts
    local selected_items_have_bindings=false
    local total_bindings=0
    
    # Only check for bindings if the bindings file exists
    if [[ -f "$BINDINGS_FILE" ]]; then
        for pkg in "${packages_array[@]}"; do
            local bindings=$(find_app_bindings "$pkg")
            if [[ -n "$bindings" ]]; then
                selected_items_have_bindings=true
                total_bindings=$((total_bindings + $(echo "$bindings" | wc -l)))
            fi
        done
        
        for webapp in "${webapps_array[@]}"; do
            local bindings=$(find_app_bindings "$webapp")
            if [[ -n "$bindings" ]]; then
                selected_items_have_bindings=true
                total_bindings=$((total_bindings + $(echo "$bindings" | wc -l)))
            fi
        done
    fi
    
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
            local bindings=$(find_app_bindings "$pkg")
            if [[ -n "$bindings" ]]; then
                gum style \
                    --foreground 214 \
                    "📦 $pkg"
            fi
        done
        
        for webapp in "${webapps_array[@]}"; do
            local bindings=$(find_app_bindings "$webapp")
            if [[ -n "$bindings" ]]; then
                gum style \
                    --foreground 214 \
                    "🌐 $webapp"
            fi
        done
        
        echo ""
        
        gum style \
            --foreground 51 \
            --italic \
            "Do you want to remove their keyboard shortcuts from ~/.config/hypr/bindings.conf?"
        
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
    
    # Final confirmation
    clear
    
    # Build confirmation content using separate lines
    local total_count=$((${#packages_array[@]} + ${#webapps_array[@]}))
    
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
    
    # Show keyboard shortcuts info if applicable
    if [[ "$REMOVE_BINDINGS" == true ]]; then
        local total_bindings=0
        for pkg in "${packages_array[@]}"; do
            local bindings=$(find_app_bindings "$pkg")
            [[ -n "$bindings" ]] && total_bindings=$((total_bindings + $(echo "$bindings" | wc -l)))
        done
        for webapp in "${webapps_array[@]}"; do
            local bindings=$(find_app_bindings "$webapp")
            [[ -n "$bindings" ]] && total_bindings=$((total_bindings + $(echo "$bindings" | wc -l)))
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