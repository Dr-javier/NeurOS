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
    
    local folderName = args[1]
    if folderName == ".." then
        if currentDir.parent then
            terminalData.fileSystem.currentDir = currentDir.parent
        end
    else
        for _, child in ipairs(currentDir.children) do
            if child.name == folderName and child.type == "folder" then
                terminalData.fileSystem.currentDir = child
                return
            end
        end
        local item = NeurOS.GetTerminal(id)
        NeurOS.WriteToTerminal(item, "No such folder: " .. folderName)
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