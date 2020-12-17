SCRIPT_DIR=$(cd $(dirname $0); pwd)
install_dein (){
  mkdir -p $HOME/.config/nvim/dein/repos/github.com/Shougo/dein.vim
  git clone https://github.com/Shougo/dein.vim.git $HOME/.config/nvim/dein/repos/github.com/Shougo/dein.vim
}

install_tpm (){
  mkdir -p $HOME/.tmux/plugins
  git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm
}

install_node (){
  curl -L git.io/nodebrew | perl - setup
  $HOME/.nodebrew/current/bin/nodebrew install v14.9.0
  $HOME/.nodebrew/current/bin/nodebrew use v14.9.0

}

install_dein
install_tpm
install_node
