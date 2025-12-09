#!/bin/bash

set -e

# Command line options
ONLY_CONFIG=false
EXPORT_PACKAGES=false
QUIET_MODE=false
DRY_RUN=false

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
        --quiet)
            QUIET_MODE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "  --only-config      Only copy config files (skip packages and external tools)"
            echo "  --export-packages  Export package lists for different distros and exit"
            echo "  --quiet            Minimal output, no interactive prompts"
            echo "  --dry-run          Show what would be done without making changes"
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
LOG_FILE="$HOME/.i3-install-$(date +%Y%m%d_%H%M%S).log"

# Logging and cleanup
exec > >(tee -a "$LOG_FILE") 2>&1
trap "cleanup_exit" EXIT INT TERM

# Colors and Styles
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'

# Symbols
CHECKMARK="✓"
CROSSMARK="✗"
WARNING="⚠"
INFO="ℹ"
ARROW="➜"
DOT="•"
STAR="✦"
GEAR="⚙"
PACKAGE="📦"
FOLDER="📁"
TERMINAL="💻"
PALETTE="🎨"
ROCKET="🚀"
PARTY="🎉"

# Variáveis para progresso
TOTAL_STEPS=0
CURRENT_STEP=0
PACKAGES_INSTALLED=0
TOTAL_PACKAGES=0
START_TIME=0
INSTALL_DURATION=0

# =============================================================================
# FUNÇÕES DE UTILIDADE
# =============================================================================

# Função de limpeza
cleanup_exit() {
    local exit_code=$?
    echo -e "\n${DIM}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${DIM}Limpeza de arquivos temporários...${NC}"
    
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
        echo -e "${DIM}${CHECKMARK} Diretório temporário removido${NC}"
    fi
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${DIM}${CHECKMARK} Limpeza concluída${NC}"
    else
        echo -e "${DIM}${CROSSMARK} Script interrompido com código $exit_code${NC}"
    fi
    
    if [ $INSTALL_DURATION -gt 0 ]; then
        echo -e "${DIM}Tempo total: $((INSTALL_DURATION / 60))m $((INSTALL_DURATION % 60))s${NC}"
    fi
    
    return $exit_code
}

# Função para calcular tempo
start_timer() {
    START_TIME=$(date +%s)
}

stop_timer() {
    local end_time=$(date +%s)
    INSTALL_DURATION=$((end_time - START_TIME))
}

# Função para exportar pacotes
export_packages() {
    echo -e "${CYAN}${BOLD}Exportando listas de pacotes organizadas:${NC}\n"
    
    local groups=(
        "CORE" "UI" "FILE_MANAGER" "AUDIO" 
        "UTILITIES" "TERMINAL" "FONTS" "BUILD" "OPTIONAL"
    )
    
    for group in "${groups[@]}"; do
        local var_name="PACKAGES_${group}[@]"
        local packages=("${!var_name}")
        local count=${#packages[@]}
        
        echo -e "${MAGENTA}${BOLD}${group}${NC} ${DIM}($count pacotes)${NC}"
        echo -e "${DIM}└─ ${packages[*]}${NC}\n"
    done
    
    exit 0
}

# Funções de log com estilo refinado
die() { 
    echo -e "\n${RED}${BOLD}${CROSSMARK} ERRO CRÍTICO${NC}" >&2
    echo -e "${RED}${ITALIC}$*${NC}\n" >&2
    exit 1
}

msg() { 
    if [ "$QUIET_MODE" = false ]; then
        echo -e "${CYAN}${ARROW} ${ITALIC}$*${NC}"
    fi
}

success() { 
    echo -e "${GREEN}${CHECKMARK} ${BOLD}$*${NC}"
}

warning() { 
    echo -e "${YELLOW}${WARNING} ${ITALIC}$*${NC}"
}

info() { 
    echo -e "${BLUE}${INFO} ${ITALIC}$*${NC}"
}

step() {
    echo -e "\n${WHITE}${BOLD}${DOT} $*${NC}"
}

# Função para mostrar banner de grupo de pacotes (refinado)
show_package_group() {
    local group_name=$1
    local group_icon=$2
    local packages=("${@:3}")
    local count=${#packages[@]}
    
    echo -e "${MAGENTA}╭─ ${group_icon} ${BOLD}${group_name}${NC} ${DIM}(${count} pacotes)${NC}"
    
    # Organiza em colunas para melhor visualização
    local cols=3
    local rows=$(( (count + cols - 1) / cols ))
    
    for ((row=0; row<rows; row++)); do
        local line="${MAGENTA}│${NC} "
        for ((col=0; col<cols; col++)); do
            local index=$((row + col * rows))
            if [ $index -lt $count ]; then
                line+="${DIM}${packages[index]}${NC}"
                if [ $col -lt $((cols - 1)) ]; then
                    line+=", "
                fi
            fi
        done
        echo -e "$line"
    done
    
    echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────${NC}"
}

# Função para mostrar progresso suave
show_progress() {
    local current=$1
    local total=$2
    local message=$3
    local width=40
    
    if [ "$QUIET_MODE" = true ]; then
        return
    fi
    
    local percentage=$((current * 100 / total))
    local filled=$((percentage * width / 100))
    local empty=$((width - filled))
    
    # Cores do gradiente
    local gradient_colors=("${GREEN}" "${CYAN}" "${BLUE}" "${MAGENTA}")
    local color_index=$((percentage * ${#gradient_colors[@]} / 100))
    [ $color_index -ge ${#gradient_colors[@]} ] && color_index=$((${#gradient_colors[@]} - 1))
    local color=${gradient_colors[$color_index]}
    
    # Barra de progresso com caracteres Unicode
    local bar=""
    for ((i=0; i<filled; i++)); do
        if [ $i -eq $((filled - 1)) ] && [ $filled -lt $width ]; then
            bar+="▶"
        else
            bar+="█"
        fi
    done
    
    for ((i=0; i<empty; i++)); do
        bar+="░"
    done
    
    printf "\r${color}${bar}${NC} ${DIM}%3d%%${NC} ${ITALIC}%s${NC}" "$percentage" "$message"
    
    if [ $current -eq $total ]; then
        printf "\n"
    fi
}

# Função para instalar pacotes com progresso refinado
install_packages_with_progress() {
    local group_name=$1
    local group_icon=$2
    local packages=("${@:3}")
    local count=${#packages[@]}
    
    if [ $count -eq 0 ]; then
        return 0
    fi
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${CYAN}[DRY RUN]${NC} Instalaria ${count} pacotes do grupo ${BOLD}${group_name}${NC}"
        echo -e "  ${DIM}${packages[*]}${NC}\n"
        PACKAGES_INSTALLED=$((PACKAGES_INSTALLED + count))
        return 0
    fi
    
    echo -e "\n${CYAN}${BOLD}${group_icon} ${group_name}${NC}"
    show_package_group "$group_name" "$group_icon" "${packages[@]}"
    
    # Instala em lotes menores para melhor feedback
    local batch_size=5
    local installed_in_group=0
    
    for ((i=0; i<count; i+=batch_size)); do
        local end=$((i+batch_size-1))
        [ $end -ge $count ] && end=$((count-1))
        
        local batch=("${packages[@]:i:batch_size}")
        
        if sudo apt-get install -y "${batch[@]}" > /dev/null 2>&1; then
            installed_in_group=$((installed_in_group + batch_size))
            PACKAGES_INSTALLED=$((PACKAGES_INSTALLED + batch_size))
            
            # Progresso dentro do grupo
            local group_percentage=$((installed_in_group * 100 / count))
            show_progress $PACKAGES_INSTALLED $TOTAL_PACKAGES \
                "$group_name ($installed_in_group/$count)"
        else
            warning "Falha no lote de pacotes: ${batch[*]}"
        fi
    done
    
    echo -e "${GREEN}${CHECKMARK} ${group_name} concluído${NC}"
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
# BANNER INICIAL REFINADO
# =============================================================================

show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════════╗
    ║                                                                  ║
    ║        ██████╗ ██╗   ██╗███╗   ██╗███████╗██████╗               ║
    ║       ██╔════╝ ██║   ██║████╗  ██║██╔════╝██╔══██╗              ║
    ║       ██║  ███╗██║   ██║██╔██╗ ██║███████╗██████╔╝              ║
    ║       ██║   ██║██║   ██║██║╚██╗██║╚════██║██╔══██╗              ║
    ║       ╚██████╔╝╚██████╔╝██║ ╚████║███████║██████╔╝              ║
    ║        ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═════╝               ║
    ║                                                                  ║
    ║                    ✦ i3wm Environment Builder ✦                 ║
    ║                                                                  ║
    ╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo -e "${DIM}${ITALIC}    Configuração elegante e minimalista para o i3 Window Manager${NC}\n"
    
    # Informações do sistema
    local distro=""
    if [ -f /etc/os-release ]; then
        distro=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
    fi
    
    echo -e "${WHITE}${BOLD}┌───────────── SISTEMA ────────────────────────────────────┐${NC}"
    echo -e "${WHITE}${BOLD}│${NC} ${DISTRO}${DIM}:${NC} ${BOLD}${distro:-Não detectado}${NC}"
    echo -e "${WHITE}${BOLD}│${NC} ${USER}${DIM}:${NC} ${BOLD}$USER${NC}"
    echo -e "${WHITE}${BOLD}│${NC} ${PACKAGE}${DIM}:${NC} ${BOLD}$([ "$ONLY_CONFIG" = false ] && echo "$TOTAL_PACKAGES pacotes" || echo "Apenas configuração")${NC}"
    echo -e "${WHITE}${BOLD}│${NC} ${FOLDER}${DIM}:${NC} ${BOLD}$CONFIG_DIR${NC}"
    echo -e "${WHITE}${BOLD}│${NC} ${TERMINAL}${DIM}:${NC} ${BOLD}$LOG_FILE${NC}"
    echo -e "${WHITE}${BOLD}└──────────────────────────────────────────────────────────┘${NC}\n"
}

# =============================================================================
# ANIMAÇÃO DE INÍCIO
# =============================================================================

show_startup_animation() {
    if [ "$QUIET_MODE" = false ]; then
        echo -e "${CYAN}Inicializando ambiente i3...${NC}"
        
        local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
        for i in {1..10}; do
            local frame_idx=$((i % ${#frames[@]}))
            printf "\r${CYAN}%s Preparando ambiente...${NC}" "${frames[$frame_idx]}"
            sleep 0.1
        done
        printf "\n\n"
    fi
}

# =============================================================================
# INÍCIO DA EXECUÇÃO
# =============================================================================

start_timer

# Check if we should export packages and exit
if [ "$EXPORT_PACKAGES" = true ]; then
    export_packages
    exit 0
fi

# Calcula total de pacotes
calculate_total_packages

# Mostra banner e animação
show_banner
show_startup_animation

if [ "$QUIET_MODE" = false ] && [ "$DRY_RUN" = false ]; then
    echo -e "${YELLOW}${BOLD}Este script configurará seu ambiente i3.${NC}"
    echo -e "${YELLOW}${ITALIC}Certifique-se de ter permissões sudo disponíveis.${NC}\n"
    
    read -p "${CYAN}${BOLD}Continuar com a instalação? (y/N): ${NC}" -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
fi

# =============================================================================
# ATUALIZAÇÃO DO SISTEMA
# =============================================================================
CURRENT_STEP=1
TOTAL_STEPS=8

if [ "$ONLY_CONFIG" = false ] && [ "$DRY_RUN" = false ]; then
    echo -e "\n${WHITE}${BOLD}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}${BOLD}${GEAR} ETAPA ${CURRENT_STEP}/${TOTAL_STEPS}: Atualização do Sistema${NC}\n"
    
    step "Sincronizando repositórios de pacotes..."
    if sudo apt-get update > /dev/null 2>&1; then
        success "Repositórios atualizados"
    else
        warning "Alguns repositórios não puderam ser atualizados"
    fi
    
    step "Otimizando pacotes do sistema..."
    show_progress 30 100 "Verificando atualizações"
    
    if sudo apt-get upgrade -y > /dev/null 2>&1; then
        show_progress 70 100 "Aplicando atualizações"
        sudo apt-get autoremove -y > /dev/null 2>&1
        show_progress 100 100 "Limpeza concluída"
        success "Sistema otimizado e atualizado"
    else
        warning "Algumas atualizações não foram aplicadas"
    fi
else
    msg "Modo de configuração somente - pulando atualizações do sistema"
fi

CURRENT_STEP=$((CURRENT_STEP + 1))

# =============================================================================
# INSTALAÇÃO DE PACOTES
# =============================================================================
if [ "$ONLY_CONFIG" = false ] && [ "$DRY_RUN" = false ]; then
    echo -e "\n${WHITE}${BOLD}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}${BOLD}${PACKAGE} ETAPA ${CURRENT_STEP}/${TOTAL_STEPS}: Instalação de Pacotes${NC}"
    echo -e "${DIM}Total de pacotes a instalar: ${BOLD}${TOTAL_PACKAGES}${NC}\n"
    
    # Instala grupos de pacotes
    install_packages_with_progress "CORE" "${ROCKET}" "${PACKAGES_CORE[@]}"
    install_packages_with_progress "INTERFACE" "${PALETTE}" "${PACKAGES_UI[@]}"
    install_packages_with_progress "GERENCIADOR DE ARQUIVOS" "${FOLDER}" "${PACKAGES_FILE_MANAGER[@]}"
    install_packages_with_progress "ÁUDIO" "🔊" "${PACKAGES_AUDIO[@]}"
    install_packages_with_progress "UTILITÁRIOS" "${GEAR}" "${PACKAGES_UTILITIES[@]}"
    install_packages_with_progress "TERMINAL" "${TERMINAL}" "${PACKAGES_TERMINAL[@]}"
    install_packages_with_progress "FONTES" "🔤" "${PACKAGES_FONTS[@]}"
    install_packages_with_progress "DESENVOLVIMENTO" "${STAR}" "${PACKAGES_BUILD[@]}"
    
    # Instalações especiais com estilo
    step "Configurando navegador..."
    if sudo apt-get install -y firefox-esr 2>/dev/null || sudo apt-get install -y firefox 2>/dev/null; then
        success "Firefox configurado"
    else
        warning "Firefox não disponível"
    fi
    
    step "Otimizando terminal..."
    if sudo apt-get install -y eza 2>/dev/null || sudo apt-get install -y exa 2>/dev/null; then
        success "eza/exa instalado"
    else
        info "Usando ls padrão"
    fi
    
    step "Habilitando serviços essenciais..."
    sudo systemctl enable avahi-daemon acpid 2>/dev/null && success "Serviços habilitados"
    
    echo -e "\n${GREEN}${BOLD}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}🎯 INSTALAÇÃO DE PACOTES CONCLUÍDA!${NC}"
    echo -e "${GREEN}${ITALIC}  ${PACKAGES_INSTALLED} de ${TOTAL_PACKAGES} pacotes instalados com sucesso${NC}"
    echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════════════${NC}\n"
elif [ "$DRY_RUN" = true ]; then
    echo -e "\n${CYAN}${BOLD}[MODO SIMULAÇÃO]${NC} Mostrando pacotes que seriam instalados:\n"
    PACKAGES_INSTALLED=$TOTAL_PACKAGES
fi

CURRENT_STEP=$((CURRENT_STEP + 1))

# =============================================================================
# BACKUP DE CONFIGURAÇÃO EXISTENTE
# =============================================================================
echo -e "\n${WHITE}${BOLD}══════════════════════════════════════════════════════════════${NC}"
echo -e "${WHITE}${BOLD}${FOLDER} ETAPA ${CURRENT_STEP}/${TOTAL_STEPS}: Configuração do Ambiente${NC}\n"

if [ -d "$CONFIG_DIR" ]; then
    echo -e "${YELLOW}${WARNING} Configuração existente detectada em:${NC}"
    echo -e "  ${DIM}$CONFIG_DIR${NC}\n"
    
    if [ "$QUIET_MODE" = false ] && [ "$DRY_RUN" = false ]; then
        echo -e "${CYAN}${BOLD}Escolha uma opção:${NC}"
        echo -e "  ${GREEN}1${NC}) ${BOLD}Backup e substituir${NC} ${DIM}(recomendado)${NC}"
        echo -e "  ${YELLOW}2${NC}) ${BOLD}Substituir diretamente${NC} ${DIM}(sem backup)${NC}"
        echo -e "  ${RED}3${NC}) ${BOLD}Cancelar instalação${NC}"
        echo -e "  ${BLUE}4${NC}) ${BOLD}Mesclar configurações${NC} ${DIM}(preserva personalizações)${NC}"
        
        read -p "${CYAN}Sua escolha (1-4): ${NC}" -n 1 -r
        echo
        
        case $REPLY in
            1)
                BACKUP_DIR="$CONFIG_DIR.bak.$(date +%Y%m%d_%H%M%S)"
                mv "$CONFIG_DIR" "$BACKUP_DIR"
                success "Backup criado em: ${DIM}$BACKUP_DIR${NC}"
                ;;
            2)
                rm -rf "$CONFIG_DIR"
                warning "Configuração anterior removida sem backup"
                ;;
            3)
                die "Instalação cancelada pelo usuário"
                ;;
            4)
                info "Modo de mesclagem selecionado"
                # Continua sem remover a configuração existente
                ;;
            *)
                die "Opção inválida selecionada"
                ;;
        esac
    else
        # Modo quiet ou dry-run
        if [ "$DRY_RUN" = true ]; then
            echo -e "${CYAN}[DRY RUN]${NC} Faria backup da configuração existente"
        else
            BACKUP_DIR="$CONFIG_DIR.bak.$(date +%Y%m%d_%H%M%S)"
            mv "$CONFIG_DIR" "$BACKUP_DIR"
            success "Backup automático criado"
        fi
    fi
else
    success "Nenhuma configuração anterior encontrada"
fi

CURRENT_STEP=$((CURRENT_STEP + 1))

# =============================================================================
# CÓPIA DE CONFIGURAÇÕES
# =============================================================================
if [ "$DRY_RUN" = false ]; then
    echo -e "\n${WHITE}${BOLD}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}${BOLD}${GEAR} ETAPA ${CURRENT_STEP}/${TOTAL_STEPS}: Aplicando Configurações${NC}\n"
    
    step "Estruturando diretórios de configuração..."
    mkdir -p "$CONFIG_DIR"
    show_progress 10 100 "Criando estrutura"
    
    step "Transferindo configurações do i3..."
    if cp -r "$SCRIPT_DIR"/i3/* "$CONFIG_DIR"/ 2>/dev/null; then
        show_progress 40 100 "Copiando arquivos"
        success "Configurações principais aplicadas"
    else
        die "Falha ao copiar configurações"
    fi
    
    step "Configurando scripts e permissões..."
    find "$CONFIG_DIR"/scripts -type f -exec chmod +x {} \; 2>/dev/null || true
    show_progress 60 100 "Configurando permissões"
    
    step "Organizando diretórios pessoais..."
    xdg-user-dirs-update
    mkdir -p ~/Screenshots ~/Downloads ~/Documents ~/Workspace
    show_progress 80 100 "Organizando diretórios"
    
    step "Aplicando configurações finais..."
    show_progress 100 100 "Finalizando configuração"
    
    success "Configurações aplicadas com sucesso"
else
    echo -e "${CYAN}[DRY RUN]${NC} Copiaria configurações para: ${DIM}$CONFIG_DIR${NC}"
fi

CURRENT_STEP=$((CURRENT_STEP + 1))

# =============================================================================
# COMPONENTES ADICIONAIS - ATUALIZADO COM TODAS CONFIGURAÇÕES
# =============================================================================
if [ "$ONLY_CONFIG" = false ] && [ "$DRY_RUN" = false ]; then
    echo -e "\n${WHITE}${BOLD}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}${BOLD}${STAR} ETAPA ${CURRENT_STEP}/${TOTAL_STEPS}: Componentes Avançados${NC}\n"
    
    mkdir -p "$TEMP_DIR" && cd "$TEMP_DIR"
    
    # Lista de componentes atualizada com todas as configurações originais
    local components=(
        "Compositor (Picom):picom"
        "Terminal (Kitty):kitty"
        "Editor (Neovim):nvim"
        "Editor (Emacs):emacs"
        "Temas e Ícones:themes"
        "Wallpapers:wallpapers"
        "Gerenciador de Login:login"
    )
    
    for component in "${components[@]}"; do
        local name="${component%:*}"
        local cmd="${component#*:}"
        
        case $cmd in
            picom)
                if sudo apt install -y picom > /dev/null 2>&1; then
                    echo -e "${GREEN}${CHECKMARK} ${name}${NC}"
                else
                    echo -e "${YELLOW}${WARNING} ${name} (opcional)${NC}"
                fi
                ;;
                
            kitty)
                # Instalar Kitty se não existir
                if ! command -v kitty &> /dev/null; then
                    sudo apt install -y kitty > /dev/null 2>&1
                    echo -e "${GREEN}${CHECKMARK} ${name} (instalado)${NC}"
                else
                    echo -e "${CYAN}${INFO} ${name} (já instalado)${NC}"
                fi
                
                # Configurar Kitty (sempre criar/atualizar configuração)
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
                echo -e "  ${GREEN}${CHECKMARK} Configuração do Kitty aplicada${NC}"
                ;;
                
            nvim)
                if [ ! -d "$HOME/.config/nvim" ]; then
                    git clone -q https://github.com/owhska/nvim "$HOME/.config/nvim" 2>/dev/null && \
                    echo -e "${GREEN}${CHECKMARK} ${name}${NC}"
                else
                    echo -e "${CYAN}${INFO} ${name} (já configurado)${NC}"
                fi
                ;;
                
            emacs)
                if [ -f "$SCRIPT_DIR/emacs/.emacs" ]; then
                    cp "$SCRIPT_DIR/emacs/.emacs" "$HOME/.emacs"
                    echo -e "${GREEN}${CHECKMARK} ${name}${NC}"
                else
                    echo -e "${YELLOW}${WARNING} ${name} (arquivo não encontrado)${NC}"
                fi
                ;;
                
            themes)
                if sudo apt install -y arc-theme papirus-icon-theme > /dev/null 2>&1; then
                    echo -e "${GREEN}${CHECKMARK} ${name}${NC}"
                else
                    echo -e "${YELLOW}${WARNING} ${name}${NC}"
                fi
                ;;
                
            wallpapers)
                mkdir -p "$CONFIG_DIR/wallpapers"
                if [ -d "$SCRIPT_DIR/wallpapers" ]; then
                    cp -r "$SCRIPT_DIR/wallpapers"/* "$CONFIG_DIR/wallpapers/" 2>/dev/null || true
                    echo -e "${GREEN}${CHECKMARK} ${name}${NC}"
                else
                    echo -e "${YELLOW}${WARNING} ${name} (diretório não encontrado)${NC}"
                fi
                ;;
                
            login)
                # Instalar apenas SDDM sem KDE Plasma
                echo -e "${CYAN}Instalando SDDM (apenas display manager)...${NC}"
                
                # Primeiro verificar se já tem algum DM instalado
                if systemctl list-unit-files | grep -q "^display-manager"; then
                    echo -e "  ${YELLOW}⚠ Já existe um display manager instalado${NC}"
                fi
                
                # Instalar SDDM sem recomendações (evita KDE)
                if sudo apt install -y --no-install-recommends sddm> /dev/null 2>&1; then
                    # Desabilitar quaisquer outros DMs que possam ter sido instalados
                    sudo systemctl disable gdm3 lightdm 2>/dev/null || true
                    
                    # Habilitar SDDM
                    sudo systemctl enable sddm 2>/dev/null
                    
                    echo -e "${GREEN}${CHECKMARK} ${name} (SDDM instalado e configurado)${NC}"
                else
                    echo -e "${YELLOW}${WARNING} ${name} (falha na instalação)${NC}"
                fi
                ;;
        esac
    done
    
    success "Componentes avançados configurados"
fi

CURRENT_STEP=$((CURRENT_STEP + 1))

# =============================================================================
# FERRAMENTAS OPCIONAIS
# =============================================================================
if [ "$ONLY_CONFIG" = false ] && [ "$QUIET_MODE" = false ]; then
    clear
    echo -e "\n${WHITE}${BOLD}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}${BOLD}${STAR} FERRAMENTAS OPCIONAIS${NC}\n"
    
    echo -e "${CYAN}${ITALIC}Ferramentas adicionais para melhorar seu fluxo de trabalho:${NC}\n"
    
    show_package_group "FERRAMENTAS OPCIONAIS" "${STAR}" "${PACKAGES_OPTIONAL[@]}"
    
    if [ "$DRY_RUN" = false ]; then
        echo -e "\n${CYAN}${BOLD}Deseja instalar estas ferramentas opcionais?${NC}"
        read -p "${CYAN}(S)im, (N)ão, (E)scolher individualmente: ${NC}" -n 1 -r
        echo
        
        case $REPLY in
            [Ss]*)
                echo -e "\n${CYAN}Instalando ferramentas opcionais...${NC}"
                for package in "${PACKAGES_OPTIONAL[@]}"; do
                    echo -e "${DIM}  ▸ $package${NC}"
                    sudo apt install -y "$package" > /dev/null 2>&1 || true
                done
                success "Ferramentas opcionais instaladas"
                ;;
            [Ee]*)
                echo -e "\n${CYAN}Selecione os pacotes para instalar:${NC}"
                local i=1
                for package in "${PACKAGES_OPTIONAL[@]}"; do
                    echo -e "  ${GREEN}$i${NC}) $package"
                    i=$((i+1))
                done
                echo -e "  ${GREEN}$i${NC}) Todos"
                
                read -p "${CYAN}Digite os números (separados por espaço): ${NC}" -a choices
                
                for choice in "${choices[@]}"; do
                    if [ "$choice" -eq ${#PACKAGES_OPTIONAL[@]}+1 ]; then
                        sudo apt install -y "${PACKAGES_OPTIONAL[@]}" > /dev/null 2>&1
                        break
                    elif [ "$choice" -ge 1 ] && [ "$choice" -le ${#PACKAGES_OPTIONAL[@]} ]; then
                        local idx=$((choice-1))
                        sudo apt install -y "${PACKAGES_OPTIONAL[$idx]}" > /dev/null 2>&1 || true
                    fi
                done
                ;;
            *)
                info "Ferramentas opcionais ignoradas"
                ;;
        esac
    else
        echo -e "${CYAN}[DRY RUN]${NC} Mostrando ferramentas opcionais disponíveis"
    fi
fi

CURRENT_STEP=$((CURRENT_STEP + 1))

# =============================================================================
# ZSH E OH-MY-ZSH (OPCIONAL)
# =============================================================================
if [ "$ONLY_CONFIG" = false ] && [ "$QUIET_MODE" = false ] && [ "$DRY_RUN" = false ]; then
    clear
    echo -e "\n${WHITE}${BOLD}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}${BOLD}${TERMINAL} ETAPA ${CURRENT_STEP}/${TOTAL_STEPS}: Ambiente de Terminal${NC}\n"
    
    echo -e "${CYAN}${BOLD}Deseja configurar ZSH com Oh My Zsh?${NC}"
    echo -e "${DIM}ZSH oferece autocompletar aprimorado, temas e plugins úteis.${NC}\n"
    
    read -p "${CYAN}Configurar ZSH como shell padrão? (s/N): ${NC}" -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        echo -e "\n${CYAN}${BOLD}Configurando ambiente ZSH...${NC}"
        
        # Instalação básica
        step "Instalando ZSH e dependências..."
        sudo apt install -y zsh curl git > /dev/null 2>&1
        success "ZSH instalado"
        
        # Oh My Zsh
        step "Configurando Oh My Zsh..."
        if [ ! -d "$HOME/.oh-my-zsh" ]; then
            RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended > /dev/null 2>&1
            success "Oh My Zsh configurado"
        else
            info "Oh My Zsh já está instalado"
        fi
        
        # Plugins
        step "Instalando plugins populares..."
        
        local plugins_info=(
            "zsh-autosuggestions:sugestões enquanto digita"
            "zsh-syntax-highlighting:realce de sintaxe"
            "k:listagem de diretórios colorida"
            "zsh-z:navegação rápida entre diretórios"
        )
        
        ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
        
        for plugin_info in "${plugins_info[@]}"; do
            local plugin="${plugin_info%:*}"
            local desc="${plugin_info#*:}"
            
            case $plugin in
                "zsh-autosuggestions")
                    url="https://github.com/zsh-users/zsh-autosuggestions"
                    ;;
                "zsh-syntax-highlighting")
                    url="https://github.com/zsh-users/zsh-syntax-highlighting"
                    ;;
                "k")
                    url="https://github.com/supercrabtree/k"
                    ;;
                "zsh-z")
                    url="https://github.com/agkozak/zsh-z"
                    ;;
            esac
            
            if [ ! -d "${ZSH_CUSTOM}/plugins/${plugin}" ]; then
                git clone -q "$url" "${ZSH_CUSTOM}/plugins/${plugin}" 2>/dev/null
                echo -e "  ${GREEN}${CHECKMARK} ${plugin}${NC} ${DIM}($desc)${NC}"
            else
                echo -e "  ${CYAN}${INFO} ${plugin}${NC} ${DIM}(já instalado)${NC}"
            fi
        done
        
        # Configuração
        step "Personalizando configuração..."
        cat > "$HOME/.zshrc" << 'EOF'
# Oh My Zsh Configuration
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(
    git
    docker
    zsh-autosuggestions
    k
    zsh-z
)

source $ZSH/oh-my-zsh.sh

# Modern file listing
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first'
alias la='eza -a --icons --group-directories-first'

# Quick navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# System
alias cls='clear'
alias update='sudo apt update && sudo apt upgrade -y'
alias cleanup='sudo apt autoremove -y && sudo apt autoclean'

# Colorful grep
#alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Safety nets
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Função para reload do zsh
reload() {
    source ~/.zshrc
    echo "ZSH config reloaded!"
}
EOF
        success "Configuração personalizada aplicada"
        
        # Shell padrão
        step "Definindo ZSH como shell padrão..."
        sudo chsh -s "$(which zsh)" "$USER" > /dev/null 2>&1
        
        echo -e "\n${GREEN}${BOLD}══════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}${BOLD}✨ AMBIENTE ZSH CONFIGURADO!${NC}"
        echo -e "${GREEN}${ITALIC}Para ativar agora: ${BOLD}exec zsh${NC}"
        echo -e "${GREEN}${ITALIC}Na próxima sessão, o ZSH será iniciado automaticamente.${NC}"
        echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════════════${NC}\n"
    else
        info "Configuração do ZSH ignorada"
    fi
fi

CURRENT_STEP=$((CURRENT_STEP + 1))

# =============================================================================
# CONCLUSÃO E RESUMO
# =============================================================================
stop_timer

echo -e "\n${GREEN}${BOLD}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}${PARTY} INSTALAÇÃO CONCLUÍDA COM SUCESSO!${NC}"
echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════════════${NC}\n"

# Resumo estilizado
echo -e "${WHITE}${BOLD}📊 RESUMO DA INSTALAÇÃO${NC}"
echo -e "${DIM}────────────────────────────────────────────────────────────${NC}"

if [ "$ONLY_CONFIG" = false ]; then
    echo -e "${CYAN}${PACKAGE} Pacotes:${NC} ${GREEN}${PACKAGES_INSTALLED}/${TOTAL_PACKAGES} instalados${NC}"
fi

echo -e "${CYAN}${FOLDER} Configuração:${NC} ${GREEN}$CONFIG_DIR${NC}"
echo -e "${CYAN}${TERMINAL} Arquivo de log:${NC} ${DIM}$LOG_FILE${NC}"
echo -e "${CYAN}⏱️  Tempo total:${NC} ${GREEN}$((INSTALL_DURATION / 60))m $((INSTALL_DURATION % 60))s${NC}"

if [ "$DRY_RUN" = true ]; then
    echo -e "${CYAN}🔍 Modo:${NC} ${YELLOW}Simulação (nenhuma alteração feita)${NC}"
fi

echo -e "${DIM}────────────────────────────────────────────────────────────${NC}\n"

# Dica final
if [ "$ONLY_CONFIG" = false ]; then
    echo -e "${YELLOW}${ITALIC}💡 Dica: Execute 'neofetch' ou 'fastfetch' para ver suas informações do sistema!${NC}\n"
fi
