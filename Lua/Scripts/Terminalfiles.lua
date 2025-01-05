function NeurOS.RegisterCommand(name, func)
    NeurOS.Commands[name] = func
end

NeurOS.RegisterCommand("rm", function(id, args)
    if #args < 1 then
        local item = NeurOS.GetTerminal(id)
        NeurOS.WriteToTerminal(item, "Usage: rm <name>")
        return
    end
    
    local terminalData = NeurOS.GetTerminalData(id)
    local currentDir = terminalData and terminalData.fileSystem.currentDir
    if not currentDir then
        NeurOS.WriteToTerminal(NeurOS.GetTerminal(id), "File system not initialized.")
        return
    end
    
    local name = args[1]
    for i, child in ipairs(currentDir.children) do
        if child.name == name then
            table.remove(currentDir.children, i)
            local item = NeurOS.GetTerminal(id)
            NeurOS.WriteToTerminal(item, "Removed: " .. name)
            return
        end
    end
    local item = NeurOS.GetTerminal(id)
    NeurOS.WriteToTerminal(item, "No such file or folder: " .. name)
end)

NeurOS.RegisterCommand("mkdir", function(id, args)
    if #args < 1 then
        local item = NeurOS.GetTerminal(id)
        NeurOS.WriteToTerminal(item, "Usage: mkdir <folder_name>")
        return
    end
    
    local terminalData = NeurOS.GetTerminalData(id)
    local currentDir = terminalData and terminalData.fileSystem.currentDir
    if not currentDir then
        NeurOS.WriteToTerminal(NeurOS.GetTerminal(id), "File system not initialized.")
        return
    end
    
    local folderName = args[1]
    local newFolder = NeurOS.CreateFolder(folderName, currentDir)
    table.insert(currentDir.children, newFolder)
    local item = NeurOS.GetTerminal(id)
    NeurOS.WriteToTerminal(item, "Folder created: " .. folderName)
end)

NeurOS.RegisterCommand("cd", function(id, args)
    if #args < 1 then
        local item = NeurOS.GetTerminal(id)
        NeurOS.WriteToTerminal(item, "Usage: cd <folder_name>")
        return
    end
    
    local terminalData = NeurOS.GetTerminalData(id)
    if not terminalData then return end
    local currentDir = terminalData.fileSystem.currentDir
    if not currentDir then
        NeurOS.WriteToTerminal(NeurOS.GetTerminal(id), "File system not initialized.")
        return
    end
    
    local path = args[1]
    
    -- Handle ./ at start (current directory)
    if path:sub(1,2) == "./" then
        path = path:sub(3)
    end
    
    -- Handle multiple ../
    while path:sub(1,3) == "../" do
        if currentDir.parent then
            currentDir = currentDir.parent
            path = path:sub(4)  -- Remove the "../" part
        else
            NeurOS.WriteToTerminal(NeurOS.GetTerminal(id), "Already at root directory")
            return
        end
    end
    
    -- Handle single ..
    if path == ".." then
        if currentDir.parent then
            terminalData.fileSystem.currentDir = currentDir.parent
        else
            NeurOS.WriteToTerminal(NeurOS.GetTerminal(id), "Already at root directory")
        end
        return
    end
    
    -- Handle remaining path (if any)
    if path ~= "" then
        for _, child in ipairs(currentDir.children) do
            if child.name == path and child.type == "folder" then
                terminalData.fileSystem.currentDir = child
                return
            end
        end
        local item = NeurOS.GetTerminal(id)
        NeurOS.WriteToTerminal(item, "No such folder: " .. path)
    end
end)

NeurOS.RegisterCommand("ls", function(id, args)
    local item = NeurOS.GetTerminal(id)
    local terminalData = NeurOS.GetTerminalData(id)
    local currentDir = terminalData and terminalData.fileSystem.currentDir
    
    if not currentDir then
        NeurOS.WriteToTerminal(item, "File system not initialized.")
        return
    end
    
    local contents = {}
    for _, child in ipairs(currentDir.children) do
        table.insert(contents, child.name)
    end

    if #contents > 0 then
        NeurOS.WriteToTerminal(item, table.concat(contents, "\n"))
    else
        NeurOS.WriteToTerminal(item, "No contents in directory: " .. currentDir.name)
    end
end)

NeurOS.RegisterCommand("nano", function(id, args)
    if #args < 1 then
        local item = NeurOS.GetTerminal(id)
        NeurOS.WriteToTerminal(item, "Usage: nano <filename>")
        return
    end
    
    local terminalData = NeurOS.GetTerminalData(id)
    local currentDir = terminalData and terminalData.fileSystem.currentDir
    if not currentDir then
        NeurOS.WriteToTerminal(NeurOS.GetTerminal(id), "File system not initialized.")
        return
    end
    
    local filename = args[1]
    -- Check if file exists
    local existingFile
    for _, child in ipairs(currentDir.children) do
        if child.name == filename then
            if child.type == "folder" then
                NeurOS.WriteToTerminal(NeurOS.GetTerminal(id), "Cannot edit a folder")
                return
            end
            existingFile = child
            break
        end
    end
    
    -- Create new file if it doesn't exist
    if not existingFile then
        existingFile = {
            name = filename,
            type = "file",
            content = "",
            parent = currentDir
        }
        table.insert(currentDir.children, existingFile)
    end
    
    -- Set terminal to edit mode
    terminalData.editMode = true
    terminalData.editingFile = existingFile
    
    -- Split content into lines for editing
    terminalData.editingLines = {}
    if existingFile.content then
        for line in existingFile.content:gmatch("[^\n]+") do
            table.insert(terminalData.editingLines, line)
        end
    end
    
    local displayContent = existingFile.content or ""
    if #terminalData.editingLines > 0 then
        displayContent = displayContent .. "\nCurrent line count: " .. #terminalData.editingLines
    end
    
    NeurOS.WriteToTerminal(NeurOS.GetTerminal(id), "Editing " .. filename .. 
        "\nEnter content (':w' to save and exit, ':l <number>' to edit specific line):\n" .. displayContent)
end)

NeurOS.RegisterCommand("run", function(id, args)
    if #args < 1 then
        local item = NeurOS.GetTerminal(id)
        NeurOS.WriteToTerminal(item, "Usage: run <filename>")
        return
    end
    
    local terminalData = NeurOS.GetTerminalData(id)
    local currentDir = terminalData and terminalData.fileSystem.currentDir
    if not currentDir then
        NeurOS.WriteToTerminal(NeurOS.GetTerminal(id), "File system not initialized.")
        return
    end
    
    local filename = args[1]
    -- Find file
    for _, child in ipairs(currentDir.children) do
        if child.name == filename and child.type == "file" then
            NeurOS.WriteToTerminal(NeurOS.GetTerminal(id), "Contents of " .. filename .. ":\n" .. (child.content or ""))
            return
        end
    end
    
    NeurOS.WriteToTerminal(NeurOS.GetTerminal(id), "File not found: " .. filename)
end)

function NeurOS.GetTerminalData(id)
    local item = NeurOS.GetTerminal(id)
    if item then
        local terminal = NeurOS.Terminals[item]
        if not terminal.fileSystem then
            terminal.fileSystem = {}
        end
        return terminal
    end
    return nil
end

function NeurOS.CreateFolder(name, parent)
    return { name = name, type = "folder", children = {}, parent = parent or nil }
end

NeurOS.RegisterCommand("ssh", function(id, args)
    if #args < 2 then
        local item = NeurOS.GetTerminal(id)
        NeurOS.WriteToTerminal(item, "Usage: ssh terminalid@username port")
        return
    end

    local item = NeurOS.GetTerminal(id)
    local terminal = NeurOS.Terminals[item]
    
    print("[SSH] Attempting connection from terminal " .. id)
    
    -- Parse terminalid@username
    local targetId, username = args[1]:match("(%d+)@(.+)")
    local port = tonumber(args[2])
    
    print("[SSH] Target ID: " .. (targetId or "nil"))
    print("[SSH] Username: " .. (username or "nil"))
    print("[SSH] Port: " .. (port or "nil"))

    if not targetId or not username then
        NeurOS.WriteToTerminal(item, "Invalid format. Use: terminalid@username")
        return
    end

    -- Check if target terminal exists
    local targetItem = NeurOS.GetTerminal(targetId)
    print("[SSH] Target terminal found: " .. (targetItem ~= nil and "yes" or "no"))
    
    if not targetItem then
        NeurOS.WriteToTerminal(item, "Terminal not found")
        return
    end

    local targetTerminal = NeurOS.Terminals[targetItem]
    print("[SSH] Target terminal initialized: " .. (targetTerminal ~= nil and "yes" or "no"))
    
    -- Check if port is open
    if port ~= 22 and (not targetTerminal.ports or not targetTerminal.ports[port] or not targetTerminal.ports[port].open) then
        print("[SSH] Port " .. port .. " is closed")
        NeurOS.WriteToTerminal(item, "Connection refused: Port closed")
        return
    end

    -- Check if user exists on target
    print("[SSH] User exists on target: " .. (targetTerminal.users[username] ~= nil and "yes" or "no"))
    if not targetTerminal.users[username] then
        NeurOS.WriteToTerminal(item, "User not found on remote terminal")
        return
    end

    -- Prompt for password
    terminal.pendingSSH = {
        targetId = targetId,
        username = username,
        attempts = 0
    }
    print("[SSH] Pending SSH session created")
    NeurOS.WriteToTerminal(item, "Enter password:")
end)

NeurOS.RegisterCommand("ipscan", function(id, args)
    local item = NeurOS.GetTerminal(id)
    local message = "Available terminals:\n"
    local found = false
    
    for terminalId, terminalItem in pairs(NeurOS.TerminalLookup) do
        message = message .. "Terminal ID: " .. terminalId .. " (Port 22 open)\n"
        local terminal = NeurOS.Terminals[terminalItem]
        if terminal.ports then
            for port, status in pairs(terminal.ports) do
                if status.open then
                    message = message .. "  Port " .. port .. " open\n"
                end
            end
        end
        found = true
    end
    
    if not found then
        message = "No terminals found"
    end
    
    NeurOS.WriteToTerminal(item, message)
end)

NeurOS.RegisterCommand("setport", function(id, args)
    if #args < 2 then
        local item = NeurOS.GetTerminal(id)
        NeurOS.WriteToTerminal(item, "Usage: setport <number> <open/closed>")
        return
    end

    local item = NeurOS.GetTerminal(id)
    local terminal = NeurOS.Terminals[item]
    local port = tonumber(args[1])
    local state = args[2]:lower()

    if not port or port == 22 then
        NeurOS.WriteToTerminal(item, "Invalid port number or cannot modify port 22")
        return
    end

    if state ~= "open" and state ~= "closed" then
        NeurOS.WriteToTerminal(item, "State must be 'open' or 'closed'")
        return
    end

    if not terminal.ports then
        terminal.ports = {}
    end

    terminal.ports[port] = {open = (state == "open")}
    NeurOS.WriteToTerminal(item, "Port " .. port .. " is now " .. state)
end)

NeurOS.RegisterCommand("exit", function(id, args)
    local item = NeurOS.GetTerminal(id)
    local terminal = NeurOS.Terminals[item]
    
    if not terminal.sshSession then
        NeurOS.WriteToTerminal(item, "Not in SSH session")
        return
    end

    -- Notify both terminals about disconnection
    NeurOS.WriteToTerminal(item, "SSH session closed")
    local targetItem = NeurOS.GetTerminal(terminal.sshSession.targetId)
    if targetItem then
        NeurOS.WriteToTerminal(targetItem, "Remote session disconnected: " .. terminal.currentUser)
    end

    terminal.sshSession = nil
end)

NeurOS.RegisterCommand("help", function(id, args)
    local item = NeurOS.GetTerminal(id)
    
    if #args == 0 then
        -- List all commands
        local message = "Available commands:\n"
        local commands = {}
        for cmd, info in pairs(NeurOS.help) do
            table.insert(commands, cmd .. " - " .. info.desc)
        end
        table.sort(commands)  -- Alphabetically sort commands
        message = message .. table.concat(commands, "\n")
        message = message .. "\n\nUse 'help <command>' for detailed information."
        NeurOS.WriteToTerminal(item, message)
        return
    end

    -- Show detailed help for specific command
    local command = args[1]
    local helpInfo = NeurOS.help[command]
    
    if not helpInfo then
        NeurOS.WriteToTerminal(item, "No help available for: " .. command)
        return
    end

    local message = string.format([[
        Command: %s
        Description: %s
        Syntax: %s
        Details: %s]], command, helpInfo.desc, helpInfo.syntax, helpInfo.details)

    NeurOS.WriteToTerminal(item, message)
end)