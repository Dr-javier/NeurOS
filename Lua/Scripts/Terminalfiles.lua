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