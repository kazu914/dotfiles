# p10k
zinit ice depth=1; zinit light romkatv/powerlevel10k
# # To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


# exa
zinit ice as"program" from"gh-r" mv"exa* -> exa"
zinit light ogham/exa


# bat
zinit ice as"program" from"gh-r" mv"bat* -> bat" pick"bat/bat"
zinit light sharkdp/bat


zinit light zdharma/fast-syntax-highlighting


zinit light zsh-users/zsh-autosuggestions
bindkey '^j' autosuggest-accept
