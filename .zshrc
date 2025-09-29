setopt interactivecomments
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

alias ls="ls -alh --color=always"
alias up="sudo apt update && sudo apt upgrade -y"
alias in="sudo apt install"
alias un="sudo apt remove --purge"

source ~/.zsh/zsh-autocomplete/zsh-autocomplete.plugin.zsh
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':autocomplete:history-incremental-search-*' completer _history
zstyle ':autocomplete:*' accept-line yes

bindkey '^M' accept-line
bindkey -M menuselect '^M' .accept-line

eval "$(starship init zsh)"
