if CLIENT and Game.IsMultiplayer then return end
LuaUserData.RegisterType("Barotrauma.Items.Components.Terminal")
LuaUserData.RegisterType("Barotrauma.Items.Components.TerminalMessage")
LuaUserData.RegisterType('System.Collections.Generic.List`1[[Barotrauma.Items.Components.TerminalMessage]]')
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Items.Components.Terminal"], "messageHistory")


NeurOS = NeurOS or {
    Terminals = {},
    Commands = {},
    TerminalLookup = {},
    FileSystem = {},
    help = {}
}


print("NeurOS has loaded")
local FilePath = table.pack(...)[1]
dofile(FilePath.."/Lua/Scripts/Helperfunctions.lua")
dofile(FilePath.."/Lua/Scripts/Terminalinit.lua")
dofile(FilePath.."/Lua/Scripts/Terminalfiles.lua")
dofile(FilePath.."/Lua/Scripts/Terminalcommands.lua")
dofile(FilePath.."/Lua/Scripts/Terminallistener.lua")
dofile(FilePath.."/Lua/Scripts/helpdefs.lua")
