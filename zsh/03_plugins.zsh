#!/bin/zsh

# チェックするコマンド名
command_name="todo"
# コマンドが存在しないかを確認し、存在しなければダウンロードとインストールを行う
if ! command -v "$command_name" &> /dev/null; then
    echo "Command '$command_name' が見つかりません。ダウンロードしてインストールします..."
    # コマンドをダウンロードして /usr/local/bin に移動し、実行権限を付与する
    cd /tmp || exit
    curl -LOJ https://github.com/kazu914/todo_txt_cli/releases/download/v0.0.2/todo_txt-x86_64-apple-darwin
    sudo mv todo_txt-x86_64-apple-darwin /usr/local/bin/todo
    sudo chmod +x /usr/local/bin/todo
fi
