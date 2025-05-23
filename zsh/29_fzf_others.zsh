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
  basedir=`git rev-parse --show-superproject-working-tree --show-toplevel | head -1`
  candidate=`fd -E "*.jar" -t f . $basedir | sed "s|^$basedir||g"`
  candidate=($empty"\n"${candidate[@]})

  if [ $# = 0 ];then
    selected=$(echo $candidate | fzf --preview-window=right:50%:rounded:cycle:wrap --preview "if [ {} = '$empty' ]; then echo 'Open Here'; else bat  --color=always --style=header,grid --line-range :100 $basedir{}; fi")
  else
    selected=$(echo $candidate | fzf --preview-window=right:50%:rounded:cycle:wrap --query "$1" --preview "if [ {} = '$1' ]; then echo 'Create new file: $1'; else bat  --color=always --style=header,grid --line-range :100 $basedir{}; fi")
  fi

  if [ -n "$selected" ];then
    if [ "$selected" = "$empty" ];then
      print -s "${EDITOR} ./"
      ${EDITOR} ./
    else
      print -s "${EDITOR} $basedir$selected"
      ${EDITOR} $basedir$selected
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
    print -s "cat $selected"
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
    print -s "vim ${ROOT_DIR_PATH}/${selected}"
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
    print -s "vim $selected_file +$selected_line"
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
  selected=`echo ${candidate}  | fzf --select-1 --exit-0 --preview "lsd -1A --icon always --color always {}"`

  if [ -n "$selected" ];then
    print -s "cd $selected"
    z $selected
  else
    echo "No file is selected"
  fi
}

#############################################################################################
#################################### fuzzy bun ###############################################
#############################################################################################
fb() {
  # package.jsonの存在確認
  if [[ ! -f package.json ]]; then
    echo "package.jsonが見つかりません"
    return 1
  fi

  # jqでスクリプト名を取得し、fzfで選択
  local script
  script=$(jq -r '.scripts | keys[]' package.json | fzf --preview="jq --arg key {} -r '.scripts[\$key]' package.json" )

  # スクリプトが選択されなかった場合
  if [[ -z "$script" ]]; then
    echo "スクリプトが選択されませんでした"
    return 1
  fi

  # 選択されたスクリプトを実行
  bun run "$script"
}

switch_session() {
  local candidate selected
  candidate=`tmux ls`
  selected=`echo ${candidate} | fzf`
  if [ -n "$selected" ];then
    echo ${selected%%\:*}
    print -s "tmux switch -t ${selected%%\:*}"
    tmux switch -t ${selected%%\:*}
  else
    echo "No session is selected"
  fi
}
