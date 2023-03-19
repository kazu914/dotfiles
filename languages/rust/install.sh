if ! command -v cargo > /dev/null; then
  echo "cargo not found. Installing..."
  curl https://sh.rustup.rs -sSf | sh
else
  echo "cargo has already installed."
fi

if ! command -v rust-analyzer > /dev/null; then
  echo "rust-analyzer not found. Installing..."
  rustup component add rust-analyzer
  echo "Create symlink $HOME/.cargo/bin/rust-analyzer -> ln -s $(rustup which --toolchain stable rust-analyzer)"
  ln -s $(rustup which --toolchain stable rust-analyzer) $HOME/.cargo/bin
else
  echo "rust-analyzer has already installed."
fi
