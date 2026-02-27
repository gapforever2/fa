local GROUP_DEV_ROLES = {
    mod = true,
    bal = true,
    admin = true,
    yt = true,
    bs = true,
}

local canUseCached = nil

local function CanUse()
    if canUseCached == nil then
        local arg = GetCommandLineArg("/group", 1)
        if not arg or not arg[1] then
            canUseCached = false
        else
            local role = string.lower(tostring(arg[1]))
            canUseCached = GROUP_DEV_ROLES[role] == true
        end
    end

    return canUseCached
end

return {
    CanUse = CanUse,
}
