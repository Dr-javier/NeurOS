

function NeurOS.GenerateTerminalId()
    return string.format("%06d", math.random(0, 999999))
end

function NeurOS.GenerateUniqueTerminalId()
    local id
    repeat
        id = NeurOS.GenerateTerminalId()
    until NeurOS.TerminalLookup[id] == nil
    return id
end

function NeurOS.GetTerminalId(item)
    return NeurOS.Terminals[item] and NeurOS.Terminals[item].id or nil
end

function NeurOS.GetTerminal(id)
    return NeurOS.TerminalLookup[id] or nil
end

function NeurOS.WriteToTerminal(item, message)
    local terminal = item.GetComponentString("Terminal")
    if terminal then
        --ShowOnTerminal(terminal, message)
        terminal.ReceiveSignal(Signal(1),item.Connections[4])
        terminal.showMessage = message
        terminal.SyncHistory()
    end
end

function NeurOS.HandleCommand(id, message)
    local args = NeurOS.ParseArguments(message)
    if #args == 0 then return end  -- Add this check
    
    local commandName = args[1]
    local commandArgs = {}
    for i = 2, #args do
        table.insert(commandArgs, args[i])
    end
    local command = NeurOS.Commands[commandName]

    if command == nil then
        local item = NeurOS.GetTerminal(id)
        NeurOS.WriteToTerminal(item, "Unknown command: " .. commandName)
        return
    end
    
    command(id, commandArgs)
end

function NeurOS.ParseArguments(message)
    local args = {}
    for word in message:gmatch("%S+") do
        table.insert(args, word)
    end
    return args
end

function ShowOnTerminal(terminal, message)
    if not terminal then
        return
    end
    
    if not terminal.messageHistory then
        return
    end
    
    terminal.messageHistory.Add(terminal.TerminalMessage(message, Color.Green, false))
    
    while terminal.messageHistory.Count > 100 do
        terminal.messageHistory.RemoveAt(0)
    end
    
    terminal.SyncHistory()
end