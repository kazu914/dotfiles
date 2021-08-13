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
  local selected empty
  local -a candidate
  empty="(Empty)"

  if [ $# = 0 ];then
    candidate=`fd -t f`
    candidate=($empty"\n"${candidate[@]})
    selected=$(echo $candidate | fzf --preview "if [ {} = '$empty' ]; then echo 'Open Here'; else bat  --color=always --style=header,grid --line-range :100 {}; fi")
  else
    if [ -f $1 ]; then
      selected=$1
    else
      candidate=`fd -t f`
      candidate=($1"\n"${candidate[@]})
      selected=$(echo $candidate | fzf --query "$1" --preview "if [ {} = '$1' ]; then echo 'Create new file: $1'; else bat  --color=always --style=header,grid --line-range :100 {}; fi")
    fi
  fi

  if [ -n "$selected" ];then
    if [ "$selected" = "$empty" ];then
      nvim ./
    else
      nvim $selected
    fi
  else
    echo "No file is selected"
  fi
}

cat (){
  local selected
  if [ $# = 0 ];then
    selected=$(fd -t f | fzf --preview "bat  --color=always --style=header,grid --line-range :100 {}")
  else
    if [ -f $1 ]; then
      selected=$1
    else
      selected=$(fd -t f | fzf --query "$1" --preview "bat  --color=always --style=header,grid --line-range :100 {}")
    fi
  fi

  if [ -n "$selected" ];then
    bat $selected
  else
    echo "No file is selected"
  fi
}

fadd() {
  local out q n addfiles
  while out=$(
      git status --short |
      awk '{if (substr($0,2,1) !~ / /) print $2}' |
      fzf --multi --exit-0 --expect=ctrl-d --preview "git diff --color {}"); do
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
