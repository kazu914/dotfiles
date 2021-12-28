#!/bin/bash

function fzf_bookmarks() {
  candidate1=`\cat ${HOME}/Library/Application\ Support/Google/Chrome/Default/Bookmarks | jq -r '.roots.bookmark_bar as $p | $p.children[] | select(has("url")|not) | .children[] |  .name + " | " + .url'`
  candidate2=`\cat ${HOME}/Library/Application\ Support/Google/Chrome/Default/Bookmarks | jq -r '.roots.bookmark_bar as $p | $p.children[] | select(has("url")) | .name + " | " + .url'`
  candidate=( "${candidate1[@]}" "${candidate2[@]}" )
  selected=$(echo "$candidate" | $HOME/.zinit/plugins/junegunn---fzf/fzf)
  open -a 'Google Chrome' `echo ${selected##*|}`
}
