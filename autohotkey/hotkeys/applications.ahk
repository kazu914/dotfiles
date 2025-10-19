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
    if !ProcessExist("WindowsTerminal.exe") {
        Run("wt.exe")  ; Windows Terminal 起動
    } else {
        winTitle := "ahk_exe WindowsTerminal.exe"
        if WinExist(winTitle) {
            WinActivate(winTitle)
        } else {
            MsgBox "Windows Terminal のウィンドウが見つかりません。"
        }
    }
}
