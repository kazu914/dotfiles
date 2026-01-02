# VSCode Settings Setup for Windows

このディレクトリには、Windows環境でVSCode設定をシンボリックリンクで配置するためのスクリプトが含まれています。

## ファイル構成

- `setup.ps1` - PowerShellスクリプト本体
- `setup.bat` - バッチファイルラッパー（簡易実行用）
- `settings.json` - VSCode設定ファイル
- `keybindings.json` - キーバインド設定
- `extensions` - インストールする拡張機能リスト

## 使用方法

### 方法1: バッチファイルから実行（推奨）

1. エクスプローラーで `setup.bat` を右クリック
2. 「管理者として実行」を選択
3. 指示に従って実行

```cmd
# 通常のセットアップ
setup.bat

# 強制的に上書き
setup.bat force

# クリーンアップ（シンボリンク削除）
setup.bat clean
```

### 方法2: PowerShellから直接実行

1. PowerShellを管理者権限で起動
2. このディレクトリに移動
3. スクリプトを実行

```powershell
# 通常のセットアップ
.\setup.ps1

# 強制的に上書き
.\setup.ps1 -Force

# クリーンアップ（シンボリンク削除）
.\setup.ps1 -Clean

# 拡張機能のインストールをスキップ
.\setup.ps1
# -> プロンプトで "n" を入力
```

## 前提条件

### 管理者権限

Windowsでシンボリックリンクを作成するには、通常は管理者権限が必要です。

または、Windows 10 バージョン1703以降では、開発者モードを有効にすることで管理者権限なしでシンボリンクを作成できます：

1. 設定 > 更新とセキュリティ > 開発者向け
2. 「開発者モード」をオン

### PowerShell実行ポリシー

スクリプトが実行できない場合は、実行ポリシーを変更してください：

```powershell
# 現在のポリシー確認
Get-ExecutionPolicy

# ポリシー変更（管理者権限で実行）
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

`setup.bat` を使用する場合は、`-ExecutionPolicy Bypass` オプションで実行されるため、実行ポリシーの変更は不要です。

## スクリプトが行うこと

### セットアップ時

1. VSCode設定ディレクトリ（`%APPDATA%\Code\User`）を確認
2. 以下のファイルのシンボリンクを作成：
   - `settings.json`
   - `keybindings.json`
3. （オプション）`extensions` ファイルに記載された拡張機能をインストール
4. インストール済み拡張機能のリストを `extensions` ファイルに保存

### クリーンアップ時

- 作成されたシンボリンクを削除（通常のファイルは削除しません）

## トラブルシューティング

### シンボリンク作成に失敗する

- 管理者権限で実行しているか確認
- または開発者モードを有効にする
- ターゲットディレクトリが既に存在し、シンボリンクでない場合は手動でバックアップして削除

### 拡張機能のインストールに失敗する

- `code` コマンドがPATHに通っているか確認
- VSCodeを再インストールして「PATHに追加」オプションを有効にする

### 既存の設定ファイルがある場合

- `-Force` オプションを使用すると既存のシンボリンクを上書きします
- 通常のファイルの場合は、手動でバックアップしてから削除してください

## Mac/Linux との違い

- Mac/Linux: `Makefile` を使用（`make init` / `make clean`）
- Windows: PowerShellスクリプトを使用（`setup.ps1` / `setup.bat`）

両方のスクリプトは同じ設定ファイルを共有します。
