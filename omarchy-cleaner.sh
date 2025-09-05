#!/bin/bash

# Omarchy Cleaner - Remove unwanted default applications from Omarchy

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

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
    # "docker"
    # "docker-buildx"
    # "docker-compose"
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
    local installed=()
    for app in "${DEFAULT_APPS[@]}"; do
        if is_package_installed "$app"; then
            installed+=("$app")
        fi
    done
    echo "${installed[@]}"
}

# Function to get list of installed webapps from our removal list
get_installed_webapps() {
    local installed=()
    for webapp in "${DEFAULT_WEBAPPS[@]}"; do
        if is_webapp_installed "$webapp"; then
            installed+=("$webapp")
        fi
    done
    echo "${installed[@]}"
}


# Simple text-based selection menu
simple_select_packages() {
    local installed_packages=("$@")
    local installed_webapps=()
    local all_items=()
    local item_types=()
    local selected_status=()
    local selected_packages=()
    
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
    
    # Initialize all as selected
    for i in "${!all_items[@]}"; do
        selected_status[$i]=1
    done
    
    while true; do
        clear
        echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║         Omarchy Cleaner v1.0           ║${NC}"
        echo -e "${BLUE}║   Remove unwanted default applications ║${NC}"
        echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${CYAN}Items available for removal:${NC}"
        echo ""
        
        # Display packages section if any exist
        local has_packages=false
        local has_webapps=false
        for type in "${item_types[@]}"; do
            if [[ "$type" == "package" ]]; then
                has_packages=true
            elif [[ "$type" == "webapp" ]]; then
                has_webapps=true
            fi
        done
        
        if [[ "$has_packages" == true ]]; then
            echo -e "${BOLD}Apps found:${NC}"
        fi
        
        # Display items with selection status
        for i in "${!all_items[@]}"; do
            if [[ "${item_types[$i]}" == "webapp" ]] && [[ "$has_webapps" == true ]] && [[ "$has_packages" == true ]]; then
                # Print webapp header only once
                local first_webapp=true
                for ((j=0; j<i; j++)); do
                    if [[ "${item_types[$j]}" == "webapp" ]]; then
                        first_webapp=false
                        break
                    fi
                done
                if [[ "$first_webapp" == true ]]; then
                    echo ""
                    echo -e "${BOLD}Webapps found:${NC}"
                fi
            fi
            
            local num=$((i+1))
            local prefix=""
            if [[ "${item_types[$i]}" == "webapp" ]]; then
                prefix="[WebApp] "
            fi
            
            if [[ ${selected_status[$i]} -eq 1 ]]; then
                echo -e "  ${GREEN}[$num]${NC} ✓ $prefix${all_items[$i]}"
            else
                echo -e "  ${YELLOW}[$num]${NC}   $prefix${all_items[$i]}"
            fi
        done
        
        echo ""
        
        # Count selected
        local count=0
        for status in "${selected_status[@]}"; do
            [[ $status -eq 1 ]] && ((count++))
        done
        echo -e "${BOLD}Currently selected: ${GREEN}$count${NC} of ${#all_items[@]} items"
        echo ""
        
        echo -e "${BOLD}Enter your choice:${NC}"
        echo -e "  • ${CYAN}1-${#all_items[@]}${NC} to toggle an item"
        echo -e "  • ${CYAN}A${NC} to select all"
        echo -e "  • ${CYAN}N${NC} to select none"
        echo -e "  • ${GREEN}C${NC} to continue"
        echo -e "  • ${RED}Q${NC} to quit"
        echo ""
        read -p "Choice: " choice </dev/tty
        
        case $choice in
            [1-9]|[1-9][0-9])
                if [[ $choice -le ${#all_items[@]} ]] && [[ $choice -ge 1 ]]; then
                    local idx=$((choice-1))
                    if [[ ${selected_status[$idx]} -eq 1 ]]; then
                        selected_status[$idx]=0
                    else
                        selected_status[$idx]=1
                    fi
                fi
                ;;
            [aA])
                for i in "${!all_items[@]}"; do
                    selected_status[$i]=1
                done
                ;;
            [nN])
                for i in "${!all_items[@]}"; do
                    selected_status[$i]=0
                done
                ;;
            [cC])
                # Collect selected items with their types
                local selected_packages=()
                local selected_webapps=()
                
                for i in "${!all_items[@]}"; do
                    if [[ ${selected_status[$i]} -eq 1 ]]; then
                        if [[ "${item_types[$i]}" == "webapp" ]]; then
                            selected_webapps+=("${all_items[$i]}")
                        else
                            selected_packages+=("${all_items[$i]}")
                        fi
                    fi
                done
                
                if [[ ${#selected_packages[@]} -eq 0 ]] && [[ ${#selected_webapps[@]} -eq 0 ]]; then
                    echo ""
                    echo -e "${YELLOW}No items selected! Please select at least one item.${NC}"
                    read -p "Press Enter to continue..." </dev/tty
                else
                    SELECTED_PACKAGES="${selected_packages[*]}"
                    SELECTED_WEBAPPS="${selected_webapps[*]}"
                    return 0
                fi
                ;;
            [qQ])
                return 1
                ;;
            *)
                echo -e "${RED}Invalid option!${NC}"
                sleep 1
                ;;
        esac
    done
}

# Function to remove webapps
remove_webapps() {
    local webapps=("$@")
    local failed_webapps=()
    local removed_webapps=()
    
    if [[ ${#webapps[@]} -eq 0 ]]; then
        return 0
    fi
    
    echo -e "\n${BLUE}Starting webapp removal...${NC}\n"
    
    for webapp in "${webapps[@]}"; do
        echo -e "${YELLOW}Removing $webapp webapp...${NC}"
        if omarchy-webapp-remove "$webapp" 2>/dev/null; then
            echo -e "${GREEN}✓ Successfully removed $webapp webapp${NC}"
            removed_webapps+=("$webapp")
        else
            echo -e "${RED}✗ Failed to remove $webapp webapp${NC}"
            failed_webapps+=("$webapp")
        fi
        echo ""
    done
    
    # Summary for webapps
    if [[ ${#removed_webapps[@]} -gt 0 ]]; then
        echo -e "${GREEN}Successfully removed webapps: ${removed_webapps[*]}${NC}"
    fi
    if [[ ${#failed_webapps[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Could not remove webapps: ${failed_webapps[*]}${NC}"
    fi
}

# Function to remove packages
remove_packages() {
    local packages=("$@")
    local failed_packages=()
    local removed_packages=()
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        return 0
    fi
    
    echo -e "\n${BLUE}Starting package removal...${NC}\n"
    
    for pkg in "${packages[@]}"; do
        echo -e "${YELLOW}Removing $pkg...${NC}"
        if sudo pacman -Rns --noconfirm "$pkg" 2>/dev/null; then
            echo -e "${GREEN}✓ Successfully removed $pkg${NC}"
            removed_packages+=("$pkg")
        else
            echo -e "${RED}✗ Failed to remove $pkg (may already be removed or have dependencies)${NC}"
            failed_packages+=("$pkg")
        fi
        echo ""
    done
    
    # Summary for packages
    if [[ ${#removed_packages[@]} -gt 0 ]]; then
        echo -e "${GREEN}Successfully removed packages: ${removed_packages[*]}${NC}"
    fi
    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Could not remove packages: ${failed_packages[*]}${NC}"
    fi
}

# Function to remove both packages and webapps
remove_items() {
    local packages=("$@")
    local webapps=()
    
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
        
        remove_packages "${pkg_array[@]}"
        remove_webapps "${webapp_array[@]}"
    else
        # All are packages
        remove_packages "${packages[@]}"
    fi
    
    # Final summary
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}Removal process completed!${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
}

# Main function
main() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         Omarchy Cleaner v1.0           ║${NC}"
    echo -e "${BLUE}║   Remove unwanted default applications ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${CYAN}Checking for installed packages and webapps...${NC}"
    echo ""
    
    # Get list of installed packages and webapps
    local installed_packages=($(get_installed_packages))
    local installed_webapps=($(get_installed_webapps))
    
    if [[ ${#installed_packages[@]} -eq 0 ]] && [[ ${#installed_webapps[@]} -eq 0 ]]; then
        echo -e "${GREEN}✓ No packages or webapps from the removal lists are currently installed.${NC}"
        echo ""
        echo -e "${CYAN}Nothing to clean!${NC}"
        exit 0
    fi
    
    # Display found items
    local total_items=$((${#installed_packages[@]} + ${#installed_webapps[@]}))
    echo -e "${YELLOW}Found ${total_items} item(s) that can be removed:${NC}"
    echo ""
    
    if [[ ${#installed_packages[@]} -gt 0 ]]; then
        echo -e "${BOLD}Apps found:${NC}"
        for i in "${!installed_packages[@]}"; do
            local num=$((i+1))
            echo -e "  ${CYAN}[$num]${NC} ${installed_packages[$i]}"
        done
        echo ""
    fi
    
    if [[ ${#installed_webapps[@]} -gt 0 ]]; then
        echo -e "${BOLD}Webapps found:${NC}"
        local start_num=$((${#installed_packages[@]} + 1))
        for i in "${!installed_webapps[@]}"; do
            local num=$((start_num + i))
            echo -e "  ${CYAN}[$num]${NC} [WebApp] ${installed_webapps[$i]}"
        done
        echo ""
    fi
    
    echo "Press Enter to continue to item selection, or Ctrl+C to exit..."
    read </dev/tty
    
    # Combine packages and webapps with separator
    local all_items=()
    all_items+=("${installed_packages[@]}")
    if [[ ${#installed_webapps[@]} -gt 0 ]]; then
        all_items+=("--webapps--")
        all_items+=("${installed_webapps[@]}")
    fi
    
    # Use simple text selection - call directly without capturing output
    simple_select_packages "${all_items[@]}"
    local result=$?
    
    if [[ $result -ne 0 ]]; then
        clear
        echo -e "\n${YELLOW}Operation cancelled.${NC}"
        exit 0
    fi
    
    # The function will set global variables with selected items
    local selected_packages="$SELECTED_PACKAGES"
    local selected_webapps="$SELECTED_WEBAPPS"
    
    # Convert to arrays and combine for removal
    local packages_array=($selected_packages)
    local webapps_array=($selected_webapps)
    
    # Create combined array for removal function
    local items_to_remove=()
    items_to_remove+=("${packages_array[@]}")
    if [[ ${#webapps_array[@]} -gt 0 ]]; then
        items_to_remove+=("--webapps--")
        items_to_remove+=("${webapps_array[@]}")
    fi
    
    # Final confirmation
    clear
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║       Confirmation Required             ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${RED}${BOLD}Warning:${NC} You are about to remove the following items:"
    echo ""
    
    if [[ ${#packages_array[@]} -gt 0 ]]; then
        echo -e "${BOLD}Packages:${NC}"
        for pkg in "${packages_array[@]}"; do
            echo -e "  ${BOLD}•${NC} $pkg"
        done
        echo ""
    fi
    
    if [[ ${#webapps_array[@]} -gt 0 ]]; then
        echo -e "${BOLD}Webapps:${NC}"
        for webapp in "${webapps_array[@]}"; do
            echo -e "  ${BOLD}•${NC} [WebApp] $webapp"
        done
        echo ""
    fi
    
    echo -e "${YELLOW}This action cannot be undone.${NC}"
    echo ""
    read -p "Type 'yes' to confirm removal, or anything else to cancel: " confirm </dev/tty
    
    if [[ "$confirm" == "yes" ]]; then
        clear
        remove_items "${items_to_remove[@]}"
        echo ""
        echo "Press Enter to exit..."
        read </dev/tty
    else
        echo -e "\n${YELLOW}Operation cancelled.${NC}"
    fi
}

# Handle Ctrl+C gracefully
trap 'echo -e "\n${YELLOW}Operation cancelled.${NC}"; exit 1' INT

# Run main function
main "$@"