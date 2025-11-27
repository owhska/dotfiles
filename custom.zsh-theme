# Define as cores
local sunny_yellow='%F{#F0C05A}' # Amarelo suave para pasta
local vibrant_orange='%F{#F28C38}' # Laranja vibrante para branch
local reset_color='%f'            # Reseta a cor

# Função para verificar se está em um repositório Git e adicionar "on" com ícone de branch
prompt_git() {
  local git_info=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [[ -n "$git_info" ]]; then
    echo " on ${vibrant_orange} ${git_info}${reset_color}"
  fi
}

# Configura o prompt com a setinha no final
PROMPT='${sunny_yellow}%c${reset_color}$(prompt_git) ➜ '

# Configurações para o git_prompt_info (mostra a branch, mantido para compatibilidade)
ZSH_THEME_GIT_PROMPT_PREFIX=""
ZSH_THEME_GIT_PROMPT_SUFFIX=""
ZSH_THEME_GIT_PROMPT_DIRTY=" ✗"
ZSH_THEME_GIT_PROMPT_CLEAN=" ✓"

# Configuração do zsh-syntax-highlighting para colorir comandos em verde aspargo
# ZSH_HIGHLIGHT_STYLES[command]='fg=#7BB75B'
# ZSH_HIGHLIGHT_STYLES[builtin]='fg=#7BB75B'
# ZSH_HIGHLIGHT_STYLES[alias]='fg=#7BB75B'
