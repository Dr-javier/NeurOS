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

    local isFirstUser = next(terminal.users) == nil
    terminal.users[username] = {
        password = password,
        isSudo = isFirstUser  -- First user gets sudo privileges
    }

    NeurOS.WriteToTerminal(item, "User created successfully")
    
    -- Auto-login if this is the first user
    if isFirstUser then
        terminal.currentUser = username
        NeurOS.WriteToTerminal(item, "Logged in as: " .. username)
    end
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

-- Register Mail Commands
NeurOS.RegisterCommand("mail", function(id, args)
    if #args < 1 then
        NeurOS.WriteToTerminal(NeurOS.GetTerminal(id), "Usage: mail <send|inbox|download|read|delete> [parameters]")
        return
    end

    local subcommand = args[1]:lower()
    table.remove(args, 1) -- Remove the subcommand from args

    if subcommand == "send" then
        -- Usage: mail send <terminalID> <subject> <message> -attach <filePath>
        NeurOS.HandleMailSend(id, args)
    elseif subcommand == "inbox" then
        NeurOS.HandleMailInbox(id)
    elseif subcommand == "download" then
        -- Usage: mail download <messageID>
        NeurOS.HandleMailDownload(id, args)
    elseif subcommand == "read" then
        -- Usage: mail read <messageID>
        NeurOS.HandleMailRead(id, args)
    elseif subcommand == "delete" then
        -- Usage: mail delete <messageID>
        NeurOS.HandleMailDelete(id, args)
    else
        NeurOS.WriteToTerminal(NeurOS.GetTerminal(id), "Unknown mail subcommand: " .. subcommand)
    end
end)

-- Handle 'mail send' command
function NeurOS.HandleMailSend(senderId, args)
    local terminal = NeurOS.Terminals[NeurOS.TerminalLookup[senderId]]
    if not terminal or not terminal.currentUser then
        NeurOS.WriteToTerminal(NeurOS.GetTerminal(senderId), "You must be logged in to send mail.")
        return
    end

    -- Parse arguments
    local attachIndex = nil
    for i, arg in ipairs(args) do
        if arg == "-attach" then
            attachIndex = i
            break
        end
    end

    local recipientId, subject, message, attachmentPath = nil, nil, nil, nil
    if attachIndex then
        recipientId = args[1]
        subject = args[2]
        message = table.concat(args, " ", 3, attachIndex - 1)
        attachmentPath = args[attachIndex + 1]
    else
        if #args < 3 then
            NeurOS.WriteToTerminal(NeurOS.GetTerminal(senderId), "Usage: mail send <terminalID> <subject> <message> -attach <filePath>")
            return
        end
        recipientId = args[1]
        subject = args[2]
        message = table.concat(args, " ", 3)
    end

    -- Validate recipient
    local recipientTerminal = NeurOS.GetTerminal(recipientId)
    if not recipientTerminal then
        NeurOS.WriteToTerminal(NeurOS.GetTerminal(senderId), "Recipient terminal ID not found.")
        return
    end

    -- Handle attachment
    local attachmentStoredPath = nil
    if attachmentPath then
        local senderFile = NeurOS.FindFile(terminal.fileSystem.currentDir, attachmentPath)
        if not senderFile then
            NeurOS.WriteToTerminal(NeurOS.GetTerminal(senderId), "Attachment file not found: " .. attachmentPath)
            return
        end
        -- Copy attachment to recipient's file system
        local recipientTerminalData = NeurOS.Terminals[recipientTerminal]
        local destPath = NeurOS.GenerateUniqueFilePath(recipientTerminalData.fileSystem.currentDir, senderFile.name)
        NeurOS.CopyFile(senderFile, recipientTerminalData.fileSystem.currentDir, destPath)
        attachmentStoredPath = destPath
    end

    -- Create message
    local messageObj = NeurOS.CreateMessage(terminal.id, subject, message, attachmentStoredPath)
    table.insert(terminal.mail.outbox, messageObj)
    table.insert(NeurOS.Terminals[recipientTerminal].mail.inbox, messageObj)

    NeurOS.WriteToTerminal(NeurOS.GetTerminal(senderId), "Message sent successfully.")
    NeurOS.WriteToTerminal(recipientTerminal, "New mail received from terminal " .. terminal.id .. ".")
end

-- Handle 'mail inbox' command
function NeurOS.HandleMailInbox(id)
    local terminal = NeurOS.Terminals[NeurOS.TerminalLookup[id]]
    if not terminal or not terminal.currentUser then
        NeurOS.WriteToTerminal(NeurOS.GetTerminal(id), "You must be logged in to view inbox.")
        return
    end

    local inbox = terminal.mail.inbox
    if #inbox == 0 then
        NeurOS.WriteToTerminal(NeurOS.GetTerminal(id), "Your inbox is empty.")
        return
    end

    local message = "Inbox:\nID | From | Subject | Status | Attachment\n"
    for _, msg in ipairs(inbox) do
        local status = msg.read and "Read" or "Unread"
        local attachment = msg.attachment and "[*]" or ""
        message = message .. string.format("%s | %s | %s | %s | %s\n", msg.id, msg.sender, msg.subject, status, attachment)
    end

    NeurOS.WriteToTerminal(NeurOS.GetTerminal(id), message)
end

-- Handle 'mail read' command
function NeurOS.HandleMailRead(id, args)
    if #args < 1 then
        NeurOS.WriteToTerminal(NeurOS.GetTerminal(id), "Usage: mail read <messageID>")
        return
    end

    local messageId = args[1]
    local terminal = NeurOS.Terminals[NeurOS.TerminalLookup[id]]
    if not terminal or not terminal.currentUser then
        NeurOS.WriteToTerminal(NeurOS.GetTerminal(id), "You must be logged in to read messages.")
        return
    end

    local inbox = terminal.mail.inbox
    for _, msg in ipairs(inbox) do
        if msg.id == messageId then
            NeurOS.WriteToTerminal(NeurOS.GetTerminal(id), string.format("From: %s\nSubject: %s\nMessage:\n%s", msg.sender, msg.subject, msg.content))
            msg.read = true
            return
        end
    end

    NeurOS.WriteToTerminal(NeurOS.GetTerminal(id), "Message ID not found in inbox.")
end

-- Handle 'mail download' command
function NeurOS.HandleMailDownload(id, args)
    if #args < 1 then
        NeurOS.WriteToTerminal(NeurOS.GetTerminal(id), "Usage: mail download <messageID>")
        return
    end

    local messageId = args[1]
    local terminal = NeurOS.Terminals[NeurOS.TerminalLookup[id]]
    if not terminal or not terminal.currentUser then
        NeurOS.WriteToTerminal(NeurOS.GetTerminal(id), "You must be logged in to download attachments.")
        return
    end

    local inbox = terminal.mail.inbox
    for _, msg in ipairs(inbox) do
        if msg.id == messageId then
            if not msg.attachment then
                NeurOS.WriteToTerminal(NeurOS.GetTerminal(id), "No attachment found for this message.")
                return
            end

            local file = NeurOS.FindFile(terminal.fileSystem.currentDir, msg.attachment)
            if not file then
                NeurOS.WriteToTerminal(NeurOS.GetTerminal(id), "Attachment file not found in your file system.")
                return
            end

            -- Simulate downloading by copying the file to current directory
            local destPath = NeurOS.GenerateUniqueFilePath(terminal.fileSystem.currentDir, file.name)
            NeurOS.CopyFile(file, terminal.fileSystem.currentDir, destPath)

            NeurOS.WriteToTerminal(NeurOS.GetTerminal(id), "Attachment downloaded to " .. destPath)
            return
        end
    end

    NeurOS.WriteToTerminal(NeurOS.GetTerminal(id), "Message ID not found in inbox.")
end

-- Handle 'mail delete' command
function NeurOS.HandleMailDelete(id, args)
    if #args < 1 then
        NeurOS.WriteToTerminal(NeurOS.GetTerminal(id), "Usage: mail delete <messageID>")
        return
    end

    local messageId = args[1]
    local terminal = NeurOS.Terminals[NeurOS.TerminalLookup[id]]
    if not terminal or not terminal.currentUser then
        NeurOS.WriteToTerminal(NeurOS.GetTerminal(id), "You must be logged in to delete messages.")
        return
    end

    local inbox = terminal.mail.inbox
    for i, msg in ipairs(inbox) do
        if msg.id == messageId then
            table.remove(inbox, i)
            NeurOS.WriteToTerminal(NeurOS.GetTerminal(id), "Message deleted successfully.")
            return
        end
    end

    NeurOS.WriteToTerminal(NeurOS.GetTerminal(id), "Message ID not found in inbox.")
end

-- Utility Functions for File Operations
function NeurOS.FindFile(directory, filePath)
    -- Implement logic to find a file in the given directory
    for _, file in ipairs(directory.children) do
        if file.name == filePath and not file.isFolder then
            return file
        end
    end
    return nil
end

function NeurOS.CopyFile(sourceFile, destinationDir, destPath)
    -- Implement file copying logic
    local newFile = {
        name = destPath or sourceFile.name,
        content = sourceFile.content,
        isFolder = false,
        children = {}
    }
    table.insert(destinationDir.children, newFile)
end

function NeurOS.GenerateUniqueFilePath(directory, fileName)
    -- Ensure the file path is unique within the directory
    local uniqueName = fileName
    local counter = 1
    while NeurOS.FindFile(directory, uniqueName) do
        uniqueName = string.format("%s_%d", fileName, counter)
        counter = counter + 1
    end
    return uniqueName
end