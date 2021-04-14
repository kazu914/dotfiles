#!/bin/bash
PATH=${HOME}/.nodebrew/current/bin:${PATH}

packages=(
  commitizen
  cz-emoji
  neovim
)


function uninstall_if_exist () {
   if npm list --depth 0 -g $1 | grep empty >/dev/null ; then
     npm remove -g $1 > /dev/null
     echo  npm: removed $1
   else
     echo  npm: not found : $1
   fi
}

for package in "${packages[@]}" ; do
  uninstall_if_exist ${package}
done
