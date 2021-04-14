#################################  EXPORT  #################################
# Android
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:/usr/local/go/bin

# Rust
if [ -x "$(command -v rustc)" ]; then
  export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"
fi

#Go
export GOPATH=$HOME/.go

# nodebew
export PATH=$HOME/.nodebrew/current/bin:$PATH
#################################  HISTORY  #################################
# history
HISTFILE=$HOME/.zsh-history
HISTSIZE=100000
SAVEHIST=1000000
# share .zshhistory
setopt inc_append_history
setopt share_history

#################################  COMPLEMENT  #################################
# enable completion
autoload -Uz compinit && compinit

# 補完候補をそのまま探す -> 小文字を大文字に変えて探す -> 大文字を小文字に変えて探す
zstyle ':completion:*' matcher-list '' 'm:{[:lower:]}={[:upper:]}' '+m:{[:upper:]}={[:lower:]}'

### 補完方法毎にグループ化する。
zstyle ':completion:*' format '%B%F{blue}%d%f%b'
zstyle ':completion:*' group-name ''


### 補完侯補をメニューから選択する。
### select=2: 補完候補を一覧から選択する。補完候補が2つ以上なければすぐに補完する。
zstyle ':completion:*:default' menu select=2
#################################  OTHERS  #################################
# automatically change directory when dir name is typed
setopt auto_cd

# disable ctrl+s, ctrl+q
setopt no_flow_control

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line

export EDITOR=nvim
export VISUAL=nvim

set -o vi
bindkey "jj" vi-cmd-mode
function zle-line-init zle-keymap-select {
    VIM_NORMAL="%K{208}%F{black}%k%f%K{208}%F{white} % NORMAL %k%f%K{black}%F{208}%k%f"
    VIM_INSERT="%K{075}%F{black}%k%f%K{075}%F{white} % INSERT %k%f%K{black}%F{075}%k%f"
    RPS1="${${KEYMAP/vicmd/$VIM_NORMAL}/(main|viins)/$VIM_INSERT}"
    RPS2=$RPS1
    zle reset-prompt
}
zle -N zle-line-init
zle -N zle-keymap-select
