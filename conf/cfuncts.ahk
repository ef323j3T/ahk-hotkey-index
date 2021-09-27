
Send_AltLeft() {
	SendInput, !{Left}
}
Send_AltRight() {
	SendInput, !{Right}
}
Send_AltUp() {
	SendInput, !{Up}
}
Send_AltDown() {
	SendInput, !{Down}
}



TaskView() {
	Send, #{tab}
}
Send_PageUp() {
	SendInput ^{PgUp}
}
Send_PageDown() {
	SendInput ^{PgDn}
}



Explorer_FocusLocBar() {
	SendInput, !d ; Focus Location bar (explorer.exe)
}
Explorer_OpenCmdHere() {
	SendInput, !dcmd{Enter} ; Open Command Window here (explorer.exe)
}



Script_Reload() {
	Reload
}
Script_Pause() {
	Pause
}
Script_Suspend() {
	Suspend
}

Script_KillAllOther() {
	DetectHiddenWindows, On
	WinGet, List, List, ahk_class AutoHotkey
	Loop %List%
	{
		WinGet, PID, PID, % "ahk_id " List%A_Index%
		If ( PID <> DllCall("GetCurrentProcessId") )
			PostMessage,0x111,65405,0,, % "ahk_id " List%A_Index%
	}
}
