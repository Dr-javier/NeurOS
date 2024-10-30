NeurOS.RegisterCommand("test", function(id, args)
    local message = "Test command called with " .. #args .. " arguments:"
    for i, arg in ipairs(args) do
        message = message .. "\nArg " .. i .. ": " .. arg
    end
    local item = NeurOS.GetTerminal(id)
    NeurOS.WriteToTerminal(item, message)
end)