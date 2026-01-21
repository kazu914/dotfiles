alias loadzshrc='source $HOME/.zshrc'
alias vim="nvim"
alias rg="rg --smart-case"
alias cat="bat"
alias ls="lsd"
alias ll="lsd -la"
alias tree='lsd --tree'
alias gbs='git branch -u origin/$(git rev-parse --abbrev-ref HEAD)'

# cd -> auto ls
if [[ "$CLAUDECODE" != "1" ]]; then
  cd (){
    __zoxide_z "$@" && pwd && lsd --tree -a --depth=1
  }
fi

alias kk='kakisute interact'

if builtin command -v gsed > /dev/null; then
  alias sed='gsed'
fi
