;{ AHKScripts
; Fanatic Guru
; 2014 03 31
;
; FUNCTION that will find the path and file name of all AHK scripts running.
;
;---------------------------------------------------------------------------------
;
; Method:
;   AHKScripts(ByRef Array)
;
; Parameters:
;   1) {Array} variable in which to store AHK script path data array
;
; Returns:
;   String containing the complete path of all AHK scripts running
;   One path per line of string, delimiter = `n
;
; ByRef:
;   Populates {Array} passed as parameter with AHK script path data
;     {Array}.Path
;     {Array}.Name
;     {Array}.Dir
;     {Array}.Ext
;     {Array}.Title
;     {Array}.hWnd
;
; Example Code:
/*
	MsgBox % AHKScripts(Script_List)
	for index, element in Script_List
		MsgBox % "#:`t" index "`nPath:`t" element.Path "`nName:`t" element.Name "`nDir:`t" element.Dir "`nExt:`t" element.Ext "`nTitle:`t" element.Title "`nhWnd:`t" element.hWnd
	return
*/

AHKScripts(ByRef Array) {
	DetectHiddenWindows, % (Setting_A_DetectHiddenWindows := A_DetectHiddenWindows) ? "On" :
	WinGet, AHK_Windows, List, ahk_class AutoHotkey
	Array := {}
	list := ""
	Loop %AHK_Windows%
	{
		hWnd := AHK_Windows%A_Index%
		WinGetTitle, Win_Name, ahk_id %hWnd%
		File_Path := RegExReplace(Win_Name, "^(.*) - AutoHotkey v[0-9\.]+$", "$1")
		SplitPath, File_Path, File_Name, File_Dir, File_Ext, File_Title
		Array[A_Index,"Path"] := File_Path
		Array[A_Index,"Name"] := File_Name
		Array[A_Index,"Dir"] := File_Dir
		Array[A_Index,"Ext"] := File_Ext
		Array[A_Index,"Title"] := File_Title
		Array[A_Index,"hWnd"] := hWnd
		list .= File_Path "`n"
		Loop, Read, list_conffiles_ref.ahk
		{
			ln := A_LoopReadLine
			list .= A_LoopReadLine "`n"
		}
	}
	DetectHiddenWindows, %Setting_A_DetectHiddenWindows%
	return Trim(list, " `n")
}
