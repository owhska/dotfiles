#!/usr/bin/env bash

# If not running interactively, don't do anything
[[ -n $PS1 ]] || return

# use vardump instead of parr
alias parr='vardump'

# -- Environment

HISTCONTROL='ignoredups'
HISTSIZE=5000
HISTFILESIZE=5000

export EDITOR='vim'
export GREP_COLOR='1;36'
export LSCOLORS='ExGxbEaECxxEhEhBaDaCaD'
export MANPAGER='less'
export PAGER='less'
export TZ='America/New_York'
export VISUAL='vim'

# Support colors in less
export LESS_TERMCAP_mb=$'\e[1;31m'
export LESS_TERMCAP_md=$'\e[1;31m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[1;33;44m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[4;1;32m'
export LESS_TERMCAP_mr=$'\e[7m'
export LESS_TERMCAP_mh=$'\e[2m'
export LESS_TERMCAP_ZN=$'\e[74m'
export LESS_TERMCAP_ZV=$'\e[75m'
export LESS_TERMCAP_ZO=$'\e[73m'
export LESS_TERMCAP_ZW=$'\e[75m'

# Shell Options
shopt -s cdspell
shopt -s checkwinsize
shopt -s extglob

# Bash Version >= 4
shopt -s autocd 2>/dev/null || true
shopt -s dirspell 2>/dev/null || true

# Aliases
alias hl='rg --passthru'
alias ..='cd ..'
alias ...='cd ../..'
alias v='nvim'
alias vi='vim'
alias t='tmux'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias c='clear'
alias q='exit'

# Aliases (if applicable)
grep --color=auto < /dev/null &>/dev/null &&
    alias grep='grep --color=auto'

command -v xdg-open &>/dev/null &&
    alias open='xdg-open'

command -v system_profiler &>/dev/null &&
    alias wattage='system_profiler SPPowerDataType | grep Wattage'

# Enable color support of ls
if ls --color=auto /dev/null &>/dev/null; then
    alias ls='ls -p --color=auto'
else
    alias ls='ls -p -G'
fi

# -- Git Aliases

alias nb='git checkout -b "$USER-$(date +%s)"'
alias ga='git add . --all'
alias gb='git branch'
alias gc='git clone'
alias gci='git commit -a'
alias gco='git checkout'
alias gd="git diff ':!\*lock'"
alias gdf='git diff'
alias gi='git init'
alias gl='git log'
alias gp='git push origin HEAD'
alias gr='git rev-parse --show-toplevel'
alias gs='git status'
alias gt='git tag'
alias gu='git pull'

# Git main branch
gmb() {
    local main

    main=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)
    main=${main#origin/}

    [[ -n $main ]] || return 1

    echo "$main"
}

# Show diff from current branch to main
gbd() {
    local mb

    mb=$(gmb) || return 1

    git diff "$mb..HEAD"
}

# Checkout main branch and update
gcm() {
    local mb

    mb=$(gmb) || return 1

    git checkout "$mb" && git pull
}

# Merge main into current branch
gmm() {
    local mb

    mb=$(gmb) || return 1

    git merge "$mb"
}

# -- Prompt logic

# Prompt colors
RED=$'\e[31m'
GREEN=$'\e[32m'
BLUE=$'\e[34m'
CYAN=$'\e[36m'
YELLOW=$'\e[33m'
RESET=$'\e[0m'
BOLD=$'\e[1m'

# Initialize prompt theme
prompt-set-theme() {
    local theme=${1:-0}
    local j=0

    for ((i = theme; i <= 255; i += 30)); do
        PROMPT_COLORS[j]=$'\e[38;5;'${i}m
        ((j++))
    done
}

# Git branch
git_branch() {
    local branch

    branch=$(git branch --show-current 2>/dev/null)

    if [[ -n "$branch" ]]; then
        printf ' %s(git:%s%s%s)%s' \
            "$BLUE" "$RED" "$branch" "$BLUE" "$RESET"
    fi
}

# Update terminal title and prompt
prompt-update() {
    local exit_code=$?
    local user=$USER
    local host=${HOSTNAME%%.*}

    # Get PWD safely
    local s='\w'
    local pwd=${s@P}

    # Update terminal title
    local ssh=
    [[ -n $SSH_CLIENT ]] && ssh='[ssh] '

    printf '\e]0;%s%s@%s:%s\a' \
        "$ssh" "$user" "$host" "$pwd"

    # Exit code
    local status_prompt=

    if ((exit_code != 0)); then
        status_prompt='\['"$RED"'\]('"$exit_code"') \['"$RESET"'\]'
    fi

    # Git branch
    local branch
    branch=$(git branch --show-current 2>/dev/null)

    # Select prompt style
    case "$PROMPT_STYLE" in

        # Original prompt
        0)
            local user_color=${PROMPT_COLORS[0]}

            ((UID == 0)) && user_color=$RED

            PS1="$status_prompt"
            PS1+='\['"$user_color"'\]\['"$BOLD"'\]\u\['"$RESET"'\] '
            PS1+='\[${PROMPT_COLORS[5]}\]\w '

            if [[ -n $branch ]]; then
                PS1+='\[${PROMPT_COLORS[2]}\]('
                PS1+='\[${PROMPT_COLORS[3]}\]git:'"$branch"
                PS1+='\[${PROMPT_COLORS[2]}\]) '
            fi

            PS1+='\[${PROMPT_COLORS[0]}\]\$\['"$RESET"'\] '
            ;;

        # Arrow prompt
        1)
            local symbol_color=$GREEN

            ((exit_code != 0)) && symbol_color=$RED

            PS1='\['"$symbol_color"'\]➜ \['"$RESET"'\]'
            PS1+='\['"$CYAN"'\]\W\['"$RESET"'\]'

            if [[ -n $branch ]]; then
                PS1+='\['"$BLUE"'\] git:(\['"$RED"'\]'
                PS1+="$branch"
                PS1+='\['"$BLUE"'\])\['"$RESET"'\]'
            fi

            PS1+=' \['"$YELLOW"'\]\$\['"$RESET"'\] '
            ;;

    esac
}

# Initialize original prompt
prompt-init() {
    PROMPT_STYLE=0
    prompt-update
}

# Initialize arrow prompt
prompt-init-arrow() {
    PROMPT_STYLE=1
    prompt-update
}

# Select prompt
# 0 = Original
# 1 = Arrow
prompt-select() {
    case "$1" in
        0|original)
            PROMPT_STYLE=0
            ;;
        1|arrow)
            PROMPT_STYLE=1
            ;;
        *)
            echo "Usage: prompt-select {0|1|original|arrow}"
            return 1
            ;;
    esac

    prompt-update
}

# Prompt configuration
PROMPT_COLORS=()
PROMPT_DIRTRIM=6

# Default theme
prompt-set-theme 24

# Default prompt
PROMPT_STYLE=0

# Update prompt before each command
PROMPT_COMMAND=prompt-update

# Initialize prompt
prompt-init

# -- Print a colorized diff

colordiff() {
    local red=$'\e[31m'
    local green=$'\e[32m'
    local cyan=$'\e[36m'
    local reset=$'\e[0m'

    diff -u "$@" | awk \
        -v "red=$red" -v "green=$green" \
        -v "cyan=$cyan" -v "reset=$reset" '
        /^-/ { printf("%s", red) }
        /^\+/ { printf("%s", green) }
        /^@/ { printf("%s", cyan) }
        { print $0 reset }
    '

    return "${PIPESTATUS[0]}"
}

# Print all 256 colors
colors() {
    local i

    for i in {0..255}; do
        printf '\e[38;5;%dmcolor %d\n' "$i" "$i"
    done

    printf '\e[0m'
}

# Copy stdin to clipboard
copy() {
    pbcopy 2>/dev/null ||
        xsel 2>/dev/null ||
        clip.exe
}

cpy() {
    cat "$1" | xclip -selection clipboard
}

# Dump terminal palette
dump-palette() {
    local fd

    exec {fd}<>/dev/tty || {
        echo "failed to open TTY"
        return 1
    }

    local re='rgb:([0-9a-f]{4})/([0-9a-f]{4})/([0-9a-f]{4})'
    local code s r g b

    for code in 4\;{0..15} 10 11 12 17 19; do
        printf '\e]%s;?\e\\' "$code" >&$fd
        read -rs -d '\' -u "$fd" s
        s=${s//$'\e'}

        if ! [[ $s =~ $re ]]; then
            echo "$code = <failed>"
            continue
        fi

        r=${BASH_REMATCH[1]}
        g=${BASH_REMATCH[2]}
        b=${BASH_REMATCH[3]}

        r=$((16#$r / 257))
        g=$((16#$g / 257))
        b=$((16#$b / 257))

        printf '%s = #%02x%02x%02x\n' "$code" "$r" "$g" "$b"
    done

    exec {fd}>&-
}

# Convert epoch to human readable
epoch() {
    local num=${1:--1}

    printf '%(%B %d, %Y %-I:%M:%S %p %Z)T\n' "$num"
}

# Open current path or file in GitHub
gho() {
    local file=$1
    local remote=${2:-origin}

    local gr branch url

    gr=$(git rev-parse --show-toplevel) || return 1
    branch=$(git rev-parse --abbrev-ref HEAD) || return 1
    url=$(git config --get "remote.$remote.url") || return 1

    [[ -n $gr && -n $branch && -n $url ]] || return 1

    local path=${PWD/#$gr/}
    [[ -n $file ]] && path+=/$file

    local a

    IFS=:/ read -r -a a <<< "$url"

    local len=${#a[@]}
    local user=${a[len-2]}
    local repo=${a[len-1]%.git}

    url="https://github.com/$user/$repo/tree/$branch$path"

    echo "$url"
    open "$url"
}

# Platform-independent interfaces
interfaces() {
    node <<'EOF'
var os = require('os');
var i = os.networkInterfaces();

Object.keys(i).forEach(function(name) {
    i[name].forEach(function(int) {
        if (int.family === 'IPv4') {
            console.log('%s: %s', name, int.address);
        }
    });
});
EOF
}

# Calculate CPU load / Core Count
load() {
    node -p <<'EOF'
var os = require('os');
var c = os.cpus().length;

os.loadavg().map(function(l) {
    return (l/c).toFixed(2);
}).join(' ');
EOF
}

# Platform-independent memory usage
meminfo() {
    node <<'EOF'
var os = require('os');
var free = os.freemem();
var total = os.totalmem();
var used = total - free;

console.log('memory: %dmb / %dmb (%d%%)',
    Math.round(used / 1024 / 1024),
    Math.round(total / 1024 / 1024),
    Math.round(used * 100 / total));
EOF
}

# Print lines over X columns
over() {
    local c=${1:-80}

    expand | awk -v "c=$c" 'length($0) > c {
        printf("%4d %s\n", NR, $0);
    }'
}

# Print rainbow if truecolor is available
truecolor-rainbow() {
    local i r g b

    for ((i = 0; i < 77; i++)); do
        r=$((255 - (i * 255 / 76)))
        g=$((i * 510 / 76))
        b=$((i * 255 / 76))

        ((g > 255)) && g=$((510 - g))

        printf '\033[48;2;%d;%d;%dm ' "$r" "$g" "$b"
    done

    printf '\e[0m\n'
}

# Follow redirects to untiny a tiny URL
untiny() {
    local url=$1

    while [[ -n $url ]]; do
        echo "-> $url"

        url=$(curl -sSI -o /dev/null -w '%header{location}' "$url") ||
            return 1
    done

    return 0
}

# Load external files
. ~/.bash_aliases 2>/dev/null
. ~/.bashrc.local 2>/dev/null

# Load completion
. ~/.bash_completion 2>/dev/null

# Return success
true
