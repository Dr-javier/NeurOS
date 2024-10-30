if CLIENT then return end

NeurOS = NeurOS or {
    Terminals = {},
    Commands = {},
    TerminalLookup = {},
    FileSystem = {}
}


print("NeurOS has loaded")
local FilePath = table.pack(...)[1]
dofile(FilePath.."/Lua/Scripts/Helperfunctions.lua")
dofile(FilePath.."/Lua/Scripts/Terminalinit.lua")
dofile(FilePath.."/Lua/Scripts/Terminalfiles.lua")
dofile(FilePath.."/Lua/Scripts/Terminalcommands.lua")
dofile(FilePath.."/Lua/Scripts/Terminallistener.lua")

