NeurOS.help = {
    adduser = {
        desc = "Create a new user account",
        syntax = "adduser <username> <4-digit-password>",
        details = "Creates a new user account. The first user created gets sudo privileges."
    },
    login = {
        desc = "Log into an existing user account",
        syntax = "login <username> <password>",
        details = "Authenticate as an existing user to access the terminal."
    },
    logout = {
        desc = "Log out of current session",
        syntax = "logout",
        details = "Ends the current user session."
    },
    setpass = {
        desc = "Change user password",
        syntax = "setpass <4-digit-password>",
        details = "Changes the password for the currently logged in user."
    },
    sudo = {
        desc = "Execute command with root privileges",
        syntax = "sudo <password> <command>",
        details = "Executes a command with elevated privileges. Only works for users with sudo access."
    },
    ls = {
        desc = "List directory contents",
        syntax = "ls",
        details = "Displays all files and folders in the current directory."
    },
    cd = {
        desc = "Change directory",
        syntax = "cd <folder_name>",
        details = "Navigate to another directory. Use 'cd ..' to go up one level."
    },
    mkdir = {
        desc = "Create new directory",
        syntax = "mkdir <folder_name>",
        details = "Creates a new folder in the current directory."
    },
    rm = {
        desc = "Remove file or directory",
        syntax = "rm <name>",
        details = "Permanently deletes a file or directory."
    },
    nano = {
        desc = "Text editor",
        syntax = "nano <filename>",
        details = "Create or edit a text file. Use ':w' to save and exit, ':l <number>' to edit specific line."
    },
    run = {
        desc = "Display file contents",
        syntax = "run <filename>",
        details = "Shows the contents of a file."
    },
    ssh = {
        desc = "Remote login",
        syntax = "ssh <terminalid@username> <port>",
        details = "Connect to another terminal remotely. Port 22 is always open."
    },
    ipscan = {
        desc = "Scan for terminals",
        syntax = "ipscan",
        details = "Lists all available terminals and their open ports."
    },
    setport = {
        desc = "Configure port access",
        syntax = "setport <number> <open/closed>",
        details = "Opens or closes the specified port for SSH access. Port 22 cannot be modified."
    },
    exit = {
        desc = "Exit SSH session",
        syntax = "exit",
        details = "Disconnects from a remote terminal session."
    },
    clearall = {
        desc = "Clear terminal",
        syntax = "clearall",
        details = "Clears all text from the terminal screen."
    },
    mail = {
        desc = "Handle in-game mail operations",
        syntax = "mail <send|inbox|download|read|delete> [parameters]",
        details = [[
Manage your in-game mail.

Subcommands:
- mail send <terminalID> <subject> <message> -attach <filePath>: Send a message with an attachment.
- mail inbox: View your inbox with attachment indicators.
- mail download <messageID>: Download an attachment from a specific message.
- mail read <messageID>: Read the content of a specific message.
- mail delete <messageID>: Delete a specific message from your inbox.
]]
    }
}
