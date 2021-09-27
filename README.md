# ahk-hotkey-index


list all hotkeys from running scripts in fuzzy searchable box, select to run, shift select to open hotkey file in specified editor

![explorer_yc1UqwkbXZ](https://user-images.githubusercontent.com/53843689/134848346-3e3420eb-278c-4399-8111-c51bc1351661.png)


hotkeys only indexed if actions are functions, keys only found if in files included directly in running script (i.e. not included in an include file) 

includemgr is a standalone script i use to manage my include files, it searches dirs and subdirs for ahk files and creates seperate include file lists in each dir while all files ending in \_conf.ahk get added directly to main script file - when run will delete all include.ahk files in all subdirs + also remove existing "#Include" lines from main script file 


i barely made this i just smashed together existing scripts, mainly: Fanatic Guru's HotKey Help + iswitchw lv gui and fuzzy search  + teadrinkers [shellbrowserwindow script](https://www.autohotkey.com/boards/viewtopic.php?p=183046#p183046). pretty janky but works and does exactly what i needed it to do so thought i would share in case others find it useful. 


