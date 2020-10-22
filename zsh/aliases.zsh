# for atcoder
alias act="oj t -c 'pypy3 main.py'"
alias acs="acc s main.py -- --guess-python-interpreter pypy"

alias open='xdg-open'

if builtin command -v exa > /dev/null; then
  alias ll="exa -l --icons"
  alias la="exa -aal --icons"
  alias ls="exa --icons"
fi

if builtin command -v bat > /dev/null; then
  alias cat="bat"
fi


# cd -> auto ls
cd (){
    builtin cd "$@" && ls
}
