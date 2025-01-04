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

    print(output)


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
                    NeurOS.WriteToTerminal(item, "File saved: " .. terminalData.editingFile.name)
                    terminalData.editingFile = nil
                elseif output:match("^:l%s+(%d+)$") then
                    -- Line editing command
                    local lineNum = tonumber(output:match("^:l%s+(%d+)$"))
                    if lineNum > 0 and lineNum <= #terminalData.editingLines then
                        terminalData.currentLine = lineNum
                        NeurOS.WriteToTerminal(item, "Editing line " .. lineNum .. ":\n" .. 
                            (terminalData.editingLines[lineNum] or ""))
                    else
                        NeurOS.WriteToTerminal(item, "Invalid line number. File has " .. 
                            #terminalData.editingLines .. " lines")
                    end
                else
                    -- Handle content input
                    if terminalData.currentLine then
                        -- Replace specific line
                        terminalData.editingLines[terminalData.currentLine] = output
                        terminalData.currentLine = nil
                        -- Show updated content
                        local content = table.concat(terminalData.editingLines, "\n")
                        NeurOS.WriteToTerminal(item, "Updated content:\n" .. content)
                    else
                        -- Append new line
                        table.insert(terminalData.editingLines, output)
                        NeurOS.WriteToTerminal(item, output)
                    end
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