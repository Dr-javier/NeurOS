NeurOS.RegisterCommand("test", function(id, args)
    local message = "Test command called with " .. #args .. " arguments:"
    for i, arg in ipairs(args) do
        message = message .. "\nArg " .. i .. ": " .. arg
    end
    local item = NeurOS.GetTerminal(id)
    NeurOS.WriteToTerminal(item, message)
end)

NeurOS.RegisterCommand("adduser", function(id, args)
    if #args < 2 then
        local item = NeurOS.GetTerminal(id)
        NeurOS.WriteToTerminal(item, "Usage: adduser <username> <4-digit-password>")
        return
    end

    local item = NeurOS.GetTerminal(id)
    if not item then
        print("Item not found")
        return
    end
    local terminal = NeurOS.Terminals[item]
    local username = args[1]
    local password = args[2]

    if terminal.users[username] then
        NeurOS.WriteToTerminal(item, "User already exists")
        return
    end

    -- Validate password format
    if not password:match("^%d%d%d%d$") then
        NeurOS.WriteToTerminal(item, "Password must be exactly 4 digits")
        return
    end

    terminal.users[username] = {
        password = password,
        isSudo = next(terminal.users) == nil  -- First user gets sudo privileges
    }

    NeurOS.WriteToTerminal(item, "User created successfully")
end)

NeurOS.RegisterCommand("setpass", function(id, args)
    if #args < 1 then
        local item = NeurOS.GetTerminal(id)
        NeurOS.WriteToTerminal(item, "Usage: setpass <4-digit-password>")
        return
    end

    local item = NeurOS.GetTerminal(id)
    local terminal = NeurOS.Terminals[item]
    local password = args[1]

    -- Validate password format
    if not password:match("^%d%d%d%d$") then
        NeurOS.WriteToTerminal(item, "Password must be exactly 4 digits")
        return
    end

    if terminal.pendingPasswordUser then
        terminal.users[terminal.pendingPasswordUser].password = password
        NeurOS.WriteToTerminal(item, "Password set for user: " .. terminal.pendingPasswordUser)
        terminal.pendingPasswordUser = nil
    elseif terminal.currentUser then
        terminal.users[terminal.currentUser].password = password
        NeurOS.WriteToTerminal(item, "Password updated")
    else
        NeurOS.WriteToTerminal(item, "No user selected for password change")
    end
end)

NeurOS.RegisterCommand("login", function(id, args)
    if #args < 2 then
        local item = NeurOS.GetTerminal(id)
        NeurOS.WriteToTerminal(item, "Usage: login <username> <password>")
        return
    end

    local item = NeurOS.GetTerminal(id)
    local terminal = NeurOS.Terminals[item]
    local username = args[1]
    local password = args[2]

    if not terminal.users[username] then
        NeurOS.WriteToTerminal(item, "User does not exist")
        return
    end

    if terminal.users[username].password ~= password then
        NeurOS.WriteToTerminal(item, "Invalid password")
        return
    end

    terminal.currentUser = username
    NeurOS.WriteToTerminal(item, "Logged in as: " .. username)
end)

NeurOS.RegisterCommand("logout", function(id, args)
    local item = NeurOS.GetTerminal(id)
    local terminal = NeurOS.Terminals[item]
    
    if not terminal.currentUser then
        NeurOS.WriteToTerminal(item, "Not logged in")
        return
    end

    terminal.currentUser = nil
    terminal.sudoUser = nil
    NeurOS.WriteToTerminal(item, "Logged out successfully")
end)

NeurOS.RegisterCommand("clearall", function(id, args)
    local item = NeurOS.GetTerminal(id)
    local terminal = NeurOS.Terminals[item]
    
    if not terminal.messageHistory then
        NeurOS.WriteToTerminal(item, "No messages to clear")
        return
    end

    NeurOS.ClearTerminal(item)
    NeurOS.WriteToTerminal(item, "All messages cleared")
end)

NeurOS.RegisterCommand("sudo", function(id, args)
    if #args < 2 then
        local item = NeurOS.GetTerminal(id)
        NeurOS.WriteToTerminal(item, "Usage: sudo <password> <command>")
        return
    end

    local item = NeurOS.GetTerminal(id)
    local terminal = NeurOS.Terminals[item]
    
    if not terminal.currentUser then
        NeurOS.WriteToTerminal(item, "Not logged in")
        return
    end

    local password = args[1]
    local user = terminal.users[terminal.currentUser]

    if not user.isSudo then
        NeurOS.WriteToTerminal(item, "User does not have sudo privileges")
        return
    end

    if user.password ~= password then
        NeurOS.WriteToTerminal(item, "Invalid password")
        return
    end

    -- Remove password from args and execute command
    table.remove(args, 1)
    terminal.sudoUser = terminal.currentUser
    NeurOS.HandleCommand(id, table.concat(args, " "))
    terminal.sudoUser = nil
end)

NeurOS.RegisterCommand("sudotest", function(id, args)
    local item = NeurOS.GetTerminal(id)
    local terminal = NeurOS.Terminals[item]
    
    if not terminal.sudoUser then
        NeurOS.WriteToTerminal(item, "This command requires sudo privileges")
        return
    end

    NeurOS.WriteToTerminal(item, "Sudo test successful! Running as root user.")
end)