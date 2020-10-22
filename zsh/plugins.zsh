# p10k
zinit ice depth=1; zinit light romkatv/powerlevel10k
# # To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


# exa
zinit ice as"program" from"gh-r" mv"exa* -> exa"
zinit light ogham/exa
if builtin command -v exa > /dev/null; then
  alias ll="exa -l --icons"
  alias la="exa -aal --icons"
  alias ls="exa --icons"
fi


# bat
zinit ice as"program" from"gh-r" mv"bat* -> bat" pick"bat/bat"
zinit light sharkdp/bat
if builtin command -v bat > /dev/null; then
  alias cat="bat"
fi


# fzf
zinit ice from"gh-r" as"program"
zinit load junegunn/fzf-bin
export FZF_DEFAULT_OPTS="--reverse --inline-info --height 70% --border"
fadd() {
  local out q n addfiles
  while out=$(
      git status --short |
      awk '{if (substr($0,2,1) !~ / /) print $2}' |
      fzf-tmux --multi --exit-0 --expect=ctrl-d); do
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


zinit light zdharma/fast-syntax-highlighting


zinit light zsh-users/zsh-autosuggestions
bindkey '^j' autosuggest-accept
