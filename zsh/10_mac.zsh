#!/bin/bash

function fzf_launch() {
  local applications
  applications="$(find /Applications /System/Applications -name "*app" -maxdepth 2)"
  open -a "$( printf '%s\n' "${applications[@]}" | awk -F/ '{print $NF}' | sed 's/\.app//'| sort | $HOME/.zinit/plugins/junegunn---fzf/fzf)"
}

function fzf_bookmarks() {
  candidate1=`\cat ${HOME}/Library/Application\ Support/Google/Chrome/Default/Bookmarks | jq -r '.roots.bookmark_bar as $p | $p.children[] | select(has("url")|not) | .children[] |  .name + " | " + .url'`
  candidate2=`\cat ${HOME}/Library/Application\ Support/Google/Chrome/Default/Bookmarks | jq -r '.roots.bookmark_bar as $p | $p.children[] | select(has("url")) | .name + " | " + .url'`
  candidate=( "${candidate1[@]}" "${candidate2[@]}" )
  selected=$(echo "$candidate" | $HOME/.zinit/plugins/junegunn---fzf/fzf)
  open -a 'Google Chrome' `echo ${selected##*|}`
}

if [[ $OSTYPE == 'darwin'* ]]; then
  alias d=fzf_launch
fi


