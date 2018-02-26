; Disables alt-tab when using x2go
; It instead sends alt-end. I never use alt-end, but in ubuntu (mate at least) you can use the dconf editor (org/gnome/desktop/wm/keybindings) to add '<Alt>End' to the hotkeys for the app switcher.
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#IfWinActive VcXsrv Server - Display busch01:0.0
!Tab::!End			; Disable Alt Tab.
#IfWinActive