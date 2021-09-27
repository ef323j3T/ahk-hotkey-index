
;----------------------------------------------------------------------
; Template for functional keymaps:
;	<!r::Script_Reload() ; reload script (global)	   - commands need to be converted into functions to run, parameters mostly ok
;	~LWin::	; disable left windows key (global) (B)	- options tag (not required) B = behaviour/system keys, will not be indexed; D = default, etc
;	F1::ahk_help() ; open ahk help (atom.exe)				- hks need process tag
;----------------------------------------------------------------------
; Listview GUI actions:
; 		lbutton | enter 				   -   run select item
; 		Shift+Lbutton / shift+Enter 	-	 open key conf in editor
;		RightClick							-	 msgbox info on all 8 hidden columns
;----------------------------------------------------------------------
; lv visible columns:
; C1: index number, C2: hotkey, C3: key value , C4 (process)
; Lv hidden columns:
;C5: function, C6:function parameters, C7:file path, C8:options
;----------------------------------------------------------------------
; Global variables:
;     AllKeys     - found hotkeys
;     DisplayKeys - windows in listbox
;     search      - the current search string
;     lastSearch  - previous search string
;     keyindex_id - the window ID of the indexer window
;     compact     - true when compact listview is enabled
;----------------------------------------------------------------------
#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
;#Persistent
#SingleInstance force ; Ensures that only the last executed instance of script is running
; #Warn  ; Enable warnings to assist with detecting common errors.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SetBatchLines -1 ; faster execution
;SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
global keyindex_id
;----------------------------------------------------------------------
#Include %A_ScriptDir%\lib\AccV2.ahk
#Include %A_ScriptDir%\lib\ObjRegisterActive.ahk
#Include %A_ScriptDir%\lib\Sift.ahk
#Include %A_ScriptDir%\lib\classGlobalContainer.ahk
#Include %A_ScriptDir%\lib\StrDiff.ahk
#Include %A_ScriptDir%\lib\objectSort.ahk
#Include %A_ScriptDir%\lib\AHKScripts.ahk
#Include %A_ScriptDir%\lib\TCMatch.ahk
#Include %A_ScriptDir%\lib\classGlobalContainer.ahk
;----------------------------------------------------------------------

Files_Excluded	:= "iswitchr|HotKey_Help" ;dont search these file for hotkeys // File Names with Out Ext Seperated by | i.e. Files_Excluded 	:= "Test|Debugging" -
Hot_Excluded := " " ; Excluded keys
options_filters := ["B"] ; Keys with these options are excluded

;----------------------------------------------------------------------


;Menu, Tray, NoIcon
;----------------------------------------------------------------------
global compact := true ; Use small icons in the listview
; A bit of a hack, but this 'hides' the scorlls bars, rather the listview is
; sized out of bounds, you'll still be able to use the scroll wheel or arrows
; but when resizing the window you can't use the left edge of the window, just
; the top and bottom right.
global hideScrollBars := true
hideWhenFocusLost := true ; Hides the UI when focus is lost!
; Uses tcmatch.dll included with QuickSearch eXtended by Samuel Plentz
; https://www.ghisler.ch/board/viewtopic.php?t=22592
; a bit slower, but supports Regex, Simularity, Srch & PinYin; use Winkey+/ to toggle it on/off
; while iswitch is running, included in lib folder, no license info that I could find
; see readme in lib folder for details, use the included tcmatch.ahk to change settings
; By default, for different search modes, start the string with:
;   ? - for regex
;   * - for srch
;   < - for simularity
useTCMatch := false
activateOnlyMatch := false ; Activate if it's the only match
; Set this to true to update the list every time the search is
; updated. This is usually not necessary and creates additional overhead, so
; it is disabled by default.
global refreshEveryKeystroke := false
; When true, filtered matches are scored and the best matches are presented
; first. This helps account for simple spelling mistakes such as transposed
; letters e.g. googel, vritualbox. When false, title matches are filtered and
; presented in the order given by Windows.
global scoreMatches := true
; Split search string on spaces and use each term as an additional
; filter expression.
;
; For example, you are working on an AHK script:
;  - There are two Explorer windows open to ~/scripts and ~/scripts-old.
;  - Two Vim instances editing scripts in each one of those folders.
;  - A browser window open that mentions scripts in the title
;
; This is amongst all the other stuff going on. You bring up iswitchw and
; begin typing 'scrip'. Now, we have several best matches filtered.  But I
; want the Vim windows only. Now I might be able to make a more unique match by
; adding the extension of the file open in Vim: 'scripahk'. Pretty good, but
; really the first thought was process name -- Vim. By breaking on space, we
; can first filter the list for matches on 'scrip' for 'script' and then,
; 'vim' in order to match by Vim amongst the remaining windows.
global useMultipleTerms := true
;----------------------------------------------------------------------
global Case := 0
global Options := "UC"
;----------------------------------------------------------------------

;----------------------------------------------------------------------
global Set_Hotkey_Mod_Delimiter := "+" ; Delimiter Character to Display Between Hotkey Modifiers
global Parse_Delimiter := "`n" ; Parse Delimiter and OmitChar.  Sometimes changing these can give better results.
global Parse_OmitChar := "`r"
;----------------------------------------------------------------------
global Help := {} ; - all found keys - ({ "HK": "", "HKValue": "", "HKFunc": "", "HKFuncPMS": "", "HKProc": "", "HKOptions": "", "HKFP": "", "HKLine": "" })
global AllKeys := {} ; all found, parsed - ({ "HK": "", "HKValue": "", "HKFunc": "", "HKFuncPMS": "", "HKProc": "", "HKOptions": "", "HKFP": "", "HKLine": "", "HKRaw": HKRaw })
global DisplayKeys := {} ; keys in listbox
global Scripts_Scan := {} ; AHK Scripts to Scan
global Scripts_Include := {} ; Scripts added with #Include
fileList := []
Setting_AutoTrim := A_AutoTrim
AutoTrim, On
Setting_WorkingDir := A_WorkingDir
;----------------------------------------------------------------------
; Load saved position from settings.ini
IniRead, x, settings.ini, position, x
IniRead, y, settings.ini, position, y
IniRead, w, settings.ini, position, w
IniRead, h, settings.ini, position, h
If (!x || !y || !w || !h || x = "ERROR" || y = "ERROR" || w = "ERROR" || h = "ERROR")
  x := y := w := h := 0 ; zero out of any values are invalid
;----------------------------------------------------------------------
OnMessage(0x201, "WM_LBUTTONDOWN") ; Allows clicking and dragging the window
OnMessage(0x84, "WM_NCHITTEST") ;These remove the borders, while allowing the window to be resizable
OnMessage(0x83, "WM_NCCALCSIZE") ;https://autohotkey.com/board/topic/23969-resizable-window-border/#entry155480
OnMessage(0x86, "WM_NCACTIVATE")
;----------------------------------------------------------------------
C1:=.065 , C2:=.25 , C3:=.45, C4:=.15 , C5:=0, C6:=0, C7:=0, C8:=0 ; column sizes
;----------------------------------------------------------------------
Gui, +LastFound +AlwaysOnTop +Caption +ToolWindow +Resize -DPIScale +MinSize220x127 +Hwndkeyindex_id
Gui, Color, black, 191919
WinSet, Transparent, 225
Gui, Margin, 8, 10
Gui, Font, s14 cEEE8D5, Segoe MDL2 Assets
Gui, Add, Text,     xm+5 ym+3, % Chr(0xE721)
Gui, Font, s10 cEEE8D5, Segoe UI
Gui Add, Edit, vInput w620 h25  x+10 ym gSearchChange vsearch, E0x200,
Gui, Add, ListView, y+8 w490 h500 -VScroll -HScroll -Hdr -Multi Count10 AltSubmit vlist gListViewClick +LV0x10000 +LV0x4000 -E0x200, index|proc|HK|value|func|funcpms|options|filepath
LV_Delete()
if !w , w := 620
LV_Modify(1, "Select")
Gui, Show, % x ? "x" x " y" y " w" w " h" h : "" , Key Index
WinHide, ahk_id %keyindex_id%
LV_ModifyCol(1,(w * C1)) , LV_ModifyCol(2,(w * C2)) , LV_ModifyCol(3,(w * C3)) , LV_ModifyCol(4,(w * C4)), LV_ModifyCol(5,(w * C5)), LV_ModifyCol(6,(w * C6)), LV_ModifyCol(7,(w * C7)), LV_ModifyCol(8,(w * C8))
;----------------------------------------------------------------------
; Add hotkeys for number row and pad, to focus corresponding item number in the list
numkey := [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, "Numpad1", "Numpad2", "Numpad3", "Numpad4", "Numpad5", "Numpad6", "Numpad7", "Numpad8", "Numpad9", "Numpad0"]
for i, e in numkey {
	num := StrReplace(e, "Numpad")
	KeyFunc := Func("RunSelect").Bind(num = 0 ? 10 : num)
	Hotkey, IfWinActive, % "ahk_id" keyindex_id
	Hotkey, % "!" e, % KeyFunc
}
; Define hotstrings for selecting rows, by typing the number with a space after
Loop 300 {
	KeyFunc := Func("RunSelect").Bind(A_Index)
	Hotkey, IfWinActive, % "ahk_id" keyindex_id
	Hotstring(":X:" A_Index , KeyFunc)
}
Return
;----------------------------------------------------------------------
; Win+space to activate.
#space::	; open KeyIndex gui (global)
	WinGet, ahk_exe, ProcessName, A
	If WinActive("ahk_class Windows.UI.Core.CoreWindow") ; clear the search/start menu if it's open, otherwise it keeps stealing focus	; "ahk_class AutoHotkeyGUI"?
		Send, {esc}
	LV_ModifyCol(1,(w * C1)) , LV_ModifyCol(2,(w * C2)) , LV_ModifyCol(3,(w * C3)) , LV_ModifyCol(4,(w * C4)), LV_ModifyCol(5,(w * C5)), LV_ModifyCol(6,(w * C6)), LV_ModifyCol(7,(w * C7)), LV_ModifyCol(8,(w * C8))
	search := lastSearch := ""
	AllKeys := Object()
	GuiControl, , Edit1
	WinShow, ahk_id %keyindex_id%
	WinActivate, ahk_id %keyindex_id%
	WinGetPos, , , w, h, ahk_id %keyindex_id%
	WinSet, Region , 0-0 w%w% h%h% R15-15, ahk_id %keyindex_id%
	WinSet, AlwaysOnTop, On, ahk_id %keyindex_id%
	ControlFocus, Edit1, ahk_id %keyindex_id%
	If hideWhenFocusLost
		SetTimer, HideTimer, 10
Return

; #^/::
; 	useTCMatch := !useTCMatch
; 	ToolTip, % "TC Match: " (useTCMatch ? "On" : "Off")
; 	SetTimer, tooltipOff, -2000
; Return

tooltipOff:
  ToolTip
Return
;----------------------------------------------------------------------
#If WinActive("ahk_id" keyindex_id)
	Enter::       ;Activate
	+Enter::	  ;Open selected in Editor
	Escape::      ;Close window
	;#Space::	  ;enabled =#Space toggles window open/closed, if disabled clears search bar when open
	^w::          ;Clear text
	^b::          ;Backspace
	^Home::       ;Jump to top
	^h::        ;Jump up 4 rows
	Up::          ;Previous row
	^j::          ;Previous row
	+Tab::        ;Previous row
	Down::        ;Next row
	Tab::         ;Next Row
	^k::          ;Next row
	^l::        ;Jump down 4 rows
	^End::        ;Jump to bottom
	^Tab::        ;Quit ;
	!F4::         ;Quit
	#q::          ;Quit
	~Delete::	  ;
	~Backspace::  ;
		SetKeyDelay, -1
		Switch A_ThisHotkey {
			Case "Enter":   	RunSelect()
			Case "+Enter":  	OpenInEditor()
			Case "LButton": 		RunSelect()
		;	Case "#Space":      WinHide, ahk_id %keyindex_id% ; disabled = when already open clears search bar
			Case "Escape":      WinHide, ahk_id %keyindex_id%
			Case "!F4":         Quit()
			Case "#Q":			Quit()
			Case "^Home":       LV_Modify(1, "Select Focus Vis")
			Case "^End":        LV_Modify(LV_GetCount(), "Select Focus Vis")
			Case "^b":          ControlSend, Edit1, {Backspace}, ahk_id %keyindex_id%
			Case "~Delete", "~Backspace", "^Backspace", "^w":
			If ( (DisplayKeys.MaxIndex() < 1 && LV_GetCount() > 1) || LV_GetCount() = 1)
				GuiControl, , Edit1,
			Else If (A_ThisHotkey = "^Backspace" || A_ThisHotkey = "^w")
				ControlSend, Edit1, ^+{left}{Backspace}, ahk_id %keyindex_id%
			Case "Tab", "+Tab", "Up", "Down", "PgUp", "PgDn", "^k" , "^j", "^l", "^h":
				page := InStr(A_ThisHotkey,"Pg") ||  InStr(A_ThisHotkey,"l") || InStr(A_ThisHotkey,"^h")
				row := LV_GetNext()
				jump := page ? 4 : 1
				If (row = 0)
					row := 1
				row := GetKeyState("Shift") || InStr(A_ThisHotkey,"Up") || InStr(A_ThisHotkey,"^j") || InStr(A_ThisHotkey,"^h") ? row - jump : row + jump
				If (row > LV_GetCount())
					row := page ? LV_GetCount() : 1
				Else If (row < 1)
					row := page ? 1 : LV_GetCount()
				LV_Modify(row, "Select Focus Vis")
		}
Return
;----------------------------------------------------------------------
GuiSize: ; Resizes the search field and list to the GUI width
	GuiControl, Move, list, % "w" (hideScrollBars ? A_GuiWidth + 20 : A_GuiWidth - 20) " h" A_GuiHeight - 50
	GuiControl, Move, Edit1, % "w" A_GuiWidth - 52
	LV_ModifyCol(1,(w * C1)) , LV_ModifyCol(2,(w * C2)) , LV_ModifyCol(3,(w * C3)) , LV_ModifyCol(4,(w * C4)), LV_ModifyCol(5,(w * C5)), LV_ModifyCol(6,(w * C6)), LV_ModifyCol(7,(w * C7)), LV_ModifyCol(8,(w * C8))
	WinGetPos, x, y, w, h, % "ahk_id" keyindex_id
	WinSet, Region , 0-0 w%w% h%h% R15-15, % "ahk_id" keyindex_id  ;Sets window region to round off corners
	SetTimer, SaveTimer, -2000
Return
;----------------------------------------------------------------------
SaveTimer:
	WinGetPos, x, y, w, h, % "ahk_id" keyindex_id
	; IniWrite, % x, settings.ini, position, x
	; IniWrite, % y, settings.ini, position, y
	; IniWrite, % w - 14, settings.ini, position, w ; manual adjustment of saved w/h. Gui, Show always
	; IniWrite, % h - 14, settings.ini, position, h ; makes it 14px larger when specifying coords.
Return

HideTimer: ; Hides the UI if it loses focus
	If !WinActive("ahk_id" keyindex_id) {
		WinHide, ahk_id %keyindex_id%
		SetTimer, HideTimer, Off
	}
Return
;----------------------------------------------------------------------
SearchChange: ; Runs whenever Edit control is updated
	Settimer, Refresh, -1
Return

Refresh:
	if (LV_GetCount() = 1) {
		Gui, Font, c90ee90fj
		GuiControl, Font, Edit1
	}
	Gui, Submit, NoHide
	StartTime := A_TickCount
	If useTCMatch
		RefreshList()
	Else
		RefreshListOld()
	ElapsedTime := A_TickCount - StartTime
	If (LV_GetCount() > 1) {
		Gui, Font, % LV_GetCount() > 1 && DisplayKeys.MaxIndex() < 1 ? "cff2626" : "cEEE8D5"
		GuiControl, Font, Edit1
	} Else if (LV_GetCount() = 1) {
		Gui, Font, c90ee90fj
		GuiControl, Font, Edit1
	}
return
;----------------------------------------------------------------------
ListViewClick: ; Handle mouse click events on the listview
	if (A_GuiControlEvent = "Normal") ;  ; lbutton to run
	; shift+lbutton open in editor
	; rbutton to get info on all hiddne columns

		if GetKeyState("Shift")
			OpenInEditor()
		else
			RunSelect()
	if (A_GuiControlEvent = "DoubleClick")
		if GetKeyState("Shift")
			OpenInEditor()
		else
			RunSelect()
	if (A_GuiControlEvent = "RightClick")
		Run_Show_Info() ; display info on all columns
return
;----------------------------------------------------------------------
; RunSelect(rowNum := "") {
	; 	If !rowNum
	; 		rowNum:= LV_GetNext(0)
	; 	If (rowNum > LV_GetCount())
	; 		return
	; 	LV_GetText(C5,A_EventInfo,5)
	; 	LV_GetText(C6,A_EventInfo,6)
	; 	WinHide, ahk_id %keyindex_id%
	; 	myContainer := new GlobalContainer("MyStorage")
	; 	myContainer.arr := [C5, C6]
	; 	Return
	; }
RunSelect() {
	If !rowNum
		rowNum:= LV_GetNext(0)
	If (rowNum > LV_GetCount())
		return
	LV_GetText(C5,A_EventInfo,5)
	LV_GetText(C6,A_EventInfo,6)
	LV_GetText(C5, rowNum, 5)
	LV_GetText(C6, rowNum, 6)
	WinHide, ahk_id %keyindex_id%
	myContainer := new GlobalContainer("MyStorage")
	myContainer.arr := [C5, C6]
	Return
}
OpenInEditor() {
	If !rowNum
		rowNum:= LV_GetNext(0)
	If (rowNum > LV_GetCount())
		return
	LV_GetText(HKFP, rowNum, 7)
	WinHide, ahk_id %keyindex_id%
	Run, C:\Users\Emily\AppData\Local\atom\atom.exe %HKFP%
}
Run_Show_Info() {
	LV_GetText(C1,A_EventInfo,1)
	LV_GetText(C2,A_EventInfo,2)
	LV_GetText(C3,A_EventInfo,3)
	LV_GetText(C4,A_EventInfo,4)
	LV_GetText(C5,A_EventInfo,5)
	LV_GetText(C6,A_EventInfo,6)
	LV_GetText(C7,A_EventInfo,7)
	LV_GetText(C8,A_EventInfo,8)
	MsgBox, % "index:" C1 "`nhotkey:" C2 "`nvalue:" C3 "`nraw hotkey:" C4 "`nfunction:" C5 "`function_params:" C6 "`nfilepath:" C7 "`nprocess:" C8
}
;----------------------------------------------------------------------
RefreshList() {
	global AllKeys, DisplayKeys, scoreMatches
	global search, lastSearch, refreshEveryKeystroke
	global C1, C2, C3, C4, C5, C6, C7, C8
	if (search ~= "^\d+")
		return
	DisplayKeys := []
	toRemove := ""
	If (!search || refreshEveryKeystroke || StrLen(search) < StrLen(lastSearch)) {
		AllKeys := GetAllKeys()
	}
	lastSearch := search
	for i, e in AllKeys {
		str := e.HK A_Space e.HKValue A_Space e.HKFunc A_Space e.HKProc A_Space e.title
		if !search || TCMatch(str,search) {
			If scoreMatches
				e.score := FuzzySearch(search, str)
			DisplayKeys.Push(e)
		} else {
			toRemove .= i ","
		}
	}
	If scoreMatches
		DisplayKeys := objectSort(DisplayKeys, "score")
	OutputDebug, % "AllKeys count: " AllKeys.MaxIndex() " | DisplayKeys count: " DisplayKeys.MaxIndex() "`n"
	DrawListView(DisplayKeys)
	LV_ModifyCol(1,(w * C1)) , LV_ModifyCol(2,(w * C2)) , LV_ModifyCol(3,(w * C3)) , LV_ModifyCol(4,(w * C4)), LV_ModifyCol(5,(w * C5)), LV_ModifyCol(6,(w * C6)), LV_ModifyCol(7,(w * C7)), LV_ModifyCol(8,(w * C8))
	for i, e in StrSplit(toRemove,",")
		AllKeys.Delete(e)
}

RefreshListOld() {
	global AllKeys, DisplayKeys
	global search, lastSearch, refreshEveryKeystroke
	if (search ~= "^\d+")
		return
	uninitialized := (AllKeys.MinIndex() = "")

	if (uninitialized || refreshEveryKeystroke)
		AllKeys := GetAllKeys()
	currentSearch := Trim(search)
	if ((currentSearch == lastSearch) && !uninitialized) {
		return
	}
	useExisting := (StrLen(currentSearch) > StrLen(lastSearch))
	lastSearch := currentSearch
	DisplayKeys := FilterList(useExisting ? DisplayKeys : AllKeys, currentSearch)

	DrawListView(DisplayKeys) ; Refresh the list according to the search criteria
}

FilterList(list, criteria) {
	global scoreMatches, useMultipleTerms
	filteredList := Object(), expressions := Object()
	lastTermInSearch := criteria, doScore := scoreMatches

	; If useMultipleTerms, do multiple passes with filter expressions
	if (useMultipleTerms) {
		StringSplit, searchTerms, criteria, %A_space%
		Loop, %searchTerms0%
		{
			term := searchTerms%A_index%
			lastTermInSearch := term

			expr := BuildFilterExpression(term)
			expressions.Push(expr)
		}
		} else if (criteria <> "") {
			expr := BuildFilterExpression(criteria)
			expressions[0] := expr
		}
		atNext:
		For idx, hkey in list
		{
			; if there is a search string
			if criteria <>
			{

				HK := hkey.HK
				HKValue := hkey.HKValue
				HKProc := hkey.HKProc
				; don't add the windows not matching the search string
				keyvalprocandfunc = %HK% %HKValue% %HKProc%

				For idx, expr in expressions
				{
					if RegExMatch(keyvalprocandfunc, expr) = 0
					continue atNext
				}
			}

			doScore := scoreMatches && (criteria <> "") && (lastTermInSearch <> "")
			hkey["score"] := doScore ? FuzzySearch(lastTermInSearch, keyvalprocandfunc) : 0

			filteredList.Push(hkey)
		}
		return (doScore ? SortByScore(filteredList) : filteredList) ; Filter list with given search criteria
}

DrawListView(DisplayKeys) {
	global AllKeys
	global keyindex_id
	global C1, C2, C3, C4, C5, C6, C7, C8
	displaykeyCount := DisplayKeys.MaxIndex()
	If !displaykeyCount
	return
	LV_Delete()
	for index, obj in DisplayKeys
	{
		for k, v in obj
		%k% := v
		if HKLine and if HKFP and if HK and if HKValue and if HKFunc and if HKProc and if HKOptions
		LV_Add("",index,HK,HKValue,HKProc,HKFunc,HKFuncPMS,HKFP,HKOptions)
	}
	LV_ModifyCol(1,(w * C1)) , LV_ModifyCol(2,(w * C2)) , LV_ModifyCol(3,(w * C3)) , LV_ModifyCol(4,(w * C4)), LV_ModifyCol(5,(w * C5)), LV_ModifyCol(6,(w * C6)), LV_ModifyCol(7,(w * C7)), LV_ModifyCol(8,(w * C8)) ; Add list to listview
}

GetAllKeys() { ; Parse running scripts + all #Include files for hotkeys
	global Set_Hotkey_Mod_Delimiter, Parse_Delimiter, Parse_OmitChar
	global Help, AllKeys, DisplayKeys
	global Files_Excluded, Hot_Excluded

	global Scripts_List := AHKScripts(Scripts)	; Get Path of all AHK Scripts
	global Scripts_Scan := Scripts

	R:
	Include_Found := false
	for index, Script in Scripts_Scan	{
		File_Path := Script.Path
		SplitPath, File_Path, File_Name, File_Dir, File_Ext, File_Title
		if RegExMatch(Files_Excluded,"i)(^|\|)" File_Title "($|\|)")
		continue
		Help[File_Title,"Type"] := "AHK"
		Script_File := ""
		FileRead, Script_File, %File_Path%	;  Read AHK Script File into String
		if !Script_File
		continue
		Script_File := RegExReplace(Script_File, "ms`a)^\s*/\*.*?^\s*\*/\s*|^\s*\(.*?^\s*\)\s*")	; Removes /* ... */ and ( ... ) Blocks

		Loop, Parse, Script_File, %Parse_Delimiter%, %Parse_OmitChar%	; Parse Each Line of Script File
		{
		File_Line := A_LoopField      ; RegEx to Identify Hotkey Command Lines:V
		if (RegExMatch(File_Line, "i)^\s*hotkey,(.*?),(.*)", Match) and Set_ShowHotkey)	; Check if Line Contains Hotkey Command
		{
			if Set_VarHotkey
				if RegExMatch(Match1,"%.*%")
					Match1 := HotkeyVariable(Script.Path,Match1)
			File_Line := Match1 ":: " Match2
			Hotkey_Command := true
		}
		else
			Hotkey_Command := false
			if RegExMatch(File_Line,"::")	; Simple check for Possible Hotkey or Hotstring (for speed)
			{
			if RegExMatch(File_Line,"^\s*:[0-9\*\?BbCcKkOoPpRrSsIiEeZz]*?:(.*?)::(\s*)(`;?)(.*)",Match)				; Complex Check if Line Contains Hotstring
				{
					Line_Hot := "<HS>  " Match1
					Line_Help := (Match3 ? Trim(Match4) : "= " Match2 Match4)
						if (Help[File_Title,"Hot",Line_Hot,"Count"] = "")
							Count := 1
						else
							Count += Help[File_Title,"Hot",Line_Hot,"Count"]
						Help[File_Title,"Hot",Line_Hot,"Count"] := Count
						Help[File_Title,"Hot",Line_Hot,Count] := Line_Help

				}
			else if RegExMatch(File_Line, "Umi)^\s*[\Q#!^+<>*~$\E]*((LButton|RButton|MButton|XButton1|XButton2|WheelDown|WheelUp|WheelLeft|WheelRight|CapsLock|Space|Tab|Enter|Return|Escape|Esc|Backspace|BS|ScrollLock|Delete|Del|Insert|Ins|Home|End|PgUp|PgDn|Up|Down|Left|Right|NumLock|Numpad0|Numpad1|Numpad2|Numpad3|Numpad4|Numpad5|Numpad6|Numpad7|Numpad8|Numpad9|NumpadDot|NumpadDiv|NumpadMult|NumpadAdd|NumpadSub|NumpadEnter|NumpadIns|NumpadEnd|NumpadDown|NumpadPgDn|NumpadLeft|NumpadClear|NumpadRight|NumpadHome|NumpadUp|NumpadPgUp|NumpadDel|F1|F2|F3|F4|F5|F6|F7|F8|F9|F10|F11|F12|F13|F14|F15|F16|F17|F18|F19|F20|F21|F22|F23|F24|LWin|RWin|Control|Ctrl|Alt|Shift|LControl|LCtrl|RControl|RCtrl|LShift|RShift|LAlt|RAlt|Browser_Back|Browser_Forward|Browser_Refresh|Browser_Stop|Browser_Search|Browser_Favorites|Browser_Home|Volume_Mute|Volume_Down|Volume_Up|Media_Next|Media_Prev|Media_Stop|Media_Play_Pause|Launch_Mail|Launch_Media|Launch_App1|Launch_App2|AppsKey|PrintScreen|CtrlBreak|Pause|Break|Help|Sleep|sc\d{1,3}|vk\d{1,2}|\S)(?<!;)|```;)(\s+&\s+((LButton|RButton|MButton|XButton1|XButton2|WheelDown|WheelUp|WheelLeft|WheelRight|CapsLock|Space|Tab|Enter|Return|Escape|Esc|Backspace|BS|ScrollLock|Delete|Del|Insert|Ins|Home|End|PgUp|PgDn|Up|Down|Left|Right|NumLock|Numpad0|Numpad1|Numpad2|Numpad3|Numpad4|Numpad5|Numpad6|Numpad7|Numpad8|Numpad9|NumpadDot|NumpadDiv|NumpadMult|NumpadAdd|NumpadSub|NumpadEnter|NumpadIns|NumpadEnd|NumpadDown|NumpadPgDn|NumpadLeft|NumpadClear|NumpadRight|NumpadHome|NumpadUp|NumpadPgUp|NumpadDel|F1|F2|F3|F4|F5|F6|F7|F8|F9|F10|F11|F12|F13|F14|F15|F16|F17|F18|F19|F20|F21|F22|F23|F24|LWin|RWin|Control|Ctrl|Alt|Shift|LControl|LCtrl|RControl|RCtrl|LShift|RShift|LAlt|RAlt|Browser_Back|Browser_Forward|Browser_Refresh|Browser_Stop|Browser_Search|Browser_Favorites|Browser_Home|Volume_Mute|Volume_Down|Volume_Up|Media_Next|Media_Prev|Media_Stop|Media_Play_Pause|Launch_Mail|Launch_Media|Launch_App1|Launch_App2|AppsKey|PrintScreen|CtrlBreak|Pause|Break|Help|Sleep|sc\d{1,3}|vk\d{1,2}|\S)(?<!;)|```;))?(\s+Up)?::") ; Complex Check if Line Contains Hotkey
			{
				Pos_Hotkey := RegExMatch(File_Line,"(.*?[:]?)::",Match)
				Match1 := Trim(Match1)
				if RegExMatch(Hot_Excluded,"i)(^|\|)\Q" Match1 "\E($|\|)")	; Check for Excluded Short Hotkey Name
				continue
				if !RegExMatch(Match1,"(Shift|Alt|Ctrl|Win)")
				{
				StringReplace, Match1, Match1, +, Shift%Set_Hotkey_Mod_Delimiter%
				StringReplace, Match1, Match1, <^>!, AltGr%Set_Hotkey_Mod_Delimiter%
				StringReplace, Match1, Match1, <, L, All
				StringReplace, Match1, Match1, >, R, All
				StringReplace, Match1, Match1, !, Alt%Set_Hotkey_Mod_Delimiter%
				StringReplace, Match1, Match1, ^, Ctrl%Set_Hotkey_Mod_Delimiter%
				StringReplace, Match1, Match1, #, Win%Set_Hotkey_Mod_Delimiter%
				}
				StringReplace, Match1, Match1, ```;, `;
				StringReplace, Match1, Match1, % A_Space "&" A_Space, % "+", All
				Line_Hot := Match1
				Line_Path := File_Name
				Pos := RegExMatch(File_Line,"(?<=::)(.*?);(.*)",Match)
				p := RegexMatch(File_Line, "(?im)(\w*)\((.*(?=\)\s?;))", Part)
				Line_Func := Part1
				Line_FPs := Part2
				arr := StrSplit(Match2,"(")
				Line_Help := arr[1]
				Line_Proc := arr[2]
				Line_Opt := arr[3]
				StringReplace, Line_Proc, Line_Proc, ), ,
				StringReplace, Line_Proc, Line_Proc, (, ,
				StringReplace, Line_Opt, Line_Opt, ), ,
				StringReplace, Line_Opt, Line_Opt, (, ,
				if (Line_Opt = "" )
				Line_Opt := "D"
				Help.Push({ "HK": Line_Hot, "HKValue": Line_Help, "HKFunc": Line_Func, "HKFuncPMS": Line_FPs, "HKProc": Line_Proc, "HKOptions": Line_Opt, "HKFP": File_Path, "HKLine": File_Line })

				if (Help[File_Title,"Hot",Line_Hot,"Count"] = "")
				Count := 1
				else
				Count += Help[File_Title,"Hot",Line_Hot,"Count"]
				Help[File_Title,"Hot",Line_Hot,"Count"] := Count
				Help[File_Title,"Hot",Line_Hot,Count] := Line_Help
			}
			}
			if RegExMatch(File_Line, "mi`a)^\s*#include(?:again)?(?:\s+|\s*,\s*)(?:\*i[ `t]?)?([^;\v]+[^\s;\v])", Match)	; Check for #Include
			{
				StringReplace, Match1, Match1, `%A_ScriptDir`%, %File_Dir%
				StringReplace, Match1, Match1, `%A_AppData`%, %A_AppData%
				StringReplace, Match1, Match1, `%A_AppDataCommon`%, %A_AppDataCommon%
				StringReplace, Match1, Match1,```;,;, All
				if InStr(FileExist(Match1), "D")
				{
					SetWorkingDir, %Match1%
					continue
				}
				Match1 := Get_Full_Path(Match1)
			Include_Repeat := false
			for k, val in Scripts_Include
				if (val.Path = Match1)
				Include_Repeat := true
			if !Include_Repeat
			{
				Scripts_Include.Push({"Path":Match1})
				Include_Found := true
			}
			}
		} ; Loop Through AHK Script Files
	}
	if Include_Found {
		Scripts_Scan := Scripts_Include
		goto R
	}

	added :=
	for index, obj in Help {
		for k, v in obj
			%k% := v
		if HKLine and if HKFP and if HK and if HKValue and if HKFunc and if HKProc and if HKOptions ; continue only if all values are filled (at end of loop + skip any missing)
		{
			if HKOptions != "B"	{ ; check if marked for skip B = behaaviour/system keybinding i.e disable caps lock, double click emptyspace explorer etc /// (D = default)
				string1 := RegExReplace(HKLine,"[^\w]","") ; prevent dups
				if added ~= string1
					continue
				Else {
					pos := RegExMatch(HKLine,"(.*(?=::))",Match)
					HKRaw := Match
					AllKeys.Push({ "HK": HK, "HKValue": HKValue, "HKFunc": HKFunc, "HKFuncPMS": HKFuncPMS, "HKProc": HKProc, "HKOptions": HKOptions, "HKFP": HKFP, "HKLine": HKLine, "HKRaw": HKRaw })
					added .= string1
				}
		}
	}
	Return AllKeys
}
;----------------------------------------------------------------------
Quit() {
  global keyindex_id
  Gosub, SaveTimer
  ExitApp
}
;----------------------------------------------------------------------
HotkeyVariable(Script,Variable) {
	static
	Var := Trim(Variable," %")
	If !Script_List
		Script_List := {}
	if !Script_List[Script]
	{
		DetectHiddenWindows, % (Setting_A_DetectHiddenWindows := A_DetectHiddenWindows) ? "On" :
		SetTitleMatchMode 2
		WinMove, %Script%,,A_ScreenWidth, A_ScreenHeight
		PostMessage, 0x111, 65407, , , %Script%
		ControlGetText, Text, Edit1, %Script%
		WinHide, %Script%
		Script_List[Script] := Text
	}
	Pos := RegExMatch(Script_List[Script], Var ".*\:(.*)",Match)
	DetectHiddenWindows, %Setting_A_DetectHiddenWindows%
	if (Pos and Match1)
		return Match1
	else
		return Variable ; Get Value of Variable From Script Dialog
}
Get_Full_Path(path) {
	Loop, %path%, 1
		return A_LoopFileLongPath
	return path ; Expand File Path
}
;----------------------------------------------------------------------
; Allows dragging the window position:
WM_LBUTTONDOWN() {
	If A_Gui
		PostMessage, 0xA1, 2 ; 0xA1 = WM_NCLBUTTONDOWN
}
; Sizes the client area to fill the entire window.
WM_NCCALCSIZE() {
	If A_Gui
	return 0
}
; Prevents a border from being drawn when the window is activated.
WM_NCACTIVATE() {
	If A_Gui
	return 1
}
; Redefine where the sizing borders are.  This is necessary since returning 0 for WM_NCCALCSIZE effectively gives borders zero size.
WM_NCHITTEST(wParam, lParam) {
	static border_size = 6

	if !A_Gui
		return

	WinGetPos, gX, gY, gW, gH
	x := lParam<<48>>48, y := lParam<<32>>48

	hit_left := x < gX+border_size
	hit_right := x >= gX+gW-border_size
	hit_top := y < gY+border_size
	hit_bottom := y >= gY+gH-border_size

	if hit_top
	{
		if hit_left
			return 0xD
		else if hit_right
			return 0xE
		else
			return 0xC
	}
	else if hit_bottom
	{
		if hit_left
			return 0x10
		else if hit_right
			return 0x11
		else
			return 0xF
	}
	else if hit_left
		return 0xA
	else if hit_right
		return 0xB

	; else let default hit-testing be done
}

;----------------------------------------------------------------------
;
; http://stackoverflow.com/questions/2891514/algorithms-for-fuzzy-matching-strings
;
; Matching in the style of Ido/CtrlP
;
; Returns:
;   Regex for provided search term
;
; Example:
;   explr builds the regex /[^e]*e[^x]*x[^p]*p[^l]*l[^r]*r/i
;   which would match explorer
;   or likewise
;   explr ahk
;   which would match Explorer - ~/autohotkey, but not Explorer - Documents
;
; Rules:
;  It is expected that all the letters of the input be in the keyword
;  It is expected that the letters in the input be in the same order in the keyword
;  The list of keywords returned should be presented in a consistent (reproductible) order
;  The algorithm should be case insensitive
;
BuildFilterExpression(term)
{
	expr := "i)"
	for _, character in StrSplit(term)
	expr .= "[^" . character . "]*" . character
	return expr
}
;----------------------------------------------------------------------
SortByScore(list) ; Perform insertion sort on list, comparing on each item's score property
{
	Loop % list.MaxIndex() - 1
	{
	i := A_Index+1
	window := list[i]
	j := i-1

	While j >= 0 and list[j].score > window.score
	{
		list[j+1] := list[j]
		j--
	}

	list[j+1] := window
	}

	return list
}
;----------------------------------------------------------------------
; Wrapper for Strdiff, returns better results, found somewhere on the forum, can't recall where though
FuzzySearch(string1, string2)
{
	lenl := StrLen(string1)
	lens := StrLen(string2)
	if(lenl > lens)
	{
		shorter := string2
		longer := string1
	}
	else if(lens > lenl)
	{
		shorter := string1
		longer := string2
		lens := lenl
		lenl := StrLen(string2)
	}
	else
		return StrDiff(string1, string2)
	min := 1
	Loop % lenl - lens + 1
	{
		distance := StrDiff(shorter, SubStr(longer, A_Index, lens))
		if(distance < min)
			min := distance
	}
	return min
}
;----------------------------------------------------------------------
;Modified from original to allow searching for and returning a match for role, name and value, whichever are entered.
JEE_AccGetTextAll(hWnd:=0, nameMatch := "", roleMatch := "", valMatch := "", vSep:="`n", vIndent:="`t", vOpt:="") ;Modified from original to allow searching for and returning a match for role, name and value, whichever are entered.
{
	vLimN := 20, vLimV := 20
	Loop, Parse, vOpt, % " "
	{
		vTemp := A_LoopField
		if (SubStr(vTemp, 1, 1) = "n")
			vLimN := SubStr(vTemp, 2)
		else if (SubStr(vTemp, 1, 1) = "v")
			vLimV := SubStr(vTemp, 2)
	}
	matchList := Object()
	if (nameMatch != "")
		matchList.vName := nameMatch
	if (roleMatch != "")
		matchList.vRoleText := roleMatch
	if (valMatch != "")
		matchList.vValue  := valMatch


	oMem := {}, oPos := {}
	;OBJID_WINDOW := 0x0
	oMem[1, 1] := Acc_ObjectFromWindow(hWnd, 0x0)
	oPos[1] := 1, vLevel := 1
	VarSetCapacity(vOutput, 1000000*2)

	Loop
	{
		if !vLevel
			break
		if !oMem[vLevel].HasKey(oPos[vLevel])
		{
			oMem.Delete(vLevel)
			oPos.Delete(vLevel)
			vLevelLast := vLevel, vLevel -= 1
			oPos[vLevel]++
			continue
		}
		oKey := oMem[vLevel, oPos[vLevel]]

		vName := "", vValue := ""
		if IsObject(oKey)
		{
			vRoleText := Acc_GetRoleText(oKey.accRole(0))
			try vName := oKey.accName(0)
			try vValue := oKey.accValue(0)
		}
		else
		{
			oParent := oMem[vLevel-1,oPos[vLevel-1]]
			vChildId := IsObject(oKey) ? 0 : oPos[vLevel]
			vRoleText := Acc_GetRoleText(oParent.accRole(vChildID))
			try vName := oParent.accName(vChildID)
			try vValue := oParent.accValue(vChildID)
		}
		if (StrLen(vName) > vLimN)
			vName := SubStr(vName, 1, vLimN) "..."
		if (StrLen(vValue) > vLimV)
			vValue := SubStr(vValue, 1, vLimV) "..."
		vName := RegExReplace(vName, "[`r`n]", " ")
		vValue := RegExReplace(vValue, "[`r`n]", " ")

		vAccPath := ""
		if IsObject(oKey)
		{
			Loop, % oPos.Length() - 1
				vAccPath .= (A_Index=1?"":".") oPos[A_Index+1]
		}
		else
		{
			Loop, % oPos.Length() - 2
				vAccPath .= (A_Index=1?"":".") oPos[A_Index+1]
			vAccPath .= " c" oPos[oPos.Length()]
		}
		vOutput .= vAccPath "`t" JEE_StrRept(vIndent, vLevel-1) vRoleText " [" vName "][" vValue "]" vSep

		found := 0
		If (matchList.Count() >= 1) {
			for k, v in matchList
				if InStr(%k%,v)
					found++
			if (found = matchList.Count())
				return vAccPath
		}

		oChildren := Acc_Children(oKey)
		if !oChildren.Length()
			oPos[vLevel]++
		else
		{
			vLevelLast := vLevel, vLevel += 1
			oMem[vLevel] := oChildren
			oPos[vLevel] := 1
		}
	}
	return matchList.Count() >= 1 ? 0 : SubStr(vOutput, 1, -StrLen(vSep))
}
JEE_StrRept(vText, vNum)
{
	if (vNum <= 0)
		return
	return StrReplace(Format("{:" vNum "}", ""), " ", vText)
	;return StrReplace(Format("{:0" vNum "}", 0), 0, vText)
}
