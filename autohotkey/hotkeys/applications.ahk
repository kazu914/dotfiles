#Requires AutoHotkey v2.0
#SingleInstance Force

; Win + G で実行
#G::
{
    ; Chrome が起動しているか確認
    if !ProcessExist("chrome.exe") {
        Run("chrome.exe") ; Chrome 起動
    } else {
        ; Chrome のウィンドウを探してフォーカス
        winTitle := "ahk_exe chrome.exe"
        if WinExist(winTitle) {
            WinActivate(winTitle)
        } else {
            MsgBox "Chrome のウィンドウが見つかりません。"
        }
    }
}

#Space::  ; Win + Space
{
    winTitle := "ahk_exe wezterm-gui.exe"
    if WinExist(winTitle) {
        WinActivate(winTitle)
    } else {
        ; フルパスで wezterm.exe を直接起動
        Run("C:\Program Files\WezTerm\wezterm-gui.exe")
    }
}
