Hook.Patch("Barotrauma.Items.Components.Terminal", "ServerEventRead", function(instance, ptable)
    local msg = ptable["msg"]
    local client = ptable["c"]
    
    local rewindBit = msg.BitPosition
    local output = msg.ReadString()
    msg.BitPosition = rewindBit

    print(output)

    local item = instance.Item

    -- First display the input
    NeurOS.WriteToTerminal(item, output)

    -- Then handle the command separately, without triggering another write
    if output:lower() == "install neuros" then
        NeurOS.ManuallyInitializeTerminal(item)
    else
        local terminalId = NeurOS.GetTerminalId(item)
        if terminalId then
            NeurOS.HandleCommand(terminalId, output)
        end
    end
    
    ptable.PreventExecution = true
    return nil
end, Hook.HookMethodType.Before)

--[[Hook.Add("NeurOS.TerminalWrite", "NeurOS.TerminalWrite", function(item, output)
    local terminalId = NeurOS.GetTerminalId(item)
    if terminalId then
        NeurOS.HandleCommand(terminalId, output)
    end
end)--]]