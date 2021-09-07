CURRENT_DIR_PATH=${0:a:h}
PARENT_DIR_PATH=${CURRENT_DIR_PATH%/*}
ROOT_DIR_PATH=${PARENT_DIR_PATH%/*}

#############################################################################################
##################################### fuzzy vim #############################################
#############################################################################################
fvim (){
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
alias fim="fvim"

#############################################################################################
##################################### fuzzy cat #############################################
#############################################################################################
fcat (){
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
alias fat="fcat"

#############################################################################################
################################ fuzzy edit dotfiles ########################################
#############################################################################################
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

#############################################################################################
################################## fuzzy rg vim #############################################
#############################################################################################
frg() {
  local candidate selected selected_file selected_line
  candidate=`rg --hidden --line-number --no-heading --invert-match '^\s*$' 2>/dev/null`
  selected=`echo ${candidate}  | fzf --select-1 --exit-0 -d ":" --preview "bat  --color=always --style=header,grid,numbers --theme='Solarized (dark)' --highlight-line {2} {1}"`
  selected=${selected%:*}
  selected_file=${selected%:*}
  selected_line=${selected#*:}

  if [ -n "$selected_line" -a -n "$selected_file" ]; then
    nvim $selected_file +$selected_line
  else
    echo "No code is selected"
  fi
}

#############################################################################################
#################################### fuzzy cd ###############################################
#############################################################################################
fcd() {
  local candidate selected 
  candidate=`fd -t d`
  selected=`echo ${candidate}  | fzf --select-1 --exit-0 --preview "lsd -lA --icon always --color always --date relative {}"`

  if [ -n "$selected" ];then
    z $selected
  else
    echo "No file is selected"
  fi

}

