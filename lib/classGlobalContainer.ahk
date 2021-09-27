class GlobalContainer  {
   __New(name)  {
      for wnd in ComObjCreate("Shell.Application").Windows  {
         if (wnd.GetProperty("container_name") = name)
            this._obj := wnd
      }
      if !this._obj  {
         this._obj := ComObjGet("new:{C08AFD90-F2A1-11D1-8455-00A0C91F3880}")
         this._obj.PutProperty("container_name", name)
      }
   }

   __Set(prop, value)  {
      if prop not in _obj,_userFunc
         Return this._obj.PutProperty(prop, value)
   }

   __Get(prop)  {
      if (prop != "_obj")
         Return this._obj.GetProperty(prop)
   }

   Connect(userFunc)  {
      this._userFunc := userFunc.Bind(this)
      ComObjConnect(this._obj, this)
   }

   PropertyChange(prop, obj)  {
      this._userFunc.Call(prop)
   }

   Quit()  {
      this._obj.Quit()
   }
}
