#!/bin/zsh

### INSTALL todo COMMAND ###
todo_command_name="todo"
if ! command -v "$todo_command_name" &> /dev/null; then
    echo "Command '$todo_command_name' is not found. Start download and install ..."
    cd /tmp || exit
    curl -LOJ https://github.com/kazu914/todo_txt_cli/releases/download/v0.0.2/todo_txt-x86_64-apple-darwin
    echo "sudo mv todo_txt-x86_64-apple-darwin /usr/local/bin/$todo_command_name"
    sudo mv todo_txt-x86_64-apple-darwin /usr/local/bin/$todo_command_name
    echo "sudo chmod +x /usr/local/bin/$todo_command_name"
    sudo chmod +x /usr/local/bin/$todo_command_name
fi

### INSTALL csvlens COMMAND ###
csvlens_command_name="csvlens"
if ! command -v "$csvlens_command_name" &> /dev/null; then
    echo "Command '$csvlens_command_name' is not found. Start download and install ..."
    cd /tmp || exit
    curl -LOJ https://github.com/YS-L/csvlens/releases/download/v0.5.1/csvlens-aarch64-apple-darwin.tar.xz
    tar -xf  csvlens-aarch64-apple-darwin.tar.xz
    echo "sudo mv csvlens-aarch64-apple-darwin/csvlens /usr/local/bin/${csvlens_command_name}"
    sudo mv csvlens-aarch64-apple-darwin/csvlens /usr/local/bin/${csvlens_command_name}
    echo "sudo chmod +x /usr/local/bin/${csvlens_command_name}"
    sudo chmod +x /usr/local/bin/${csvlens_command_name}
fi
