
function NeurOS.InitializeTerminals()
    for _, item in pairs(Item.ItemList) do
        local terminal = item.GetComponentString("Terminal")
        if terminal ~= nil then
            local id = NeurOS.GenerateUniqueTerminalId()
            NeurOS.RegisterTerminal(item, id)
        end
    end
end

Hook.Add("roundStart", "NeurOS.InitTerminals", function()
    NeurOS.InitializeTerminals()
end)

function NeurOS.ManuallyInitializeTerminal(item)
    if NeurOS.Terminals[item] then
        return false, "Terminal already initialized"
    end

    local id = NeurOS.GenerateUniqueTerminalId()
    NeurOS.RegisterTerminal(item, id)
    return true, "Terminal initialized successfully"
end

function NeurOS.RegisterTerminal(item, id)
    local rootFolder = NeurOS.CreateFolder("/")
    NeurOS.Terminals[item] = { id = id, fileSystem = { root = rootFolder, currentDir = rootFolder } }
    NeurOS.TerminalLookup[id] = item
    print("Terminal " .. item.Name .. " initialized, terminal id = " .. id)
    NeurOS.WriteToTerminal(item, "Terminal initialized, terminal id = " .. id)
end