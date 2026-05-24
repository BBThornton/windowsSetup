#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn

; Alt + mouse drag for GlazeWM.
;
; Alt + Left Button  = move the top-level window under the cursor
; Alt + Right Button = resize the top-level window under the cursor
;
; This works best with floating windows. Tiled windows can move briefly, but
; GlazeWM may reclaim them when its layout updates.

CoordMode "Mouse", "Screen"
SetWinDelay -1

!LButton::MoveWindowUnderMouse()
!RButton::ResizeWindowUnderMouse()

MoveWindowUnderMouse() {
    hwnd := GetTopLevelWindowUnderMouse()

    if !hwnd {
        return
    }

    MouseGetPos &startX, &startY
    WinGetPos &startWinX, &startWinY, , , "ahk_id " hwnd

    while GetKeyState("LButton", "P") {
        MouseGetPos &nowX, &nowY
        WinMove startWinX + nowX - startX, startWinY + nowY - startY, , , "ahk_id " hwnd
        Sleep 10
    }
}

ResizeWindowUnderMouse() {
    hwnd := GetTopLevelWindowUnderMouse()

    if !hwnd {
        return
    }

    MouseGetPos &startX, &startY
    WinGetPos , , &startW, &startH, "ahk_id " hwnd

    while GetKeyState("RButton", "P") {
        MouseGetPos &nowX, &nowY
        newW := Max(120, startW + nowX - startX)
        newH := Max(120, startH + nowY - startY)
        WinMove , , newW, newH, "ahk_id " hwnd
        Sleep 10
    }
}

GetTopLevelWindowUnderMouse() {
    MouseGetPos , , &hwnd

    if !hwnd {
        return 0
    }

    root := DllCall("GetAncestor", "ptr", hwnd, "uint", 2, "ptr")

    if root {
        hwnd := root
    }

    className := WinGetClass("ahk_id " hwnd)
    processName := WinGetProcessName("ahk_id " hwnd)

    if className ~= "i)^(Progman|WorkerW|Shell_TrayWnd)$" {
        return 0
    }

    if processName ~= "i)^(explorer\.exe|zebar\.exe|glazewm\.exe|AutoHotkey64\.exe|AutoHotkey\.exe)$" && className ~= "i)^(Shell_TrayWnd|NotifyIconOverflowWindow)$" {
        return 0
    }

    return hwnd
}
