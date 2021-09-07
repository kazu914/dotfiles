# for atcoder
if builtin command -v oj > /dev/null && builtin command -v acc >/dev/null;then
  alias act="oj t -c 'pypy3 main.py'"
  alias acs="acc s main.py -- --guess-python-interpreter pypy"
fi

if builtin command -v xdg-open > /dev/null; then
  alias open='xdg-open'
fi

alias loadzshrc='source $HOME/.zshrc'
alias vim="nvim"
alias rg="rg --smart-case"
alias cat="bat"

# cd -> auto ls
cd (){
  __zoxide_z "$@" && lsd -l
}
