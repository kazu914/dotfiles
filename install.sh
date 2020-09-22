#!/bin/bash
main () {
  SCRIPT_DIR=$(cd $(dirname $0); pwd)
  ln -s $SCRIPT_DIR/.gitconfig ~/.gitconfig
}


main
