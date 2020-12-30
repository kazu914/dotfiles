#############################################################################################
######################################## p10k ###############################################
#############################################################################################
zinit ice depth=1; zinit light romkatv/powerlevel10k


#############################################################################################
####################################### exa #################################################
#############################################################################################
zinit ice as"program" from"gh-r" mv"exa* -> exa"
zinit light ogham/exa
if builtin command -v exa > /dev/null; then
  alias ll="exa -l --icons"
  alias la="exa -aal --icons"
  alias ls="exa --icons"
fi

#############################################################################################
################################### github cli ##############################################
#############################################################################################
zinit ice as"program" from"gh-r" pick"usr/bin/gh"
zinit light cli/cli

#############################################################################################
##################################### bottom ################################################
#############################################################################################
zinit ice as"program" from"gh-r" 
zinit light ClementTsang/bottom

#############################################################################################
######################################## dps ################################################
#############################################################################################
zinit ice as"program" from"gh-r" 
zinit light kazu914/dps

#############################################################################################
#################################### dmountpoint ############################################
#############################################################################################
zinit ice as"program" from"gh-r" 
zinit light kazu914/dmountpoint

#############################################################################################
####################################### nvim ################################################
#############################################################################################
zinit ice as"program" from"gh-r" mv"nvim* -> nvim" pick"nvim/bin/nvim"
zinit light neovim/neovim

#############################################################################################
########################################## k ################################################
#############################################################################################
zinit light supercrabtree/k
if builtin command -v k > /dev/null; then
  alias k="k -Ah"
fi

#############################################################################################
################################### syntax highlight ########################################
#############################################################################################
zinit light zdharma/fast-syntax-highlighting


#############################################################################################
##################################### auto suggest ##########################################
#############################################################################################
zinit light zsh-users/zsh-autosuggestions
bindkey '^j' autosuggest-accept

#############################################################################################
####################################### git open ############################################
#############################################################################################
zinit light paulirish/git-open

#############################################################################################
####################################### bat #################################################
#############################################################################################
zinit ice as"program" from"gh-r" mv"bat* -> bat" pick"bat/bat"
zinit light sharkdp/bat
if builtin command -v bat > /dev/null; then
  alias cat="bat"
fi

#############################################################################################
####################################### memo ################################################
#############################################################################################
zinit ice as"program" from"gh-r" mv"memo* -> memo" pick"memo/memo"
zinit light mattn/memo

#############################################################################################
################################### efm-langserver ##########################################
#############################################################################################
zinit ice as"program" from"gh-r" mv"efm-langserver* -> efm-langserver" pick"efm-langserver/efm-langserver"
zinit light mattn/efm-langserver

mkdir -p $HOME/.config/efm-langserver
if [[ ! -h $HOME/.config/efm-langserver/config.yaml ]]; then
  ln -sv ./efm-langserver/config.yaml $HOME/.config/efm-langserver/
fi

#############################################################################################
####################################### fzf #################################################
#############################################################################################
zinit ice from"gh-r" as"program"
zinit load junegunn/fzf-bin
export FZF_DEFAULT_OPTS="--reverse --inline-info --height 70% --border"
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
__fzfcmd() {
  [ -n "$TMUX_PANE" ] && { [ "${FZF_TMUX:-0}" != 0 ] || [ -n "$FZF_TMUX_OPTS" ]; } &&
    echo "fzf-tmux ${FZF_TMUX_OPTS:--d${FZF_TMUX_HEIGHT:-40%}} -- " || echo "fzf"
}
# ALT-C - cd into the selected directory
fzf-cd-widget() {
  local cmd="${FZF_ALT_C_COMMAND:-"command find -L . -mindepth 1 \\( -path '*/\\.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \\) -prune \
    -o -type d -print 2> /dev/null | cut -b3-"}"
  setopt localoptions pipefail no_aliases 2> /dev/null
  local dir="$(eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS $FZF_ALT_C_OPTS" $(__fzfcmd) +m)"
  if [[ -z "$dir" ]]; then
    zle redisplay
    return 0
  fi
  if [ -z "$BUFFER" ]; then
    BUFFER="cd ${(q)dir}"
    zle accept-line
  else
    print -sr "cd ${(q)dir}"
    cd "$dir"
  fi
  local ret=$?
  unset dir # ensure this doesn't end up appearing in prompt expansion
  zle fzf-redraw-prompt
  return $ret
}
zle     -N    fzf-cd-widget
bindkey '\ec' fzf-cd-widget
# CTRL-R - Paste the selected command from history into the command line
fzf-history-widget() {
  local selected num
  setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases 2> /dev/null
  selected=( $(fc -rl 1 | perl -ne 'print if !$seen{(/^\s*[0-9]+\**\s+(.*)/, $1)}++' |
    FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} $FZF_DEFAULT_OPTS -n2..,.. --tiebreak=index --bind=ctrl-r:toggle-sort $FZF_CTRL_R_OPTS --query=${(qqq)LBUFFER} +m" $(__fzfcmd)) )
  local ret=$?
  if [ -n "$selected" ]; then
    num=$selected[1]
    if [ -n "$num" ]; then
      zle vi-fetch-history -n $num
    fi
  fi
  zle reset-prompt
  return $ret
}
zle     -N   fzf-history-widget
bindkey '^R' fzf-history-widget


