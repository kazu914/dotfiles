SCRIPT_DIR=$(cd $(dirname $0); pwd)
install_dein (){
  mkdir -p $HOME/.config/nvim/dein/repos/github.com/Shougo/dein.vim
  git clone https://github.com/Shougo/dein.vim.git $HOME/.config/nvim/dein/repos/github.com/Shougo/dein.vim
}

install_tpm (){
  mkdir -p $HOME/.tmux/plugins
  git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm
}

install_dein
install_tpm
