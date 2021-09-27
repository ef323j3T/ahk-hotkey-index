

; basic hotkeys to test keyindex and keyindex run function

<!r::Script_Reload() ; reload script (global)
<^<!p::Script_Pause() ; pause script (global)
<^<!s::Script_Suspend()	; suspend script (global)
<#<+>!x::Script_KillAllOther() ; Kill all other scripts (global)

<^Tab::TaskView() ; Task view (global)

~LWin::	; disable left windows key (global) (B)
	Return
~CapsLock up::	; make sure capslock off after key press (global) (B)
	SetCapsLockState, Off

#IfWinActive ahk_exe explorer.exe

<^o::Send_AltLeft() ; Go back (explorer.exe)
<^i::Send_AltRight() ; Go forward (explorer.exe)
<^u::Send_AltUp() ; Go up (explorer.exe)
<^WheelUp::Send_AltLeft() ; Go back (explorer.exe)
<^WheelDown::Send_AltDown() ; Go forward (explorer.exe)
<^l::Explorer_FocusLocBar() ; Focus Location bar (explorer.exe)
<^<!t::Explorer_OpenCmdHere() ; Open Command Window here (explorer.exe)

#IfWinActive
