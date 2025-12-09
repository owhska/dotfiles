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

# =============================================================================
# VARIÁVEIS GLOBAIS
# =============================================================================

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
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

# Variáveis para progresso
TOTAL_STEPS=0
CURRENT_STEP=0
PACKAGES_INSTALLED=0
TOTAL_PACKAGES=0

# =============================================================================
# FUNÇÕES DE UTILIDADE
# =============================================================================

# Função para exportar pacotes (CORRIGIDA - estava faltando)
export_packages() {
    echo "Exportando lista de pacotes..."
    echo "CORE: ${PACKAGES_CORE[*]}"
    echo "UI: ${PACKAGES_UI[*]}"
    echo "FILE_MANAGER: ${PACKAGES_FILE_MANAGER[*]}"
    echo "AUDIO: ${PACKAGES_AUDIO[*]}"
    echo "UTILITIES: ${PACKAGES_UTILITIES[*]}"
    echo "TERMINAL: ${PACKAGES_TERMINAL[*]}"
    echo "FONTS: ${PACKAGES_FONTS[*]}"
    echo "BUILD: ${PACKAGES_BUILD[*]}"
    echo "OPTIONAL: ${PACKAGES_OPTIONAL[*]}"
}

# Funções de log
die() { echo -e "\n${RED}✗ ERRO: $*${NC}" >&2; exit 1; }
msg() { echo -e "${CYAN}→ $*${NC}"; }
success() { echo -e "${GREEN}✓ $*${NC}"; }
warning() { echo -e "${YELLOW}⚠ $*${NC}"; }
info() { echo -e "${BLUE}ℹ $*${NC}"; }

# Função para mostrar progresso
show_progress() {
    local current=$1
    local total=$2
    local message=$3
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((percentage * width / 100))
    local empty=$((width - filled))
    
    printf "\r${CYAN}["
    printf "%${filled}s" "" | tr ' ' '█'
    printf "%${empty}s" "" | tr ' ' '░'
    printf "] %3d%%${NC} %s" "$percentage" "$message"
    
    if [ $current -eq $total ]; then
        printf "\n"
    fi
}

# Função para mostrar banner de grupo de pacotes
show_package_group() {
    local group_name=$1
    local packages=("${@:2}")
    local count=${#packages[@]}
    
    echo -e "\n${MAGENTA}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${MAGENTA}│${BOLD}  📦 $group_name${NC} ${DIM}($count pacotes)${NC}"
    echo -e "${MAGENTA}├─────────────────────────────────────────────────────────────┤${NC}"
    
    # Mostra pacotes em colunas
    for ((i=0; i<count; i+=3)); do
        printf "${MAGENTA}│${NC} %-25s" "${packages[i]}"
        if [ $((i+1)) -lt $count ]; then
            printf "%-25s" "${packages[i+1]}"
        fi
        if [ $((i+2)) -lt $count ]; then
            printf "%-25s" "${packages[i+2]}"
        fi
        printf "${MAGENTA}│${NC}\n"
    done
    
    echo -e "${MAGENTA}└─────────────────────────────────────────────────────────────┘${NC}"
}

# Função para instalar pacotes com progresso visual
install_packages_with_progress() {
    local group_name=$1
    local packages=("${@:2}")
    local count=${#packages[@]}
    
    if [ $count -eq 0 ]; then
        return 0
    fi
    
    echo -e "\n${CYAN}▸ Instalando $group_name...${NC}"
    show_package_group "$group_name" "${packages[@]}"
    
    # Calcula progresso
    local packages_per_step=$((count / 10))
    if [ $packages_per_step -lt 1 ]; then
        packages_per_step=1
    fi
    
    for ((i=0; i<count; i+=packages_per_step)); do
        local end=$((i+packages_per_step-1))
        if [ $end -ge $count ]; then
            end=$((count-1))
        fi
        
        # Instala um grupo de pacotes
        if sudo apt-get install -y "${packages[@]:i:packages_per_step}" > /dev/null 2>&1; then
            PACKAGES_INSTALLED=$((PACKAGES_INSTALLED + packages_per_step))
            show_progress $PACKAGES_INSTALLED $TOTAL_PACKAGES "Instalando $group_name"
        else
            warning "Alguns pacotes de $group_name podem ter falhado"
        fi
    done
    
    success "$group_name instalado"
    return 0
}

# =============================================================================
# PACOTES ORGANIZADOS
# =============================================================================

# Grupos de pacotes
PACKAGES_CORE=(
    xorg xorg-dev xbacklight xbindkeys xvkbd xinput
    build-essential i3 i3status sxhkd xdotool
    libnotify-bin libnotify-dev
)

PACKAGES_UI=(
    i3status rofi dunst feh lxappearance 
    network-manager-gnome lxpolkit
)

PACKAGES_FILE_MANAGER=(
    thunar thunar-archive-plugin thunar-volman
    gvfs-backends dialog mtools smbclient 
    cifs-utils fd-find unzip
)

PACKAGES_AUDIO=(
    pavucontrol pulsemixer pamixer pipewire-audio
)

PACKAGES_UTILITIES=(
    avahi-daemon acpi acpid xfce4-power-manager
    flameshot qimgv micro xdg-user-dirs-gtk
)

PACKAGES_TERMINAL=(
    suckless-tools neovim emacs-gtk ripgrep
)

PACKAGES_FONTS=(
    fonts-recommended fonts-font-awesome fonts-terminus
    fonts-firacode fonts-roboto fonts-noto-color-emoji
)

PACKAGES_BUILD=(
    cmake meson ninja-build curl pkg-config
)

PACKAGES_OPTIONAL=(
    vim btop fastfetch python3 nodejs
)

# Calcula total de pacotes
calculate_total_packages() {
    TOTAL_PACKAGES=0
    TOTAL_PACKAGES=$((TOTAL_PACKAGES + ${#PACKAGES_CORE[@]}))
    TOTAL_PACKAGES=$((TOTAL_PACKAGES + ${#PACKAGES_UI[@]}))
    TOTAL_PACKAGES=$((TOTAL_PACKAGES + ${#PACKAGES_FILE_MANAGER[@]}))
    TOTAL_PACKAGES=$((TOTAL_PACKAGES + ${#PACKAGES_AUDIO[@]}))
    TOTAL_PACKAGES=$((TOTAL_PACKAGES + ${#PACKAGES_UTILITIES[@]}))
    TOTAL_PACKAGES=$((TOTAL_PACKAGES + ${#PACKAGES_TERMINAL[@]}))
    TOTAL_PACKAGES=$((TOTAL_PACKAGES + ${#PACKAGES_FONTS[@]}))
    TOTAL_PACKAGES=$((TOTAL_PACKAGES + ${#PACKAGES_BUILD[@]}))
}

# =============================================================================
# BANNER INICIAL
# =============================================================================

show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║  ██╗ ██╗██████╗ ██████╗  █████╗ ███████╗██╗  ██╗            ║"
    echo "║  ██║██╔╝╚════██╗██╔══██╗██╔══██╗██╔════╝██║ ██╔╝            ║"
    echo "║  █████║  █████╔╝██████╔╝███████║███████╗█████╔╝             ║"
    echo "║  ██╔═██╗ ╚═══██╗██╔══██╗██╔══██║╚════██║██╔═██╗             ║"
    echo "║  ██║  ██╗██████╔╝██║  ██║██║  ██║███████║██║  ██╗            ║"
    echo "║  ╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝            ║"
    echo "║                                                              ║"
    echo "║                  by owhska - i3wm setup                      ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${DIM}Modo:${NC} ${BOLD}$([ "$ONLY_CONFIG" = true ] && echo "Apenas Configuração" || echo "Instalação Completa")${NC}"
    echo -e "${DIM}Log:${NC} ${BOLD}$LOG_FILE${NC}"
    echo -e "${DIM}Pacotes:${NC} ${BOLD}$([ "$ONLY_CONFIG" = false ] && echo "$TOTAL_PACKAGES pacotes a instalar" || echo "Nenhum pacote")${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"
}

# =============================================================================
# INÍCIO DA EXECUÇÃO
# =============================================================================

# Check if we should export packages and exit
if [ "$EXPORT_PACKAGES" = true ]; then
    export_packages
    exit 0
fi

# Calcula total de pacotes
calculate_total_packages

# Mostra banner
show_banner

read -p "Iniciar instalação do i3? (y/n) " -n 1 -r
echo
[[ ! $REPLY =~ ^[Yy]$ ]] && exit 1

# =============================================================================
# ATUALIZAÇÃO DO SISTEMA
# =============================================================================
CURRENT_STEP=1
TOTAL_STEPS=8

if [ "$ONLY_CONFIG" = false ]; then
    echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}ETAPA $CURRENT_STEP/$TOTAL_STEPS: Atualizando sistema${NC}\n"
    
    msg "Atualizando repositórios..."
    if sudo apt-get update > /dev/null 2>&1; then
        success "Repositórios atualizados"
    else
        warning "Falha ao atualizar alguns repositórios"
    fi
    
    msg "Atualizando pacotes do sistema..."
    show_progress 50 100 "Atualizando sistema"
    if sudo apt-get upgrade -y > /dev/null 2>&1; then
        show_progress 100 100 "Sistema atualizado"
        success "Sistema atualizado com sucesso"
    else
        warning "Algumas atualizações falharam"
    fi
else
    msg "Pulando atualização do sistema (--only-config mode)"
fi

CURRENT_STEP=$((CURRENT_STEP + 1))

# =============================================================================
# INSTALAÇÃO DE PACOTES
# =============================================================================
if [ "$ONLY_CONFIG" = false ]; then
    echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}ETAPA $CURRENT_STEP/$TOTAL_STEPS: Instalando pacotes${NC}"
    echo -e "${DIM}Total: $TOTAL_PACKAGES pacotes${NC}\n"
    
    # Instala grupos de pacotes
    install_packages_with_progress "CORE" "${PACKAGES_CORE[@]}"
    install_packages_with_progress "UI" "${PACKAGES_UI[@]}"
    install_packages_with_progress "GERENCIADOR DE ARQUIVOS" "${PACKAGES_FILE_MANAGER[@]}"
    install_packages_with_progress "ÁUDIO" "${PACKAGES_AUDIO[@]}"
    install_packages_with_progress "UTILITÁRIOS" "${PACKAGES_UTILITIES[@]}"
    install_packages_with_progress "TERMINAL" "${PACKAGES_TERMINAL[@]}"
    install_packages_with_progress "FONTES" "${PACKAGES_FONTS[@]}"
    install_packages_with_progress "DESENVOLVIMENTO" "${PACKAGES_BUILD[@]}"
    
    # Instala Firefox (especial)
    echo -e "\n${CYAN}▸ Instalando navegador...${NC}"
    if sudo apt-get install -y firefox-esr 2>/dev/null || sudo apt-get install -y firefox 2>/dev/null; then
        success "Firefox instalado"
    else
        warning "Firefox não disponível, pulando..."
    fi
    
    # Instala exa/eza
    echo -e "\n${CYAN}▸ Instalando ferramentas de terminal...${NC}"
    if sudo apt-get install -y exa 2>/dev/null || sudo apt-get install -y eza 2>/dev/null; then
        success "exa/eza instalado"
    else
        warning "exa/eza não disponível, pulando..."
    fi
    
    # Habilita serviços
    msg "Habilitando serviços..."
    sudo systemctl enable avahi-daemon acpid 2>/dev/null && success "Serviços habilitados"
    
    echo -e "\n${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ Todos os pacotes foram instalados!${NC}"
    echo -e "${GREEN}  Total: $PACKAGES_INSTALLED/$TOTAL_PACKAGES pacotes instalados${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}\n"
else
    msg "Pulando instalação de pacotes (--only-config mode)"
fi

CURRENT_STEP=$((CURRENT_STEP + 1))

# =============================================================================
# BACKUP DE CONFIGURAÇÃO EXISTENTE
# =============================================================================
echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}ETAPA $CURRENT_STEP/$TOTAL_STEPS: Configuração do i3${NC}\n"

if [ -d "$CONFIG_DIR" ]; then
    echo -e "${YELLOW}⚠ Configuração do i3 já existe em: $CONFIG_DIR${NC}"
    echo -e "${CYAN}Opções:${NC}"
    echo "  1) Fazer backup e continuar"
    echo "  2) Sobrescrever sem backup"
    echo "  3) Cancelar instalação"
    
    read -p "Escolha (1-3): " -n 1 -r
    echo
    
    case $REPLY in
        1)
            BACKUP_DIR="$CONFIG_DIR.bak.$(date +%s)"
            mv "$CONFIG_DIR" "$BACKUP_DIR"
            success "Backup criado em: $BACKUP_DIR"
            ;;
        2)
            rm -rf "$CONFIG_DIR"
            warning "Configuração anterior removida sem backup"
            ;;
        3)
            die "Instalação cancelada pelo usuário"
            ;;
        *)
            die "Opção inválida"
            ;;
    esac
fi

CURRENT_STEP=$((CURRENT_STEP + 1))

# =============================================================================
# CÓPIA DE CONFIGURAÇÕES
# =============================================================================
echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}ETAPA $CURRENT_STEP/$TOTAL_STEPS: Configurando ambiente${NC}\n"

msg "Criando diretório de configuração..."
mkdir -p "$CONFIG_DIR"
show_progress 20 100 "Preparando estrutura"

msg "Copiando arquivos de configuração..."
if cp -r "$SCRIPT_DIR"/i3/* "$CONFIG_DIR"/ 2>/dev/null; then
    show_progress 60 100 "Copiando configurações"
    success "Configurações do i3 copiadas"
else
    die "Falha ao copiar configurações do i3"
fi

msg "Configurando scripts..."
find "$CONFIG_DIR"/scripts -type f -exec chmod +x {} \; 2>/dev/null || true
show_progress 80 100 "Configurando scripts"

msg "Criando diretórios do usuário..."
xdg-user-dirs-update
mkdir -p ~/Screenshots ~/Downloads ~/Documents
show_progress 100 100 "Diretórios criados"

success "Ambiente configurado com sucesso"
CURRENT_STEP=$((CURRENT_STEP + 1))

# =============================================================================
# COMPONENTES ADICIONAIS
# =============================================================================
if [ "$ONLY_CONFIG" = false ]; then
    echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}ETAPA $CURRENT_STEP/$TOTAL_STEPS: Componentes adicionais${NC}\n"
    
    mkdir -p "$TEMP_DIR" && cd "$TEMP_DIR"
    
    # Picom
    msg "Instalando compositor (picom)..."
    if sudo apt install -y picom > /dev/null 2>&1; then
        success "Picom instalado"
    else
        warning "Falha ao instalar picom"
    fi
    
    # Kitty
    msg "Configurando terminal Kitty..."
    if ! command -v kitty &> /dev/null; then
        sudo apt install -y kitty > /dev/null 2>&1 && success "Kitty instalado"
    else
        info "Kitty já instalado"
    fi
    
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
    success "Kitty configurado"
    
    # Neovim
    msg "Configurando Neovim..."
    if [ ! -d "$HOME/.config/nvim" ]; then
        git clone -q https://github.com/owhska/nvim "$HOME/.config/nvim" 2>/dev/null && success "Neovim configurado"
    else
        info "Neovim já configurado"
    fi
    
    # Emacs
    msg "Configurando Emacs..."
    if [ -f "$SCRIPT_DIR/emacs/.emacs" ]; then
        cp "$SCRIPT_DIR/emacs/.emacs" "$HOME/.emacs" && success "Emacs configurado"
    else
        warning "Configuração do Emacs não encontrada"
    fi
    
    # Temas e ícones
    msg "Instalando temas..."
    if sudo apt install -y arc-theme papirus-icon-theme > /dev/null 2>&1; then
        success "Temas instalados"
    fi
    
    # Wallpapers
    msg "Configurando wallpapers..."
    mkdir -p "$CONFIG_DIR/wallpapers"
    if [ -d "$SCRIPT_DIR/wallpapers" ]; then
        cp -r "$SCRIPT_DIR/wallpapers"/* "$CONFIG_DIR/wallpapers/" 2>/dev/null || true
        success "Wallpapers configurados"
    fi
    
    # Gerenciador de login
    msg "Configurando gerenciador de login (sddm)..."
    if sudo apt install -y --no-install-recommends sddm sddm-themes > /dev/null 2>&1; then
        sudo systemctl enable sddm 2>/dev/null && success "SDDM configurado"
    fi
    
    success "Componentes adicionais instalados"
fi

CURRENT_STEP=$((CURRENT_STEP + 1))

# =============================================================================
# FERRAMENTAS OPCIONAIS
# =============================================================================
if [ "$ONLY_CONFIG" = false ]; then
    clear
    echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}FERRAMENTAS OPCIONAIS${NC}\n"
    
    show_package_group "FERRAMENTAS OPCIONAIS" "${PACKAGES_OPTIONAL[@]}"
    
    read -p "Instalar ferramentas opcionais? (y/n) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "\n${CYAN}Instalando ferramentas opcionais...${NC}"
        
        for package in "${PACKAGES_OPTIONAL[@]}"; do
            printf "${DIM}▸ %-25s${NC}" "$package"
            if sudo apt install -y "$package" > /dev/null 2>&1; then
                printf "${GREEN} ✓ instalado${NC}\n"
            else
                printf "${YELLOW} ✗ não disponível${NC}\n"
            fi
        done
        
        success "Ferramentas opcionais instaladas"
    fi
fi

CURRENT_STEP=$((CURRENT_STEP + 1))

# =============================================================================
# ZSH E OH-MY-ZSH
# =============================================================================
if [ "$ONLY_CONFIG" = false ]; then
    clear
    echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}ETAPA $CURRENT_STEP/$TOTAL_STEPS: Shell ZSH${NC}\n"
    
    read -p "Instalar e configurar ZSH + Oh My Zsh como padrão? (y/n) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "\n${CYAN}Configurando ZSH...${NC}"
        
        # Instalação básica
        msg "Instalando ZSH..."
        if sudo apt install -y zsh curl git > /dev/null 2>&1; then
            success "ZSH instalado"
        else
            warning "Falha ao instalar ZSH"
        fi
        
        # Oh My Zsh
        msg "Instalando Oh My Zsh..."
        if [ ! -d "$HOME/.oh-my-zsh" ]; then
            RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended > /dev/null 2>&1
            success "Oh My Zsh instalado"
        else
            info "Oh My Zsh já instalado"
        fi
        
        # Plugins
        msg "Instalando plugins..."
        ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
        
        plugins=(
            "zsh-autosuggestions"
            "zsh-syntax-highlighting"
            "zsh-completions"
            "k"
            "zsh-z"
        )
        
        for plugin in "${plugins[@]}"; do
            case $plugin in
                "zsh-autosuggestions")
                    url="https://github.com/zsh-users/zsh-autosuggestions"
                    ;;
                "zsh-syntax-highlighting")
                    url="https://github.com/zsh-users/zsh-syntax-highlighting"
                    ;;
                "zsh-completions")
                    url="https://github.com/zsh-users/zsh-completions"
                    ;;
                "k")
                    url="https://github.com/supercrabtree/k"
                    ;;
                "zsh-z")
                    url="https://github.com/agkozak/zsh-z"
                    ;;
            esac
            
            if [ ! -d "${ZSH_CUSTOM}/plugins/${plugin}" ]; then
                git clone -q "$url" "${ZSH_CUSTOM}/plugins/${plugin}" 2>/dev/null && \
                printf "${DIM}  ▸ %-25s${GREEN} ✓${NC}\n" "$plugin"
            else
                printf "${DIM}  ▸ %-25s${CYAN} já instalado${NC}\n" "$plugin"
            fi
        done
        
        # Configuração do ZSH
        msg "Configurando .zshrc..."
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

# Aliases úteis
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first'
alias cls='clear'
alias ..='cd ..'
alias ...='cd ../..'

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOF
        success ".zshrc configurado"
        
        # Shell padrão
        msg "Definindo ZSH como shell padrão..."
        sudo chsh -s "$(which zsh)" "$USER" > /dev/null 2>&1
        
        echo -e "\n${GREEN}══════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}✓ ZSH configurado com sucesso!${NC}"
        echo -e "${CYAN}Na próxima sessão o ZSH será ativado automaticamente.${NC}"
        echo -e "${CYAN}Para ativar agora: ${BOLD}exec zsh${NC}"
        echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}\n"
    fi
fi

CURRENT_STEP=$((CURRENT_STEP + 1))

# =============================================================================
# CONCLUSÃO
# =============================================================================
echo -e "\n${GREEN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🎉 INSTALAÇÃO CONCLUÍDA COM SUCESSO!${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${BOLD}📋 RESUMO DA INSTALAÇÃO:${NC}"
echo -e "${DIM}────────────────────────────────────────────────────────────${NC}"
echo -e "${CYAN}• Configuração:${NC} ${GREEN}$CONFIG_DIR${NC}"
echo -e "${CYAN}• Pacotes:${NC} ${GREEN}$PACKAGES_INSTALLED/$TOTAL_PACKAGES instalados${NC}"
echo -e "${CYAN}• Log completo:${NC} ${GREEN}$LOG_FILE${NC}"
echo -e "${DIM}────────────────────────────────────────────────────────────${NC}\n"

echo -e "${BOLD}🚀 PRÓXIMOS PASSOS:${NC}"
echo "  1. Faça logout do sistema"
echo "  2. Selecione 'i3' no gerenciador de login"
echo "  3. Pressione ${BOLD}Super+z${NC} para ver os atalhos de teclado"
echo "  4. Configure seu wallpaper em ${DIM}~/.config/i3/wallpapers/${NC}"
echo "  5. Personalize as configurações em ${DIM}~/.config/i3/${NC}"

echo -e "\n${CYAN}🔧 COMANDOS ÚTEIS:${NC}"
echo -e "${DIM}  • Recarregar i3:${NC} ${BOLD}Super+Shift+R${NC}"
echo -e "${DIM}  • Terminal:${NC} ${BOLD}Super+Enter${NC}"
echo -e "${DIM}  • Menu de aplicativos:${NC} ${BOLD}Super+D${NC}"

echo -e "\n${GREEN}✅ Seu ambiente i3wm está pronto para uso!${NC}\n"
