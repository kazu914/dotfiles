function fzf_launch() {
  local applications
  applications="$(find /Applications /System/Applications -name "*app" -maxdepth 2)"
  open -a "$( printf '%s\n' "${applications[@]}" | awk -F/ '{print $NF}' | sed 's/\.app//'| sort | $HOME/.zinit/plugins/junegunn---fzf/fzf)"
}

if [[ $OSTYPE == 'darwin'* ]]; then
  alias d=fzf_launch
fi

