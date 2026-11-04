# Plugins
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Completado
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Historial
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY

# Autosuggestions: aceptar sugerencia completa con End o Ctrl+E
bindkey '^[^M' autosuggest-accept   # Alt+Enter acepta sugerencia completa
bindkey '^E'   autosuggest-accept   # Ctrl+E acepta sugerencia completa

# Flecha derecha: mover cursor (acepta un carácter de sugerencia si está al final)
bindkey '^[[C' forward-char

# Navegación por palabras con Ctrl+Flechas
bindkey '^[[1;5C' forward-word    # Ctrl+→
bindkey '^[[1;5D' backward-word   # Ctrl+←

# Aliases
alias ls='ls --color=auto'
alias grep='grep --color=auto'

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

export PATH="$HOME/.local/bin:$PATH"

# Prompt simple (puedes cambiar esto)
autoload -Uz promptinit && promptinit
PROMPT='%F{magenta}%n@%m%f %F{cyan}%~%f %# '
