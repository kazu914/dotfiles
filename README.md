# My dotfiles repo
This repo includes dotfiles for
- `zsh`
- `nvim`
- `tmux`
- `git`

# How to install

```zsh
# Clone this repository
git clone https://github.com/kazu914/dotfiles

# Move to the repository
mv dotfiles

# Initialize some additional packages
make

source ~/.zshrc
```

# Others
 - Using [HackGen](https://github.com/yuru7/HackGen) for console font

## Makefile targets
### minimal
install below
- neovim without plugins
- zsh without some plugins
- tmux

### full
install below
- neovim with plugins
- zsh with plugins
- tmux
- i3 setting
- git config
- nodebrew

### clean
clean installed settings

### npm_install
If you want to install npm packages below, run `make npm_install`
- commitizen
- cz-emoji
- neovim


