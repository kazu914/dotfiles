#!/bin/bash
SCRIPT_DIR=$(cd $(dirname $0); pwd)
main () {
  DOT_FILES=(.gitconfig .tmux.conf .zshrc .p10k.zsh .czrc)

  for file in ${DOT_FILES[@]}
  do
    ln -sfnv $SCRIPT_DIR/$file $HOME/$file
  done
}

install_nvim () {
  mkdir -p $HOME/.config 
  ln -sfnv $SCRIPT_DIR/nvim $HOME/.config/nvim 
} 

main
install_nvim
sh npm/install_packages.sh
