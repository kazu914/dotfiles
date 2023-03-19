if ! command -v zoxide > /dev/null; then
  echo "zoxide not found. Installing..."
  curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi

if [[ -n $(alias zi 2>/dev/null) ]]; then
  unalias zi
fi

eval "$(zoxide init zsh)"
