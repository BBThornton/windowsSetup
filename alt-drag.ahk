#Requires AutoHotkey v2.0
#SingleInstance Force

; ─────────────────────────────────────────────────────────────────────────────
; Alt + Mouse Drag — window move / resize for GlazeWM
;
; Mirrors Hyprland's:
;   bindm = SUPER, mouse:272, movewindow    → Alt + LMB drag   = move window
;   bindm = SUPER, mouse:273, resizewindow  → Alt + RMB drag   = resize window
;
; Works best with FLOATING windows (Win+Space in GlazeWM to toggle).
; Dragging a TILED window will move it, but GlazeWM's layout engine
; will recapture it when you release — float it first for free movement.
;
; Install: https://www.autohotkey.com/  (v2, NOT v1)
; Startup: copy to shell:startup  or  Task Scheduler → trigger at logon
; ─────────────────────────────────────────────────────────────────────────────

; ── Alt + Left Click drag → MOVE window ──────────────────────────────────────
~LAlt & LButton:: {
    ; Capture initial mouse position and window position
    MouseGetPos(&startX, &startY, &hwnd)
    WinGetPos(&initWinX, &initWinY, , , "ahk_id " hwnd)

    ; Drag loop — runs while LButton is held
    while GetKeyState("LButton", "P") {
        MouseGetPos(&nowX, &nowY)
        WinMove(
            initWinX + (nowX - startX),
            initWinY + (nowY - startY),
            , ,
            "ahk_id " hwnd
        )
        Sleep(10)
    }
}

; ── Alt + Right Click drag → RESIZE window (from bottom-right corner) ────────
~LAlt & RButton:: {
    ; Capture initial mouse position and window dimensions
    MouseGetPos(&startX, &startY, &hwnd)
    WinGetPos( , , &initW, &initH, "ahk_id " hwnd)

    ; Drag loop — runs while RButton is held
    while GetKeyState("RButton", "P") {
        MouseGetPos(&nowX, &nowY)
        newW := Max(100, initW + (nowX - startX))
        newH := Max(100, initH + (nowY - startY))
        WinMove( , , newW, newH, "ahk_id " hwnd)
        Sleep(10)
    }
}
