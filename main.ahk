; main script file

#NoEnv
#SingleInstance force
;#Warn

;
myContainer := new GlobalContainer("MyStorage")
OnExit( Func("Exit").Bind(myContainer) )
myContainer.Connect( Func("GetData") )
GetData(container, property)  {
   obj := container[property]
   Loop % obj.MaxIndex()
      str := obj[A_Index]
		f := obj[1]
		f2 := obj[2]
		param := f2
	if F2
		textReturnedFromCommand := %f%( param )
	else
		textReturnedFromCommand := %f%()

	;msgbox % f "(" A_Space param A_space ")"

	if textReturnedFromCommand
		msgbox % textReturnedFromCommand
}
Exit(container)  {
   container.Quit()
}
;#<Include>
#Include %A_ScriptDir%\conf\cfuncts.ahk
#Include %A_ScriptDir%\lib\AccV2.ahk
#Include %A_ScriptDir%\lib\AHKScripts.ahk
#Include %A_ScriptDir%\lib\classGlobalContainer.ahk
#Include %A_ScriptDir%\lib\objectSort.ahk
#Include %A_ScriptDir%\lib\ObjRegisterActive.ahk
#Include %A_ScriptDir%\lib\Sift.ahk
#Include %A_ScriptDir%\lib\StrDiff.ahk
#Include %A_ScriptDir%\lib\TCMatch.ahk
#Include %A_ScriptDir%\lib\tf.ahk
#Include %A_ScriptDir%\conf\global_conf.ahk
;</#Include>

run, %A_ScriptDir%\KeyIndex.ahk
