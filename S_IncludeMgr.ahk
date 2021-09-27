
#NoEnv
SetWorkingDir, %A_ScriptDir%
top_folder = %A_ScriptDir%

; recursively search all dirs and subdirs for ahk files and create
; include file lists in their respective dirs and parent dirs
;
; hotkeys kept in files ending with "_conf.ahk"
; - conf files added to main script file rather than their parent dir
; so key indexer can find them
;
;

;-------------------------------------------------------------------------------					 <custom_vars> + line 148
base_file:=top_folder . "\main.ahk"																								;	 NAME OF MAIN AHK SCRIPT

#Include %A_ScriptDir%\lib\tf.ahk

skip_filesarr:=[ ".bak.ahk", "_ref.ahk", "__"]
skip_dirsarr := ["test", ".history", ".vscode", ".git", "ref"] ; 1 dir down only
skip_subdirsarr := ["ref"] ; 2 dir down
script_dirsarr := ["scripts"] ; collects A_ScriptDir\Scripts\*.ahk files in case need a list of them for anything in the future
;----------------------------B---------------------------------------------------					/<custom_vars>
base_filename:=RegExReplace(base_file, "^.+\\|\.[^.]+$") ; name no .ext

base_incldfile:=top_folder . "\include.ahk" ;tmp
base_includefilename:=RegExReplace(base_incldfile, "^.+\\|\.[^.]+$")

base_configfile:=top_folder . "\user_conf.ahk" ;tmp
base_configfilename:=RegExReplace(base_configfile, "^.+\\|\.[^.]+$")

base_scriptfile:=top_folder . "\scripts_list.ahk" ;tmp
base_scriptfilename:=RegExReplace(base_scriptfile, "^.+\\|\.[^.]+$")

list_includefiles:= 				; list of all include.ahk files full paths
list_conffiles:=						; list of all _config files full paths
list_scripts:=							; list of all files in script dir
list_ahkfiles:=							; list of all other .ahk files full paths

Loop, %top_folder%\*.*, 2, 1			; CHECK A_ScriptDir
{
	ThisSubFolderPath = %A_LoopFileFullPath%
	ThisSubFolderName = %A_LoopFileName%
	SubDirCount = 0
	strFile := ThisSubFolderPath . "\include.ahk"
	FileDelete, %strFile%
	mid:
	Loop, %ThisSubFolderPath%\*.ahk ; CHECK SUBDIRECTORY FOR FILES
	{
		rpath:=StrReplace(ThisSubFolderPath, A_ScriptDir, "%A_ScriptDir%")
		arr:=strsplit(rpath,"\")
		firstdir:=arr[2]
		Loop,% skip_dirsarr.Length() { ; skip top level dirs on MATCH
    	if(firstdir = skip_dirsarr[A_Index]){
				continue mid
			}
		}
		seconddir:=arr[3]
		Loop,% skip_subdirsarr.Length() { ; skip top level dirs on MATCH
    	if(seconddir = skip_subdirsarr[A_Index]){
				continue mid
			}
		}

		Loop,% skip_filesarr.Length() { ; skip if any file names CONTAIN match
    	if(A_LoopFileName ~= skip_filesarr[A_Index]){
				continue mid
			}
		}

		Loop,% script_dirsarr.Length() { ; keep script files in sep list
    	if(firstdir = script_dirsarr[A_Index]){
			NewStr:=StrReplace(A_LoopFileFullPath, A_ScriptDir, "%A_ScriptDir%") ; replace full paths w "%_ScriptDir%"
			list_scripts .= "`; run " NewStr "`n"																; add to list of script files
			continue mid
			}
		}
		if (A_LoopFileName ~= "conf.ahk")
		{
			NewStr:=StrReplace(A_LoopFileFullPath, A_ScriptDir, "%A_ScriptDir%") 			; replace full paths w "%_ScriptDir%"
			FileRead, filetext, %base_configfile% 																		; read file
			IfNotInString, filetext, %NewStr% 																				; if line doesnt already exists
				fileappend, #Include %NewStr%`n, %base_configfile%											;	append to file
				list_conffiles .= "#Include " NewStr "`n"																; add to list of conffiles
		}
		Else
		{
			arr:=strsplit(A_LoopFileFullPath,"\")
			parent:=arr[arr.length() - 1]
			IfInString, parent, `-																										; use "-" in dirname to store include file 2 dirs up
			{																																					;(used to bundle functions in their own dirs but list w others)
				SubDirCount++
				par:=SubStr(A_LoopFileFullPath, 1, InStr(A_LoopFileFullPath, "\", False, 0) - 1)
				par:=SubStr(par, 1, InStr(par, "\", False, 0) - 1)
				par:=SubStr(par, 1, InStr(par, "\", False, 0) - 1)
				NewStr:=StrReplace(A_LoopFileFullPath, A_ScriptDir, "%A_ScriptDir%")
				list_ahkfiles .= A_LoopFileFullPath "`n"
				fileappend, #Include %NewStr%`n, %par%\include.ahk
			}
			Else
			{
				SubDirCount++
				parent:=SubStr(A_LoopFileFullPath, 1, InStr(A_LoopFileFullPath, "\", False, 0) - 1)																						; default behaviour
				par:=SubStr(parent, 1, InStr(parent, "\", False, 0) - 1)																																				; (1 dir up)
				NewStr:=StrReplace(A_LoopFileFullPath, A_ScriptDir, "%A_ScriptDir%")
				list_ahkfiles .= A_LoopFileFullPath "`n"
				fileappend, #Include %NewStr%`n, %par%\include.ahk
			}
		}
	}
}


Loop, %top_folder%\include.ahk, , 1																							; NEW DIR LOOP TO LINK INCLUDE.AHK FILES TO EACH OTHER
{
	ThisSubFolderPath = %A_LoopFileFullPath%
	parent:=SubStr(A_LoopFileFullPath, 1, InStr(A_LoopFileFullPath, "\", False, 0) - 1)
	par:=SubStr(parent, 1, InStr(parent, "\", False, 0) - 1)
	NewStr:=StrReplace(A_LoopFileFullPath, A_ScriptDir, "%A_ScriptDir%")
	IncldFile:="%par%\include.ahk"
	FileRead, filetext, %IncldFile% ; read file
	IfNotInString, filetext, %NewStr% ; if line doesnt already exist
		fileappend, #Include %NewStr%`n, %par%\include.ahk ; append
		list_includefiles .= A_LoopFileFullPath "`n" ; & add to list
}

FileDelete, %base_configfile%	; delete any old _config.ahk list
FileAppend, %list_conffiles%, %base_configfile%	; create tmp _config.ahk file list

;FileDelete, %base_scriptfile%
;FileAppend, %list_scripts%, %base_scriptfile%

strToFind:="#Include"
Loop, read, %base_file%																													; GET THE NUMBER OF LINES ON MAIN AHK SCRIPT FILE THAT CONTAIN ""#INCLUDE"
{
  IfInString, A_LoopReadLine, %strToFind%
  {
		Row = %A_Index%
		RowNums .=Row ","	; list of nums
   }
}
StringTrimRight, RNums, RowNums, 1 ; trim trailing comma from list
StringSplit, array, RNums, `,	; make list into array
firstline:=array1+1 ; # of first line containing #Include
lastline:=array%array0%-1	; # of last line containing #Include
fileID:=1
count:=0
lines:=

TF_RemoveLines("!main.ahk", firstline, lastline)				; delete lines from include to return						; <<<<<<<<<<<<<<<<<<< "!base_filename" = plaintxt name of base file name

Loop, Read, %base_file%																				; read base_file line by line
{
	lines .= A_LoopReadLine . "`n"															; count and collect lines
	count++
	If (count == (firstline-1))																							; split file when count reaches first line -1: by collecting lines up to point
	{
		part1:=%base_filename%_1.ahk
		fp:=fileID
		FileAppend %lines%, %base_filename%_%fileID%.ahk																	; and appending collected lines to [base_filename]_1.ahk
		fileID++
		lines:=																										; clear collected lines
	}
}
If (count > 0)
{
	fileID++
	fileID++
	lp:=fileID
	FileAppend %lines%, %base_filename%_%fileID%.ahk						; append rest of lines to [base_filename]_4.ahk
}
ls:=
sls:=
Loop, Read, %base_filename%_%fp%.ahk
{
	if A_LoopReadLine != ""
		ls .= A_LoopReadLine . "`n"
}
 Loop, Read, %base_incldfile%
{
	if A_LoopReadLine != ""
 		ls .= A_LoopReadLine . "`n"
 }
Loop, Read, %base_configfile%
{
	if A_LoopReadLine != ""
		ls .= A_LoopReadLine . "`n"
}
Loop, Read, %base_filename%_%lp%.ahk
{
	if A_LoopReadLine != ""
		ls .= A_LoopReadLine . "`n"
}
;Loop, Read, %base_scriptfile%
;{
;	if A_LoopReadLine != ""
;		ls .= A_LoopReadLine . "`n"
;}

FileMove, %base_file%, %base_filename%.bak									; backup %base_file%
FileAppend, %ls%, %base_file%																; append list (%ls%) to new %base_file%
FileDelete, %base_filename%_*.ahk														; delete "_" files
FileDelete, %base_filename%.bak															; delete backup file
FileDelete, %base_incldfile%															; delete backup file
FileDelete, %base_configfile%															; delete backup file
;FileDelete, %base_scriptfile%															; delete backup file
