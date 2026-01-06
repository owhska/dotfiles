#!/bin/bash

set -e

# Command line options
ONLY_CONFIG=false
EXPORT_PACKAGES=false

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
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "  --only-config      Only copy config files (skip packages and external tools)"
            echo "  --export-packages  Export package lists for different distros and exit"
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
#progress_install() {
#    local description="$1"
#    shift
#    echo -e "${CYAN}⬇️  $description...${NC}"
#
#    if command -v pv &> /dev/null; then
#        sudo apt-get install -y "$@" 2>&1 | pv -ptebar >/dev/null
#    else
#        sudo apt-get install -y "$@"
#    fi
#
#    echo -e "${GREEN}✔ Concluído: $description${NC}\n"
#}

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

# Banner
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
[[ ! $REPLY =~ ^[Yy]$ ]] && exit 1

# Update system
if [ "$ONLY_CONFIG" = false ]; then
    msg "Updating system..."
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt-get install -y pv >/dev/null 2>&1 || true
else
    msg "Skipping system update (--only-config mode)"
fi

# Package groups for better organization
PACKAGES_CORE=(
    xorg xorg-dev xbacklight xbindkeys xvkbd xinput
    build-essential i3 i3status sxhkd xdotool
    libnotify-bin libnotify-dev
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
)

PACKAGES_TERMINAL=(
    suckless-tools
    neovim
    emacs-gtk
    ripgrep
    fzf
    tmux
)

PACKAGES_FONTS=(
    fonts-recommended fonts-font-awesome fonts-terminus
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
fi

# Copy configs
msg "Setting up configuration..."
mkdir -p "$CONFIG_DIR"

# Copy i3 config files
cp -r "$SCRIPT_DIR"/i3/* "$CONFIG_DIR"/ || die "Failed to copy i3 config"

# Configuration directories are already in the i3 folder, so we don't need to copy them separately

# Make scripts executable
find "$CONFIG_DIR"/scripts -type f -exec chmod +x {} \; 2>/dev/null || true

# Setup directories
xdg-user-dirs-update
mkdir -p ~/Screenshots

# Install essential components
if [ "$ONLY_CONFIG" = false ]; then
    mkdir -p "$TEMP_DIR" && cd "$TEMP_DIR"

    msg "Installing picom..."
    progress_install "Installing picom" picom|| die "Failed to install picom"
    
    msg "Installing kitty..."
    if ! command -v kitty &> /dev/null; then
      sudo apt update
      progress_install "Installing kitty" kitty
    else
      msg "Kitty already installed"
    fi
    
    msg "Configurando Kitty com transparência..."
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
    git clone https://github.com/owhska/nvim "$HOME/.config/nvim"
    fi

    msg "Setting up Tmux config..."
    if [ ! -d "$HOME/.config/tmux" ]; then
        git clone https://github.com/owhska/tmux "$HOME/.config/tmux"
    fi
    
    # Copy Emacs config
    msg "Installing Emacs config..."
    if [ -f "$SCRIPT_DIR/emacs/.emacs" ]; then
        cp "$SCRIPT_DIR/emacs/.emacs" "$HOME/.emacs"
        msg "Emacs config installed!"
    else
        msg "Warning: .emacs file not found inside emacs directory!"
    fi

    msg "Installing st terminal..."
    sudo apt install -y st || \
    git clone https://git.suckless.org/st "$TEMP_DIR/st" && \
    cd "$TEMP_DIR/st" && sudo make install

    msg "Installing fonts..."
    # Instale fonts do repositório oficial
    sudo apt install -y fonts-firacode fonts-roboto fonts-noto-color-emoji

    msg "Installing themes..."
    # Use temas dos repositórios
    sudo apt install -y arc-theme papirus-icon-theme
        
    msg "Setting up wallpapers..."
    mkdir -p "$CONFIG_DIR/i3/wallpaper"

    # Copia wallpapers do diretório do script
    if [ -d "$SCRIPT_DIR/wallpaper" ]; then
        cp -r "$SCRIPT_DIR/wallpaper"/* "$CONFIG_DIR/i3/wallpaper/" 2>/dev/null || true
        msg "Wallpapers copied from script directory"
        
        # Verifica se o wall.jpg existe e configura como padrão
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

    # Configuração do i3status
    msg "Setting up i3status configuration..."
    mkdir -p "$CONFIG_DIR"

    # Copia configurações do i3
    cp -r "$SCRIPT_DIR"/i3/* "$CONFIG_DIR"/ || die "Failed to copy i3 config"

    # Cria configuração do i3status se não existir
    if [ ! -f "$CONFIG_DIR/i3status.conf" ]; then
        msg "Creating i3status configuration..."
        cat > "$CONFIG_DIR/i3status.conf" << 'EOF'
    general {
        output_format = "i3bar"
        colors = true
        interval = 5          # Atualiza a cada 5 segundos
    }

    # Ordem dos módulos exibidos (da esquerda para a direita)
    #order += "wireless _first_"
    order += "disk /"
    #order += "battery all"
    order += "cpu_usage"
    order += "memory"
    order += "time"
    order += "ethernet _first_"

    # Indicador de Ethernet simplificado
    ethernet _first_ {
        format_up = "🌐 Online"
        format_down = "🌐 Offline"
    }

    # Mostra status da rede Wi-Fi
    wireless _first_ {
        format_up = "WiFi: %quality at %essid"
        format_down = "WiFi: down"
    }

    # Mostra uso de CPU
    cpu_usage {
        format = "CPU: %usage"
    }

    # Mostra uso de memória RAM
    memory {
        format = "RAM: %used / %total"
        threshold_degraded = "10%"
        format_degraded = "MEMORY: %free"
    }


    # Mostra data e hora (no padrão do i3)
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

 # Optional tools
    clear
    read -p "Install optional tools (browsers, editors, etc)? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        msg "Installing optional tools..."
        optional_packages=(
        vim
        fastfetch
        python3
        nodejs
        )
    sudo apt install -y "${optional_packages[@]}" || msg "Some optional tools failed to install"
    msg "Optional tools installation completed"
    fi
else
    msg "Skipping external tool installation (--only-config mode)"
fi

# =============================================================================
# ZSH + Oh My Zsh + Plugins (VERSÃO SEGURA)
# =============================================================================
if [ "$ONLY_CONFIG" = false ]; then
    clear
    read -p "Instalar e configurar zsh + oh-my-zsh como padrão? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        msg "Instalando zsh e dependências..."
        sudo apt install -y zsh curl git || die "Falha ao instalar zsh ou dependências"

        # Verifica se o zsh foi instalado corretamente
        if ! command -v zsh &> /dev/null; then
            die "zsh não foi instalado corretamente"
        fi

        # Configura zsh no /etc/shells primeiro
        ZSH_PATH=$(which zsh)
        if ! grep -q "$ZSH_PATH" /etc/shells; then
            echo "$ZSH_PATH" | sudo tee -a /etc/shells
        fi

        msg "Instalando Oh My Zsh..."
        # Faz backup do .zshrc atual se existir
        if [ -f "$HOME/.zshrc" ]; then
            cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%s)"
            msg "Backup do .zshrc existente criado"
        fi

        # Instala Oh My Zsh em modo não-interativo
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

        msg "Instalando plugins populares do zsh..."
        ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
        
        # Instala plugins apenas se o Oh My Zsh foi instalado
        if [ -d "$ZSH_CUSTOM" ]; then
            git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions 2>/dev/null || true
            git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting 2>/dev/null || true
            git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM}/plugins/zsh-completions 2>/dev/null || true
            git clone https://github.com/supercrabtree/k ${ZSH_CUSTOM}/plugins/k 2>/dev/null || true
            git clone https://github.com/agkozak/zsh-z ${ZSH_CUSTOM}/plugins/zsh-z 2>/dev/null || true
        else
            msg "Aviso: Diretório do Oh My Zsh não encontrado, pulando plugins..."
        fi

#        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#        CUSTOM_THEME_SOURCE="$SCRIPT_DIR/custom.zsh-theme"
#        CUSTOM_THEME_DEST="$HOME/.oh-my-zsh/themes/custom.zsh-theme"

#        if [ -f "$CUSTOM_THEME_SOURCE" ]; then
            # Garante que o diretório de temas existe
#            mkdir -p "$(dirname "$CUSTOM_THEME_DEST")"
#            msg "Copiando tema personalizado..."
#            cp "$CUSTOM_THEME_SOURCE" "$CUSTOM_THEME_DEST"
#            chown $USER:$USER "$CUSTOM_THEME_DEST" 2>/dev/null || true
#            msg "✓ Tema personalizado copiado com sucesso!"
#        else
#            msg "Aviso: Arquivo custom.zsh-theme não encontrado em $CUSTOM_THEME_SOURCE"
#            msg "  Procurando em: $(pwd)/custom.zsh-theme"
#        fi
       
        msg "Configurando .zshrc personalizado..."
        # Cria .zshrc personalizado
        cat > "$HOME/.zshrc" << 'EOF'
# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"
# ZSH_THEME="custom"

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

# Aliases úteis
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

        # Configuração básica do Powerlevel10k
        if [ ! -f "$HOME/.p10k.zsh" ]; then
            cat > "$HOME/.p10k.zsh" << 'EOF'
# Configuração básica do Powerlevel10k
POWERLEVEL9K_MODE='nerdfont-complete'
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time background_jobs)
POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
POWERLEVEL9K_SHORTEN_DIR_LENGTH=2
EOF
        fi

        # AGORA muda o shell padrão - APENAS no final de tudo
        msg "Definindo zsh como shell padrão para sessões futuras..."
        sudo chsh -s $(which zsh) $USER

        msg "zsh + oh-my-zsh + powerlevel10k instalados com sucesso!"
        echo -e "${GREEN}Na próxima vez que você fizer login ou abrir um novo terminal, o zsh será ativado automaticamente!${NC}"
        echo -e "${GREEN}Execute 'p10k configure' para personalizar o Powerlevel10k depois.${NC}"
        
        # Apenas informa o usuário sem executar o zsh
        echo
        echo -e "${CYAN}Para ativar o zsh AGORA (opcional), execute:${NC}"
        echo -e "${CYAN}  exec zsh${NC}"
        echo -e "${CYAN}Ou simplesmente feche e reabra o terminal.${NC}"
    fi
else
    msg "Pulando instalação do zsh/oh-my-zsh (--only-config mode)"
fi

# Done
echo -e "\n${GREEN}Installation complete!${NC}"
echo "1. Log out and select 'i3' from your display manager"
echo "2. Press Super+Z for keybindings"
