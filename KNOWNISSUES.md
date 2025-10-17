- Running the script on Bizhawk 2.10 results in the error
```
NLua.Exceptions.LuaScriptException: A .NET exception occured in user-code
System.ArgumentOutOfRangeException: InvalidArgument=Value of '0' is not valid for 'SelectedIndex'.
Parameter name: SelectedIndex
   at System.Windows.Forms.ComboBox.set_SelectedIndex(Int32 value)
   at BizHawk.Client.EmuHawk.LuaDropDown..ctor(ICollection`1 items) in /_/src/BizHawk.Client.EmuHawk/tools/Lua/LuaDropDown.cs:line 13
   at BizHawk.Client.EmuHawk.FormsLuaLibrary.Dropdown(Int64 formHandle, LuaTable items, Nullable`1 x, Nullable`1 y, Nullable`1 width, Nullable`1 height) in /_/src/BizHawk.Client.EmuHawk/tools/Lua/Libraries/FormsLuaLibrary.cs:line 186
```
on the part where the code checks whether there exist any branches already
