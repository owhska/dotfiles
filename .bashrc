# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH


PS1='\[\e[36m\]\w\[\e[m\]'
# Adicionar branch do Git usando git rev-parse (fallback robusto)
git_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null | sed 's/.*/ (\0)/'
}
PS1+='\[\e[33m\]$(git_branch)\[\e[m\] \$ '

export JAVA_HOME=/usr/lib/jvm/temurin-11-jdk
export PATH=$JAVA_HOME/bin:$PATH

# Aliases para navegação e desenvolvimento
alias ll='ls -lh --color=auto'
alias la='ls -lah --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias cls='clear'
alias grep='grep --color=auto'

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc
. "$HOME/.cargo/env"
