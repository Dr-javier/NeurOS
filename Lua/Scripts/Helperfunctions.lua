

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

function NeurOS.WriteToTerminal(item, message, editmode)
    local terminal = item.GetComponentString("Terminal")
    if terminal then
        messagehistory = terminal.messageHistory
        if not messagehistory then
            print("messagehistory is nil")
            return
        end
        NeurOS.ClearTerminal(item)
        
        -- Split message into lines
        local lines = {}
        for line in message:gmatch("[^\r\n]+") do
            table.insert(lines, line)
        end
        
        -- Send each line individually
        for _, line in ipairs(lines) do
            if editmode then
                terminal.showMessage = line
            else
                terminal.showMessage = ">> " .. line
            end
            terminal.SyncHistory()
        end
    end
end

function NeurOS.ClearTerminal(item)
    local terminal = item.GetComponentString("Terminal")
    if terminal then
        if not terminal.messageHistory then
            print("history is nil")
            return
        end
        --[[for _, entry in ipairs(terminal.messageHistory) do
            print("Message removed: " .. entry.Text)
            table.remove(terminal.messageHistory, 1)
        end
        print("History cleared")]]--
        terminal.messageHistory.Clear()
        terminal.SyncHistory()
    end
end

function NeurOS.WriteToTerminalAsUser(item, message, passwordmsg) -- changed to use currentUser instead of client
    local terminal = item.GetComponentString("Terminal")
    local IsMobile = false
    print(item.Name)
    if item.Name == "Logbook" then IsMobile = true end
    if terminal then
        if not IsMobile then
            --terminal.ReceiveSignal(Signal(1),item.Connections[4])
            NeurOS.ClearTerminal(item)
        else
            NeurOS.ClearTerminal(item)
        end
        if NeurOS.Terminals[item] then
            local user = NeurOS.Terminals[item].currentUser
            if user == nil then
                user = "NeurOS"
            end
            
            -- Check if message starts with login or adduser
            local args = NeurOS.ParseArguments(message)
            if #args >= 3 and (args[1] == "login" or args[1] == "adduser") then
                -- Replace password with asterisks
                local censored = args[1] .. " " .. args[2] .. " " .. string.rep("*", #args[3])
                terminal.showMessage = user .. ": " .. censored
            else
                terminal.showMessage = user .. ": " .. message
            end
            terminal.SyncHistory()
        else
            terminal.showMessage = message
            terminal.SyncHistory()
        end
    end
end

function NeurOS.WriteToTerminalAsClient(item, message, client) -- will be unused, maybe for logging?
    local terminal = item.GetComponentString("Terminal")
    if terminal then
        terminal.ReceiveSignal(Signal(1),item.Connections[4])
        terminal.showMessage = client.Character.Name .. ": " .. message
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