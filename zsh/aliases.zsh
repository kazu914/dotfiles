# for atcoder
if builtin command -v oj > /dev/null && builtin command -v acc >/dev/null;then
  alias act="oj t -c 'pypy3 main.py'"
  alias acs="acc s main.py -- --guess-python-interpreter pypy"
fi

if builtin command -v xdg-open > /dev/null; then
  alias open='xdg-open'
fi
if builtin command -v nvim > /dev/null; then
  alias vim='nvim'
fi

alias loadzshrc='source $HOME/.zshrc'

# cd -> auto ls
cd (){
    builtin cd "$@" && k
}
