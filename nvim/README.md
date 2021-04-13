deinの設定はちょっと独自

```
curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > installer.sh
# プラグインのインストール先を~/config/nvim/dein以下に設定している．
sh ./installer.sh ~/.config/nvim/dein
```

# Makefileのターゲット
`enabled`に置かれたスクリプトが読み込まれる様になっている．

## `make`
`make minimal`と同義

## `make minimal`
`general/*.vim`のシンボリックリンクを`enabled`配下に貼る.

## `make full`
`make minimal`に加え，`plugins/90_dein_init.vim`のシンボリックリンクを`enabled`に貼る.
これにより，`plugins`配下の`toml`ファイルがロードされるようになる．

## `make clean`
`enabled`を削除する
