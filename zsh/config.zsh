#################################  SETOPT  #################################
# share .zshhistory
setopt inc_append_history
setopt share_history

# automatically change directory when dir name is typed
setopt auto_cd

#################################  EXPORT  #################################
# Android
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:/usr/local/go/bin

# Rust
export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"

#Go
export GOPATH=$HOME/.go

#################################  HISTORY  #################################
# history
HISTFILE=$HOME/.zsh-history
HISTSIZE=100000
SAVEHIST=1000000
