#!/bin/bash

set -e

# Command line options
ONLY_CONFIG=false
EXPORT_PACKAGES=false
NON_INTERACTIVE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --only-config)
            ONLY_CONFIG=true
            shift
            ;;
        --export-packages)
            EXPORT_PACKAGES=true
            shift
            ;;
        --non-interactive)
            NON_INTERACTIVE=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "  --only-config      Only copy config files (skip packages and external tools)"
            echo "  --export-packages  Export package lists for different distros and exit"
            echo "  --non-interactive  Run without any user prompts (use defaults)"
            echo "  --help            Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/i3"
TEMP_DIR="/tmp/i3_$$"
LOG_FILE="$HOME/i3-install.log"

# Logging and cleanup
exec > >(tee -a "$LOG_FILE") 2>&1
trap "rm -rf $TEMP_DIR" EXIT

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

die() { echo -e "${RED}ERROR: $*${NC}" >&2; exit 1; }
msg() { echo -e "${CYAN}$*${NC}"; }

# User responses storage
INSTALL_I3=true
INSTALL_NVIDIA=false
INSTALL_CUDA=false
INSTALL_OPTIONAL_TOOLS=false
INSTALL_ZSH=false

# Function to export packages
export_packages() {
    echo "Exporting installed packages for Debian/Ubuntu..."
    dpkg --get-selections > "$HOME/package_list_debian.txt"
    echo "Packages exported to ~/package_list_debian.txt"
}

# Check if we should export packages and exit
if [ "$EXPORT_PACKAGES" = true ]; then
    export_packages
    exit 0
fi

# Gather user preferences early
if [ "$NON_INTERACTIVE" = false ]; then
    clear
    echo -e "${CYAN}"
    echo " +-+-+-+-+-+-+-+-+-+-+-+-+-+ "
    echo " |o|w|h|s|k|a| "
    echo " +-+-+-+-+-+-+-+-+-+-+-+-+-+ "
    echo " |s|e|t|u|p|   "
    echo " +-+-+-+-+-+-+-+-+-+-+-+-+-+ "
    echo -e "${NC}\n"

    read -p "Install i3? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
fi

# Check for NVIDIA GPU early
HAS_NVIDIA=false
if lspci | grep -i nvidia > /dev/null 2>&1; then
    HAS_NVIDIA=true
    if [ "$NON_INTERACTIVE" = false ]; then
        echo -e "${YELLOW}NVIDIA GPU detected!${NC}"
        read -p "Install NVIDIA drivers? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            INSTALL_NVIDIA=true
            read -p "Install CUDA toolkit for GPU computing? (y/n) " -n 1 -r
            echo
            [[ $REPLY =~ ^[Yy]$ ]] && INSTALL_CUDA=true
        fi
    else
        # Non-interactive defaults
        INSTALL_NVIDIA=true
        INSTALL_CUDA=false
    fi
fi

if [ "$NON_INTERACTIVE" = false ]; then
    read -p "Install optional tools (browsers, editors, etc)? (y/n) " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && INSTALL_OPTIONAL_TOOLS=true
    
    read -p "Install and configure zsh + oh-my-zsh as default shell? (y/n) " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && INSTALL_ZSH=true
else
    INSTALL_OPTIONAL_TOOLS=true
    INSTALL_ZSH=true
fi

progress_install() {
    local description="$1"
    shift
    local packages=("$@")
    local total_packages=${#packages[@]}
    local installed_count=0
    
    # Cabeçalho com emoji e descrição
    echo -e "\n${CYAN}📦 $description${NC}"
    echo -e "${GRAY}═${NC}"$(printf '%.0s═' $(seq 1 $((${#description} + 2))))
    
    # Verificar se há pacotes para instalar
    if [ $total_packages -eq 0 ]; then
        echo -e "${YELLOW}⚠️  Nenhum pacote especificado${NC}\n"
        return 1
    fi
    
    echo -e "${BLUE}📊 Total de pacotes: $total_packages${NC}"
    
    # Verificar pacotes já instalados
    local to_install=()
    for pkg in "${packages[@]}"; do
        if dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
            echo -e "  ${GREEN}✓${NC} $pkg ${GRAY}(já instalado)${NC}"
            ((installed_count++))
        else
            to_install+=("$pkg")
        fi
    done
    
    # Se todos já estiverem instalados
    if [ $installed_count -eq $total_packages ]; then
        echo -e "${GREEN}✅ Todos os pacotes já estão instalados${NC}\n"
        return 0
    fi
    
    # Mostrar o que será instalado
    if [ ${#to_install[@]} -gt 0 ]; then
        echo -e "${YELLOW}⬇️  Pacotes para instalar: ${#to_install[@]}${NC}"
        printf "  • %s\n" "${to_install[@]}"
    fi
    
    echo -e "${BLUE}⏳ Iniciando instalação...${NC}"
    
    # Instalação com progresso
    local start_time=$(date +%s)
    
    if command -v pv &> /dev/null && [ -t 1 ]; then
        # Com PV (barra de progresso)
        sudo apt-get update 2>/dev/null
        sudo apt-get install -y "${to_install[@]}" 2>&1 | \
            pv -ptebar -s $(( ${#to_install[@]} * 50 )) -N "$description" >/dev/null
    else
        # Sem PV (modo normal)
        sudo apt-get update
        sudo apt-get install -y "${to_install[@]}"
    fi
    
    local exit_code=${PIPESTATUS[0]}
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Resultado
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✅ $description concluído em ${duration}s${NC}"
        
        # Verificar instalação bem-sucedida
        local success_count=0
        for pkg in "${to_install[@]}"; do
            if dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
                ((success_count++))
            fi
        done
        
        echo -e "  ${GREEN}${success_count}/${#to_install[@]} pacotes instalados com sucesso${NC}"
    else
        echo -e "${RED}❌ Erro na instalação de $description${NC}"
        echo -e "${YELLOW}Código de erro: $exit_code${NC}"
    fi
    
    echo ""
    return $exit_code
}

# Update system
if [ "$ONLY_CONFIG" = false ]; then
    msg "Updating system..."
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt-get install -y pv >/dev/null 2>&1 || true
    
    # Install NVIDIA drivers if requested
    if [ "$HAS_NVIDIA" = true ] && [ "$INSTALL_NVIDIA" = true ]; then
        msg "Installing NVIDIA drivers..."
        
        # Determine Ubuntu/Debian version
        if command -v lsb_release > /dev/null; then
            DISTRO=$(lsb_release -is)
            CODENAME=$(lsb_release -cs)
        else
            # Fallback for Debian
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                DISTRO=$ID
                CODENAME=$VERSION_CODENAME
            else
                DISTRO="unknown"
                CODENAME="unknown"
            fi
        fi
        
        # Add NVIDIA repository for Ubuntu
        if [ "$DISTRO" = "ubuntu" ]; then
            msg "Adding NVIDIA repository for Ubuntu $CODENAME..."
            sudo apt-get install -y software-properties-common
            sudo add-apt-repository -y ppa:graphics-drivers/ppa
            sudo apt-get update
        fi
        
        # Install the recommended driver
        msg "Finding recommended NVIDIA driver..."
        if command -v ubuntu-drivers > /dev/null; then
            RECOMMENDED_DRIVER=$(ubuntu-drivers devices | grep recommended | awk '{print $3}')
            if [ -n "$RECOMMENDED_DRIVER" ]; then
                msg "Installing recommended driver: $RECOMMENDED_DRIVER"
                sudo apt-get install -y "$RECOMMENDED_DRIVER"
            else
                # Fallback to common driver
                sudo apt-get install -y nvidia-driver-535
            fi
        else
            # For Debian or systems without ubuntu-drivers
            sudo apt-get install -y nvidia-driver firmware-misc-nonfree
        fi
        
        # Install CUDA toolkit if requested
        if [ "$INSTALL_CUDA" = true ]; then
            msg "Installing CUDA toolkit..."
            if [ "$DISTRO" = "ubuntu" ]; then
                wget https://developer.download.nvidia.com/compute/cuda/repos/$DISTRO$CODENAME/x86_64/cuda-keyring_1.1-1_all.deb
                sudo dpkg -i cuda-keyring_1.1-1_all.deb
                sudo apt-get update
                sudo apt-get install -y cuda-toolkit
            else
                sudo apt-get install -y nvidia-cuda-toolkit
            fi
        fi
        
        # Install GPU monitoring tools
        msg "Installing GPU monitoring tools..."
        sudo apt-get install -y nvidia-smi nvtop
        
        # Configure Xorg for NVIDIA
        msg "Creating Xorg configuration for NVIDIA..."
        sudo mkdir -p /etc/X11/xorg.conf.d
        sudo tee /etc/X11/xorg.conf.d/10-nvidia.conf > /dev/null << 'EOF'
Section "Device"
    Identifier     "Device0"
    Driver         "nvidia"
    VendorName     "NVIDIA Corporation"
    Option         "AllowEmptyInitialConfiguration"
    Option         "Coolbits" "28"
    Option         "TripleBuffer" "on"
EndSection

Section "Screen"
    Identifier     "Screen0"
    Device         "Device0"
    Monitor        "Monitor0"
    DefaultDepth    24
    Option         "Stereo" "0"
    Option         "metamodes" "nvidia-auto-select +0+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}"
    Option         "SLI" "Off"
    Option         "MultiGPU" "Off"
    Option         "BaseMosaic" "off"
    SubSection     "Display"
        Depth       24
    EndSubSection
EndSection
EOF
        
        msg "${GREEN}NVIDIA drivers installed!${NC}"
        echo -e "${YELLOW}A reboot is required for changes to take effect.${NC}"
        
        # Create GPU check script
        mkdir -p "$CONFIG_DIR/scripts"
        cat > "$CONFIG_DIR/scripts/check-gpu" << 'EOF'
#!/bin/bash
# Check GPU acceleration status

echo "=== GPU Acceleration Status Check ==="
echo ""

# Check NVIDIA
if command -v nvidia-smi &> /dev/null; then
    echo "NVIDIA GPU:"
    nvidia-smi --query-gpu=name,driver_version,temperature.gpu,utilization.gpu --format=csv,noheader
    echo ""
    
    # Check if NVIDIA is in use
    if glxinfo | grep -i nvidia > /dev/null 2>&1; then
        echo "✅ NVIDIA acceleration is ACTIVE"
    else
        echo "⚠️  NVIDIA detected but not active"
    fi
fi

echo ""
echo "OpenGL Information:"
if command -v glxinfo &> /dev/null; then
    glxinfo | grep -E "(OpenGL vendor|OpenGL renderer|OpenGL version)" | head -3
else
    echo "glxinfo not installed. Install with: sudo apt install mesa-utils"
fi

echo ""
echo "Vulkan Information:"
if command -v vulkaninfo &> /dev/null; then
    vulkaninfo --summary 2>/dev/null | grep -A5 "GPU"
else
    echo "Vulkan info not available"
fi
EOF
        chmod +x "$CONFIG_DIR/scripts/check-gpu"
    else
        msg "${YELLOW}No NVIDIA GPU detected or NVIDIA installation skipped.${NC}"
    fi
else
    msg "Skipping system update (--only-config mode)"
fi

# Package groups for better organization
PACKAGES_CORE=(
    xorg xorg-dev xbacklight xbindkeys xvkbd xinput
    build-essential i3 i3status sxhkd xdotool
    libnotify-bin libnotify-dev mesa-utils
)

PACKAGES_UI=(
    i3status rofi dunst feh lxappearance network-manager-gnome lxpolkit
)

PACKAGES_FILE_MANAGER=(
    thunar thunar-archive-plugin thunar-volman
    gvfs-backends dialog mtools smbclient cifs-utils fd-find unzip
)

PACKAGES_AUDIO=(
    pavucontrol pulsemixer pamixer pipewire-audio
)

PACKAGES_UTILITIES=(
    avahi-daemon acpi acpid xfce4-power-manager
    flameshot qimgv micro xdg-user-dirs-gtk
    inxi htop wget curl git
)

PACKAGES_TERMINAL=(
    suckless-tools
    neovim
    emacs-gtk
    ripgrep
    fzf
    tmux
    zsh
)

PACKAGES_FONTS=(
    fonts-recommended fonts-font-awesome fonts-terminus
    fonts-firacode fonts-roboto fonts-noto-color-emoji
)

PACKAGES_BUILD=(
    cmake meson ninja-build curl pkg-config
)

# Install packages by group
if [ "$ONLY_CONFIG" = false ]; then
    msg "Installing core packages..."
    progress_install "Installing core packages" "${PACKAGES_CORE[@]}" || die "Failed to install core packages"

    msg "Installing UI components..."
    progress_install "Installing UI packages" "${PACKAGES_UI[@]}" || die "Failed to install UI packages"

    msg "Installing file manager..."
    progress_install "Installing file manager packages" "${PACKAGES_FILE_MANAGER[@]}" || die "Failed to install file manager"

    msg "Installing audio support..."
    progress_install "Installing audio packages" "${PACKAGES_AUDIO[@]}" || die "Failed to install audio packages"

    msg "Installing system utilities..."
    progress_install "Installing system packages" "${PACKAGES_UTILITIES[@]}" || die "Failed to install utilities"
    
    # Try firefox-esr first (Debian), then firefox (Ubuntu)
    sudo apt-get install firefox-esr 2>/dev/null || sudo apt-get install -y firefox 2>/dev/null || msg "Note: firefox not available, skipping..."

    msg "Installing terminal tools..."
    progress_install "Installing terminal packages" "${PACKAGES_TERMINAL[@]}" || die "Failed to install terminal tools"
    
    # Try exa first (Debian 12), then eza (newer Ubuntu)
    sudo apt-get install exa 2>/dev/null || sudo apt-get install eza 2>/dev/null || msg "Note: exa/eza not available, skipping..."

    msg "Installing fonts..."
    progress_install "Installing fonts packages" "${PACKAGES_FONTS[@]}" || die "Failed to install fonts"

    msg "Installing build dependencies..."
    progress_install "Installing build packages" "${PACKAGES_BUILD[@]}" || die "Failed to install build tools"

    # Enable services
    sudo systemctl enable avahi-daemon acpid
else
    msg "Skipping package installation (--only-config mode)"
fi

# Handle existing config
if [ -d "$CONFIG_DIR" ]; then
    if [ "$NON_INTERACTIVE" = false ]; then
        clear
        read -p "Found existing i3 config. Backup? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            mv "$CONFIG_DIR" "$CONFIG_DIR.bak.$(date +%s)"
            msg "Backed up existing config"
        else
            clear
            read -p "Overwrite without backup? (y/n) " -n 1 -r
            echo
            [[ $REPLY =~ ^[Yy]$ ]] || die "Installation cancelled"
            rm -rf "$CONFIG_DIR"
        fi
    else
        # Non-interactive: backup automatically
        if [ -d "$CONFIG_DIR" ]; then
            mv "$CONFIG_DIR" "$CONFIG_DIR.bak.$(date +%s)"
            msg "Backed up existing config automatically"
        fi
    fi
fi

# Copy configs
msg "Setting up configuration..."
mkdir -p "$CONFIG_DIR"

# Copy i3 config files if they exist
if [ -d "$SCRIPT_DIR/i3" ]; then
    cp -r "$SCRIPT_DIR"/i3/* "$CONFIG_DIR"/ 2>/dev/null || msg "Note: Some i3 config files couldn't be copied"
else
    msg "Note: i3 config directory not found in script folder"
fi

# Make scripts executable
find "$CONFIG_DIR"/scripts -type f -exec chmod +x {} \; 2>/dev/null || true

# Setup directories
xdg-user-dirs-update
mkdir -p ~/Screenshots

# Install essential components
if [ "$ONLY_CONFIG" = false ]; then
    mkdir -p "$TEMP_DIR" && cd "$TEMP_DIR"

    msg "Installing picom..."
    progress_install "Installing picom" picom || msg "Failed to install picom (may be in repo)"
    
    msg "Installing kitty..."
    if ! command -v kitty &> /dev/null; then
      sudo apt update
      progress_install "Installing kitty" kitty || msg "Kitty installation failed"
    else
      msg "Kitty already installed"
    fi
    
    msg "Configuring Kitty with transparency..."
    mkdir -p ~/.config/kitty
    
    cat > ~/.config/kitty/kitty.conf << 'EOF'
# Kitty config with transparency
font_family FiraCode Nerd Font
font_size 13.0

# Transparency
background_opacity 0.6

window_padding_width 40

# Mouse
mouse_hide_wait 3.0
url_color #0087bd
url_style curly

# Performance
repaint_delay 10
sync_to_monitor yes

# Terminal bell
enable_audio_bell no
EOF
    
    msg "Setting up Neovim config..."
    if [ ! -d "$HOME/.config/nvim" ]; then
        git clone https://github.com/owhska/nvim "$HOME/.config/nvim" 2>/dev/null || \
        mkdir -p "$HOME/.config/nvim"
    fi

    msg "Setting up Tmux config..."
    if [ ! -d "$HOME/.config/tmux" ]; then
        git clone https://github.com/owhska/tmux "$HOME/.config/tmux" 2>/dev/null || \
        mkdir -p "$HOME/.config/tmux"
    fi
    
    # Copy Emacs config if exists
    msg "Installing Emacs config..."
    if [ -f "$SCRIPT_DIR/emacs/.emacs" ]; then
        cp "$SCRIPT_DIR/emacs/.emacs" "$HOME/.emacs"
        msg "Emacs config installed!"
    elif [ -f "$SCRIPT_DIR/.emacs" ]; then
        cp "$SCRIPT_DIR/.emacs" "$HOME/.emacs"
        msg "Emacs config installed!"
    else
        msg "Note: .emacs file not found"
    fi

    msg "Installing st terminal..."
    sudo apt install -y st 2>/dev/null || (
        git clone https://git.suckless.org/st "$TEMP_DIR/st" 2>/dev/null && \
        cd "$TEMP_DIR/st" && sudo make install
    ) || msg "Note: st terminal installation failed"

    msg "Installing themes..."
    sudo apt install -y arc-theme papirus-icon-theme 2>/dev/null || msg "Note: themes installation failed"
        
    msg "Setting up wallpapers..."
    mkdir -p "$CONFIG_DIR/i3/wallpaper"

    # Copy wallpapers from script directory if exists
    if [ -d "$SCRIPT_DIR/wallpaper" ]; then
        cp -r "$SCRIPT_DIR/wallpaper"/* "$CONFIG_DIR/i3/wallpaper/" 2>/dev/null || true
        msg "Wallpapers copied from script directory"
        
        # Check if wall.jpg exists
        if [ -f "$CONFIG_DIR/i3/wallpaper/wall.jpg" ]; then
            msg "Your wallpaper 'wall.jpg' found and set as default"
        else
            msg "Note: wall.jpg not found in wallpapers directory"
        fi
    else
        msg "Note: wallpapers directory not found in script folder"
    fi
    
    msg "Installing lightdm..."
    sudo apt install -y lightdm
    sudo systemctl enable lightdm

    # Create i3status configuration if it doesn't exist
    if [ ! -f "$CONFIG_DIR/i3status.conf" ]; then
        msg "Creating i3status configuration..."
        cat > "$CONFIG_DIR/i3status.conf" << 'EOF'
general {
    output_format = "i3bar"
    colors = true
    interval = 5
}

order += "disk /"
order += "cpu_usage"
order += "memory"
order += "time"
order += "ethernet _first_"

ethernet _first_ {
    format_up = "🌐 Online"
    format_down = "🌐 Offline"
}

wireless _first_ {
    format_up = "WiFi: %quality at %essid"
    format_down = "WiFi: down"
}

cpu_usage {
    format = "CPU: %usage"
}

memory {
    format = "RAM: %used / %total"
    threshold_degraded = "10%"
    format_degraded = "MEMORY: %free"
}

time {
    format = "%Y-%m-%d %H:%M:%S"
}

battery all {
    format = "%status %percentage %remaining"
    path = "/sys/class/power_supply/BAT%d/uevent"
    low_threshold = 10
}

disk "/" {
    format = "%free"
}
EOF
    fi

    # Install optional tools if requested
    if [ "$INSTALL_OPTIONAL_TOOLS" = true ]; then
        msg "Installing optional tools..."
        optional_packages=(
            vim
            fastfetch
            python3
            nodejs
            python3-pip
            htop
            ranger
            bat
            yazi
            neofetch
        )
        sudo apt install -y "${optional_packages[@]}" 2>/dev/null || msg "Some optional tools failed to install"
        msg "Optional tools installation completed"
    fi
else
    msg "Skipping external tool installation (--only-config mode)"
fi

# =============================================================================
# ZSH + Oh My Zsh + Plugins
# =============================================================================
if [ "$ONLY_CONFIG" = false ] && [ "$INSTALL_ZSH" = true ]; then
    msg "Installing zsh and dependencies..."
    sudo apt install -y zsh curl git || die "Failed to install zsh or dependencies"

    # Check if zsh was installed correctly
    if ! command -v zsh &> /dev/null; then
        die "zsh was not installed correctly"
    fi

    # Configure zsh in /etc/shells first
    ZSH_PATH=$(which zsh)
    if ! grep -q "$ZSH_PATH" /etc/shells; then
        echo "$ZSH_PATH" | sudo tee -a /etc/shells
    fi

    msg "Installing Oh My Zsh..."
    # Backup existing .zshrc if exists
    if [ -f "$HOME/.zshrc" ]; then
        cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%s)"
        msg "Backup of existing .zshrc created"
    fi

    # Install Oh My Zsh in non-interactive mode
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    msg "Installing popular zsh plugins..."
    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    
    # Install plugins only if Oh My Zsh was installed
    if [ -d "$ZSH_CUSTOM" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions 2>/dev/null || true
        git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting 2>/dev/null || true
        git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM}/plugins/zsh-completions 2>/dev/null || true
        git clone https://github.com/supercrabtree/k ${ZSH_CUSTOM}/plugins/k 2>/dev/null || true
        git clone https://github.com/agkozak/zsh-z ${ZSH_CUSTOM}/plugins/zsh-z 2>/dev/null || true
    else
        msg "Warning: Oh My Zsh directory not found, skipping plugins..."
    fi

    msg "Configuring custom .zshrc..."
    # Create custom .zshrc
    cat > "$HOME/.zshrc" << 'EOF'
# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(
    git
    docker
    zsh-autosuggestions
    zsh-completions
    k
    zsh-z
)

source $ZSH/oh-my-zsh.sh

zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# Useful aliases
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first'
alias cls='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias gitp='git push -f origin'
alias v='nvim'
alias c='clear'
alias q='exit'
alias w='micro'
alias f='yazi'
alias ff="fastfetch"
alias t="tmux"
alias sai="sudo apt install -y"
alias sup="sudo apt update && sudo apt upgrade"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

gpush() {
  git add .
  git commit -m "$*"
  git push
}
EOF

    # Basic Powerlevel10k configuration
    if [ ! -f "$HOME/.p10k.zsh" ]; then
        cat > "$HOME/.p10k.zsh" << 'EOF'
# Basic Powerlevel10k configuration
POWERLEVEL9K_MODE='nerdfont-complete'
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time background_jobs)
POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
POWERLEVEL9K_SHORTEN_DIR_LENGTH=2
EOF
    fi

    # Change default shell for future sessions
    msg "Setting zsh as default shell for future sessions..."
    sudo chsh -s $(which zsh) $USER

    msg "zsh + oh-my-zsh installed successfully!"
    echo -e "${GREEN}zsh will be activated automatically on your next login or new terminal!${NC}"
    
    echo
    echo -e "${CYAN}To activate zsh NOW (optional), run:${NC}"
    echo -e "${CYAN}  exec zsh${NC}"
    echo -e "${CYAN}Or simply close and reopen the terminal.${NC}"
else
    msg "Skipping zsh/oh-my-zsh installation"
fi

# NVIDIA post-installation notes
if [ "$HAS_NVIDIA" = true ] && [ "$INSTALL_NVIDIA" = true ]; then
    echo -e "\n${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}NVIDIA DRIVER INSTALLATION COMPLETE${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "Important commands:"
    echo -e "  • ${YELLOW}nvidia-smi${NC} - Check GPU status and utilization"
    echo -e "  • ${YELLOW}nvidia-settings${NC} - Configure NVIDIA settings"
    echo -e "  • ${YELLOW}nvtop${NC} - GPU monitoring (like htop for GPU)"
    echo -e "  • ${YELLOW}check-gpu${NC} - Check GPU acceleration status"
    echo -e "\n${RED}⚠️  REQUIRED: Reboot your system to enable NVIDIA drivers!${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}\n"
fi

# Final instructions
echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                Installation complete!                    ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo -e "1. ${YELLOW}Log out and select 'i3' from your display manager${NC}"
echo -e "2. ${YELLOW}Press Super+Z for keybindings${NC}"
if [ "$HAS_NVIDIA" = true ] && [ "$INSTALL_NVIDIA" = true ]; then
    echo -e "3. ${YELLOW}Run 'check-gpu' to verify GPU acceleration${NC}"
    echo -e "4. ${RED}REBOOT IS REQUIRED for NVIDIA drivers${NC}"
else
    echo -e "3. ${YELLOW}Enjoy your new i3 setup!${NC}"
fi
echo ""
echo -e "${YELLOW}Installation log saved to: $LOG_FILE${NC}"
echo ""
