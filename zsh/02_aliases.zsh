# for atcoder
if builtin command -v oj > /dev/null && builtin command -v acc >/dev/null;then
  alias act="oj t -c 'pypy3 main.py'"
  alias acs="acc s main.py -- --guess-python-interpreter pypy"
fi

if builtin command -v xdg-open > /dev/null; then
  alias open='xdg-open'
fi

alias loadzshrc='source $HOME/.zshrc'

# cd -> auto ls
cd (){
  __zoxide_z "$@" && lsd -l
}

vim (){
  if [ $# != 0 ]; then
    nvim $@
  else 
    nvim `fd -t f | fzf --preview "bat  --color=always --style=header,grid --line-range :100 {}"`
  fi
}

cat (){
  if [ $# != 0 ]; then
    bat $@
  else 
    bat `fd -t f | fzf --preview "bat  --color=always --style=header,grid --line-range :100 {}"`
  fi
}

fadd() {
  local out q n addfiles
  while out=$(
      git status --short |
      awk '{if (substr($0,2,1) !~ / /) print $2}' |
      fzf --multi --exit-0 --expect=ctrl-d); do
    q=$(head -1 <<< "$out")
    n=$[$(wc -l <<< "$out") - 1]
    addfiles=(`echo $(tail "-$n" <<< "$out")`)
    [[ -z "$addfiles" ]] && continue
    if [ "$q" = ctrl-d ]; then
      git diff --color=always $addfiles | less -R
    else
      git add $addfiles
    fi
  done
}
alias fa="fadd"

fswitch() {
  if [ $# != 0 ]; then
    git switch $@
  else 
    git switch `git for-each-ref refs/heads/ --format='%(refname:short)' | fzf --preview "git log --graph --color --pretty=format:'%>|(20,trunc)%C(red)%h%C(reset) (%><(13,trunc)%C(blue)%cr%C(reset))  %<(50,trunc)%C(yellow)%s%C(reset)  %C(cyan)<%an>%C(reset)' --abbrev-commit {}"`
  fi

}
alias fs="fswitch"
