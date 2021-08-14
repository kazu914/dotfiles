CURRENT_DIR_PATH=${0:a:h}
PARENT_DIR_PATH=${CURRENT_DIR_PATH%/*}
ROOT_DIR_PATH=${PARENT_DIR_PATH%/*}
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
    candidate=`fd --color=always -t f`
    candidate=($empty"\n"${candidate[@]})
    selected=$(echo $candidate | fzf --preview "if [ {} = '$empty' ]; then echo 'Open Here'; else bat  --color=always --style=header,grid --line-range :100 {}; fi")
  else
    if [ -f $1 ]; then
      selected=$1
    else
      candidate=`fd --color=always -t f`
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
    selected=$(fd --color=always -t f | fzf --preview "bat  --color=always --style=header,grid --line-range :100 {}")
  else
    if [ -f $1 ]; then
      selected=$1
    else
      selected=$(fd --color=always -t f | fzf --query "$1" --preview "bat  --color=always --style=header,grid --line-range :100 {}")
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
  local selected
  if [ $# != 0 ]; then
    selected=$@
  else 
    selected=`git for-each-ref refs/heads/ --format='%(refname:short)' | fzf --preview "git log --graph --color --pretty=format:'%>|(20,trunc)%C(red)%h%C(reset) (%><(13,trunc)%C(blue)%cr%C(reset))  %<(50,trunc)%C(yellow)%s%C(reset)  %C(cyan)<%an>%C(reset)' --abbrev-commit {}"`
  fi

  if [ -n "$selected" ]; then
    git switch $selected
  else
    echo "No bransh is selected"
  fi

}
alias fs="fswitch"

fdot() {
  local candidate selected
  candidate=`fd -t f . ${ROOT_DIR_PATH}`
  candidate=`for f in ${candidate};do echo $f | sed -e "s|${ROOT_DIR_PATH}/||g"; done`
  selected=`echo ${candidate}| fzf --preview "bat  --color=always --style=header,grid --line-range :100 ${ROOT_DIR_PATH}/{}"`
  if [ -n "$selected" ];then
    nvim ${ROOT_DIR_PATH}/${selected}
  else
    echo "No file is selected"
  fi
}
