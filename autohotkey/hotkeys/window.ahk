#Requires AutoHotkey v2.0
#SingleInstance Force
SetWinDelay -1  ; WinMove の内部遅延を無効化して滑らかに

; =======================================
; Win + Shift + H → 左半分（アニメーション）
; Win + Shift + L → 右半分（アニメーション）
; Win + Shift + F → 作業領域いっぱい（最大化はしない）
; =======================================
#+h::MoveActiveWindowAnimated("left")
#+l::MoveActiveWindowAnimated("right")
#+f::MoveActiveWindowAnimated("full")

; ---- 設定（好みに応じて調整） ----
ANI_DURATION_MS := 180   ; アニメーション時間（ミリ秒）
ANI_STEPS       := 12    ; ステップ数（多いほど滑らか）

; ---- メイン処理 ----
MoveActiveWindowAnimated(side) {
    global ANI_DURATION_MS, ANI_STEPS
    hwnd := WinExist("A")
    if !hwnd
        return

    ; 最大化／最小化は移動できないのでいったん復元
    mm := WinGetMinMax("ahk_id " hwnd)
    if (mm = 1 || mm = -1)
        WinRestore("ahk_id " hwnd)

    ; 目標矩形（作業領域の左／右半分 or フル）
    wa := GetWorkAreaForWindow(hwnd)  ; {L,T,R,B}
    fullW := wa.R - wa.L
    fullH := wa.B - wa.T

    if (side = "left") {
        tw := fullW // 2, th := fullH, tx := wa.L,       ty := wa.T
    } else if (side = "right") {
        tw := fullW // 2, th := fullH, tx := wa.L + tw,  ty := wa.T
    } else { ; "full"
        tw := fullW,      th := fullH, tx := wa.L,       ty := wa.T
    }

    ; 現在の位置サイズ
    WinGetPos &x0, &y0, &w0, &h0, "ahk_id " hwnd

    ; すでに同じなら軽くスナップだけ
    if (x0 = tx && y0 = ty && w0 = tw && h0 = th) {
        WinMove(tx, ty, tw, th, "ahk_id " hwnd)
        return
    }

    ; イージング（OutCubic）で補間しながら移動
    stepSleep := Max(1, ANI_DURATION_MS // ANI_STEPS)
    Loop ANI_STEPS {
        i  := A_Index
        t  := i / ANI_STEPS
        p  := EaseOutCubic(t)

        xi := Round(x0 + (tx - x0) * p)
        yi := Round(y0 + (ty - y0) * p)
        wi := Round(w0 + (tw - w0) * p)
        hi := Round(h0 + (th - h0) * p)

        WinMove(xi, yi, wi, hi, "ahk_id " hwnd)
        Sleep stepSleep
    }

    ; 最終スナップ（誤差防止）
    WinMove(tx, ty, tw, th, "ahk_id " hwnd)
}

#q::
{
    hwnd := WinExist("A")
    if hwnd
        WinClose("ahk_id " hwnd)
}

; ---- ヘルパー：モニターの作業領域 ----
GetWorkAreaForWindow(hwnd) {
    hMon := DllCall("MonitorFromWindow", "ptr", hwnd, "uint", 2, "ptr") ; 2 = MONITOR_DEFAULTTONEAREST
    mi := Buffer(40, 0)
    NumPut("uint", 40, mi, 0)
    if !DllCall("GetMonitorInfoW", "ptr", hMon, "ptr", mi, "int")
        throw Error("GetMonitorInfo failed")

    ; rcWork の取り出し
    L := NumGet(mi, 20, "int")
    T := NumGet(mi, 24, "int")
    R := NumGet(mi, 28, "int")
    B := NumGet(mi, 32, "int")
    return {L:L, T:T, R:R, B:B}
}

; ---- イージング関数（EaseOutCubic） ----
EaseOutCubic(t) {
    ; t: 0..1
    t := 1 - t
    return 1 - t*t*t
}
