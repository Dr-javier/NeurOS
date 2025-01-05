Hook.Patch("Barotrauma.Items.Components.Terminal", "ServerEventRead", function(instance, ptable)
    local msg = ptable["msg"]
    local client = ptable["c"]
    if client == nil then
        return nil
    end
    if msg == nil then
        return nil
    end
    rewindBit = msg.BitPosition -- making local might cause issues
    output = msg.ReadString()
    msg.BitPosition = rewindBit

    

    local item = instance.Item

    NeurOS.WriteToTerminalAsUser(item, output, client)


    if output:match("^%s*>>") then
        print("Preventing execution, detected command output")
        ptable.PreventExecution = true
        return nil
    end


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
            local terminalData = NeurOS.GetTerminalData(terminalId)
            if terminalData and terminalData.editMode then
                if output == ":w" then
                    -- Join non-empty lines and save
                    local content = {}
                    for _, line in ipairs(terminalData.editingLines) do
                        if line and line:match("%S") then  -- Only keep non-empty lines
                            table.insert(content, line)
                        end
                    end
                    terminalData.editingFile.content = table.concat(content, "\n")
                    
                    -- Exit edit mode
                    terminalData.editMode = false
                    terminalData.editingLines = nil
                    terminalData.currentLine = nil

                    -- Show save message on both terminals if in SSH
                    local message = "File saved: " .. terminalData.editingFile.name
                    NeurOS.WriteToTerminal(item, message)
                    if terminal.sshSession then
                        local originalTerminal = NeurOS.GetTerminal(terminal.sshSession.targetId)
                        if originalTerminal then
                            NeurOS.WriteToTerminal(originalTerminal, message)
                        end
                    end
                elseif output:match("^:l%s+(%d+)$") then
                    -- Line editing command
                    local lineNum = tonumber(output:match("^:l%s+(%d+)$"))
                    local message
                    if lineNum > 0 and lineNum <= #terminalData.editingLines then
                        terminalData.currentLine = lineNum
                        message = "Editing line " .. lineNum .. ":\n" .. 
                            (terminalData.editingLines[lineNum] or "")
                    else
                        message = "Invalid line number. File has " .. 
                            #terminalData.editingLines .. " lines"
                    end
                    
                    -- Show message on both terminals if in SSH
                    NeurOS.WriteToTerminal(item, message)
                    if terminal.sshSession then
                        local originalTerminal = NeurOS.GetTerminal(terminal.sshSession.targetId)
                        if originalTerminal then
                            NeurOS.WriteToTerminal(originalTerminal, message)
                        end
                    end
                else
                    -- Handle content input
                    if terminalData.currentLine then
                        -- Replace specific line
                        terminalData.editingLines[terminalData.currentLine] = output
                        terminalData.currentLine = nil
                        -- Show updated content on both terminals
                        local content = "Updated content:\n" .. table.concat(terminalData.editingLines, "\n")
                        NeurOS.WriteToTerminal(item, content)
                        if terminal.sshSession then
                            local originalTerminal = NeurOS.GetTerminal(terminal.sshSession.targetId)
                            if originalTerminal then
                                NeurOS.WriteToTerminal(originalTerminal, content)
                            end
                        end
                    else
                        -- Append new line
                        table.insert(terminalData.editingLines, output)
                        NeurOS.WriteToTerminal(item, output)
                        if terminal.sshSession then
                            local originalTerminal = NeurOS.GetTerminal(terminal.sshSession.targetId)
                            if originalTerminal then
                                NeurOS.WriteToTerminal(originalTerminal, output)
                            end
                        end
                    end
                end
                ptable.PreventExecution = true
                return nil
            end
            if terminal.pendingSSH then
                print("[SSH] Processing password attempt")
                -- Handle SSH password authentication
                local targetItem = NeurOS.GetTerminal(terminal.pendingSSH.targetId)
                print("[SSH] Target terminal found: " .. (targetItem ~= nil and "yes" or "no"))
                local targetTerminal = NeurOS.Terminals[targetItem]
                print("[SSH] Target user password match: " .. 
                    (targetTerminal.users[terminal.pendingSSH.username].password == output and "yes" or "no"))
                
                if targetTerminal.users[terminal.pendingSSH.username].password == output then
                    -- Successful login
                    print("[SSH] Login successful, creating session")
                    terminal.sshSession = {
                        targetId = terminal.pendingSSH.targetId,
                        username = terminal.pendingSSH.username
                    }
                    NeurOS.WriteToTerminal(item, "Welcome to " .. terminal.pendingSSH.targetId)
                    terminal.pendingSSH = nil
                else
                    terminal.pendingSSH.attempts = terminal.pendingSSH.attempts + 1
                    print("[SSH] Failed attempt " .. terminal.pendingSSH.attempts)
                    if terminal.pendingSSH.attempts >= 3 then
                        NeurOS.WriteToTerminal(item, "Too many failed attempts")
                        terminal.pendingSSH = nil
                    else
                        NeurOS.WriteToTerminal(item, "Invalid password. Try again:")
                    end
                end
                ptable.PreventExecution = true
                return nil
            elseif terminal.sshSession then
                print("[SSH] Forwarding command to target terminal")
                -- Forward commands to target terminal
                local targetItem = NeurOS.GetTerminal(terminal.sshSession.targetId)
                if targetItem then
                    print("[SSH] Target terminal found, executing command")
                    -- Store original terminal to show output
                    local originalTerminal = item
                    
                    -- Execute command on target terminal
                    NeurOS.HandleCommand(terminal.sshSession.targetId, output)
                    
                    -- Get the last message from target terminal and show it on original terminal
                    local targetTerminalComponent = targetItem.GetComponentString("Terminal")
                    if targetTerminalComponent and targetTerminalComponent.messageHistory and 
                       targetTerminalComponent.messageHistory.Count > 0 then
                        local lastMessage = targetTerminalComponent.messageHistory[targetTerminalComponent.messageHistory.Count - 1]
                        if lastMessage then
                            NeurOS.WriteToTerminal(originalTerminal, lastMessage.Text)
                        end
                    end
                else
                    print("[SSH] Target terminal not found, closing session")
                    NeurOS.WriteToTerminal(item, "SSH session lost. Connection closed.")
                    terminal.sshSession = nil
                end
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