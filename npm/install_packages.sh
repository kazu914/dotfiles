#!/bin/bash
NPM=${HOME}/.nodebrew/current/bin

packages=(
  commitizen
  cz-emoji
  neovim
)


function install_if_not_exist () {
   if ${NPM}/npm list --depth 0 -g $1 | grep empty >/dev/null ; then
     ${NPM}/npm install -g $1 > /dev/null
     echo  npm: installed $1
   else
     echo  npm: already installed: $1
   fi
}

for package in "${packages[@]}" ; do
  install_if_not_exist ${package}
done
