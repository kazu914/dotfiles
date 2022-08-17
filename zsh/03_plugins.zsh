CURRENT_DIR_PATH=${0:a:h}

#############################################################################################
################################## starship #################################################
#############################################################################################
zinit ice wait lucid as"program" from"gh-r" mv"starship* -> starship" 
zinit light starship/starship


#############################################################################################
####################################### exa #################################################
#############################################################################################
zinit ice wait lucid as"program" from"gh-r" mv"lsd* -> lsd" pick"lsd/lsd"
zinit light Peltoche/lsd

#############################################################################################
##################################### delta #################################################
#############################################################################################
zinit ice wait lucid as"program" from"gh-r" mv"delta* -> delta" pick"delta/delta"
zinit light dandavison/delta

#############################################################################################
################################### ripgrep #################################################
#############################################################################################
zinit ice wait lucid as"program" from"gh-r" mv"ripgrep* -> ripgrep" pick"ripgrep/rg"
zinit light BurntSushi/ripgrep

#############################################################################################
################################### github cli ##############################################
#############################################################################################
zinit ice wait lucid as"program" from"gh-r" pick"usr/bin/gh"
zinit light cli/cli

#############################################################################################
########################################## k ################################################
#############################################################################################
zinit ice wait lucid
zinit light supercrabtree/k
if builtin command -v k > /dev/null; then
  alias k="k -h"
fi

#############################################################################################
################################### syntax highlight ########################################
#############################################################################################
zinit ice wait lucid
zinit light zdharma-continuum/fast-syntax-highlighting

#############################################################################################
##################################### auto suggest ##########################################
#############################################################################################
zinit light zsh-users/zsh-autosuggestions
bindkey '^j' autosuggest-accept

#############################################################################################
####################################### bat #################################################
#############################################################################################
zinit ice wait lucid as"program" from"gh-r" mv"bat* -> bat" pick"bat/bat"
zinit light sharkdp/bat

#############################################################################################
####################################### fzf #################################################
#############################################################################################
zinit ice wait lucid from"gh-r" as"program"
zinit load junegunn/fzf

#############################################################################################
###################################### memo #################################################
#############################################################################################
zinit ice wait lucid as'program' from"gh-r"  mv"memo* -> memo" pick"memo/memo"
zinit light mattn/memo

#############################################################################################
################################## code-minimap #############################################
#############################################################################################
zinit ice wait lucid from"gh-r" as"program" mv"code-minimap* -> code-minimap" pick"code-minimap/code-minimap"
zinit load wfxr/code-minimap

#############################################################################################
####################################### fd #################################################
#############################################################################################
zinit ice wait lucid as"program" from"gh-r" mv"fd* -> fd" pick"fd/fd"
zinit light sharkdp/fd

#############################################################################################
####################################### deno #################################################
#############################################################################################
zinit ice wait lucid as"program" from"gh-r" mv"deno* -> deno" pick"deno/deno"
zinit light denoland/deno

#############################################################################################
##################################### misspell ##############################################
#############################################################################################
zinit ice wait lucid as"program" from"gh-r" mv"misspell* -> misspell" pick"misspell/misspell"
zinit light client9/misspell

#############################################################################################
##################################### lazygit ##############################################
#############################################################################################
zinit ice wait lucid as"program" from"gh-r" mv"lazygit* -> lazygit" pick"lazygit/lazygit"
zinit light jesseduffield/lazygit

#############################################################################################
################################### todo_txt_cli ############################################
#############################################################################################
zinit ice wait lucid as"program" from"gh-r" mv"todo_txt* -> todo" pick"todo_txt_cli/todo"
zinit light kazu914/todo_txt_cli

#############################################################################################
##################################### kakisute ##############################################
#############################################################################################
zinit ice wait lucid as"program" from"gh-r" mv"kakisute* -> kakisute" pick"kakisute/kakisute"
zinit light kazu914/kakisute

#############################################################################################
################################### completion ############################################
#############################################################################################
zinit light zsh-users/zsh-completions
