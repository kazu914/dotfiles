#############################################################################################
################################### fuzzy git add ###########################################
#############################################################################################
fadd() {
  local out q n addfiles
  while out=$(
      git status -u --short |
      awk '{if (substr($0,2,1) !~ / /) print $2}' |
      fzf --multi --exit-0 --expect=ctrl-d --preview "if git ls-files --error-unmatch {} > /dev/null 2>&1; then git diff --color {}; else bat  --color=always --style=header --line-range :100 {}; fi"); do
    q=$(head -1 <<< "$out")
    n=$[$(wc -l <<< "$out") - 1]
    addfiles=(`echo $(tail "-$n" <<< "$out")`)
    [[ -z "$addfiles" ]] && continue
    if [ "$q" = ctrl-d ]; then
      ${EDITOR:-vim} $addfiles 
    else
      git add $addfiles
    fi
  done
}
alias fa="fadd"

#############################################################################################
################################ fuzzy switch branch ########################################
#############################################################################################
fswitch() {
  local selected
  if [ $# != 0 ]; then
    selected=$@
  else 
    selected=`git for-each-ref refs/heads/ refs/remotes/ --format='%(refname:short)' --sort='-committerdate' | fzf --preview "git log --graph --color --pretty=format:'%>|(20,trunc)%C(red)%h%C(reset) (%><(13,trunc)%C(blue)%cr%C(reset))  %<(50,trunc)%C(yellow)%s%C(reset)  %C(cyan)<%an>%C(reset)' --abbrev-commit {}"`
  fi
  if [ -n "$selected" ]; then
    if [ "`echo $selected | grep 'origin'`" ]; then
      git switch $selected -c ${selected#origin/}
    else
      git switch $selected 
    fi
  else
    echo "No bransh is selected"
  fi

}
alias fs="fswitch"

#############################################################################################
################################## fuzzy git reset ##########################################
#############################################################################################
freset() {
  local basedir out q n resetfiles file
  basedir=`git rev-parse --show-superproject-working-tree --show-toplevel | head -1`
  while out=$(git diff --staged --name-only | fzf --multi --exit-0 --expect=ctrl-d --preview "git diff --staged --color $basedir/{}"); do
    q=$(head -1 <<< "$out")
    n=$[$(wc -l <<< "$out") - 1]
    resetfiles=(`echo $(tail "-$n" <<< "$out")`)
    [[ -z "$resetfiles" ]] && continue
    if [ "$q" = ctrl-d ]; then
      ${EDITOR:-vim} $resetfiles 
    else
      for file in $resetfiles;do
        git reset HEAD $basedir/$file
      done
    fi
  done
}

#############################################################################################
################################# fuzzy git restore #########################################
#############################################################################################
frestore() {
  local out q n restorefiles
  while out=$(
      git status -u --short |
      awk '{if (substr($0,2,1) !~ / /) print $2}' |
      fzf --multi --exit-0 --expect=ctrl-d --preview "git diff --color {}"); do
    q=$(head -1 <<< "$out")
    n=$[$(wc -l <<< "$out") - 1]
    restorefiles=(`echo $(tail "-$n" <<< "$out")`)
    [[ -z "$restorefiles" ]] && continue
    if [ "$q" = ctrl-d ]; then
      ${EDITOR:-vim} $restorefiles 
    else
      git restore $restorefiles
    fi
  done
}

#############################################################################################
################################### fuzzy git show ##########################################
#############################################################################################
fshow() {
  local selected
  selected=`git log --oneline --pretty=format:'%h [%cd] %d %s <%an>' --date=format:'%Y/%m/%d %H:%M' | fzf --preview='git show {1}' | cut -f 1 -d " "`
  if [ -n "$selected" ]; then
    git show $selected
  else
    echo "No hash is selected"
  fi
}

#############################################################################################
############################# fuzzy cd in the repository ####################################
#############################################################################################
gcd() {
  local basedir candidate selected
  basedir=`git rev-parse --show-superproject-working-tree --show-toplevel | head -1`
  candidate=`fd -t d . $basedir | sed "s|^$basedir||g"`
  candidate=("/\n"${candidate[@]})
  selected=`echo ${candidate}  | fzf --select-1 --exit-0 --preview "lsd -1A --icon always --color always $basedir/{}"`
  if [ -n "$selected" ];then
    print -s "cd $basedir$selected"
    z $basedir$selected
  else
    echo "No file is selected"
  fi
}
