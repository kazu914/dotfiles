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


; ===== Ctrl + A → 行頭へ移動 =====
#InputLevel 1
^a::
{
    Send("{Home}")
}

; ===== Win + A → 全選択（Ctrl + A） =====
#InputLevel 0
#a::
{
    SendInput("^a")
}

; ===== Ctrl + E → 行末へ移動 =====
^e::Send("{End}")
