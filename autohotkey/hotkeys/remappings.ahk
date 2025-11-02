#Requires AutoHotkey v2.0
#SingleInstance Force

; ====== Win + C でコピー ======
#c::
{
    Send("^c")  ; Ctrl + C を送信
}

; ====== Win + V でペースト ======
#v::
{
    Send("^v")  ; Ctrl + V を送信
}

; ===== Win + Shift + V → 元の Win + V (クリップボード履歴) =====
#+v::
{
    ; AHKが奪ってしまうので、Windows本来のキーを再送信する
    Send("#v")  ; "#" = Winキー
}

; ==================================================
; Chrome 上でのみ有効
; ==================================================
#HotIf IsChromeActive()

#InputLevel 1
^a::Send("{Home}")   ; Ctrl + A → 行頭へ
#InputLevel 0
#a::Send("^a")       ; Win + A → 全選択
^e::Send("{End}")    ; Ctrl + E → 行末へ

#HotIf  ; 条件終了

; ====== 関数定義 ======
IsChromeActive() {
    winClass := WinGetClass("A")
    procName := WinGetProcessName("A")
    ; Chrome のウィンドウクラスは "Chrome_WidgetWin_1"
    return (winClass = "Chrome_WidgetWin_1") && (procName ~= "i)chrome\.exe")
}
