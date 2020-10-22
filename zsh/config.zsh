# share .zshhistory
setopt inc_append_history
setopt share_history

# automatically change directory when dir name is typed
setopt auto_cd

# history
HISTFILE=$HOME/.zsh-history
HISTSIZE=100000
SAVEHIST=1000000
