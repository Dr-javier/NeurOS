Hook.Patch("Barotrauma.Items.Components.Terminal", "ServerEventRead", function(instance, ptable)
    local msg = ptable["msg"]
    local client = ptable["c"]
    if client == nil then
        return nil
    end
    if msg == nil then
        return nil
    end
    local rewindBit = msg.BitPosition
    local output = msg.ReadString()
    msg.BitPosition = rewindBit

    

    local item = instance.Item

    -- First display the input
    NeurOS.WriteToTerminalAsUser(item, output, client)

    -- Check if the output starts with >>, if so, don't process as command
    if output:match("^%s*>>") then
        print("Preventing execution, detected command output")
        ptable.PreventExecution = true
        return nil
    end

    print(output)

    -- Then handle the command separately, without triggering another write
    if output:lower() == "install neuros" then
        NeurOS.ManuallyInitializeTerminal(item)
        ptable.PreventExecution = true
        return nil
    else
        local terminalId = NeurOS.GetTerminalId(item)
        if terminalId then
            -- Check if user needs to be created or logged in
            local terminal = NeurOS.Terminals[item]
            if next(terminal.users) == nil and output:sub(1, 8) ~= "adduser " then
                NeurOS.WriteToTerminal(item, "Please create your first user with: adduser <username>")
                ptable.PreventExecution = true
                return nil
            elseif terminal.currentUser == nil and 
                   output:sub(1, 6) ~= "login " and 
                   output:sub(1, 8) ~= "adduser " then
                NeurOS.WriteToTerminal(item, "Please login first with: login <username>")
                ptable.PreventExecution = true
                return nil
            end
            NeurOS.HandleCommand(terminalId, output)
        end
        ptable.PreventExecution = true
        return nil
    end
end, Hook.HookMethodType.Before)

--[[Hook.Add("NeurOS.TerminalWrite", "NeurOS.TerminalWrite", function(item, output)
    local terminalId = NeurOS.GetTerminalId(item)
    if terminalId then
        NeurOS.HandleCommand(terminalId, output)
    end
end)--]]