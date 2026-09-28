local GROUP_DEV_ROLES = {
    mod = true,
    bal = true,
    admin = true,
    yt = true,
    bs = true,
}

local canUseCached = nil
local isAdminCached = nil

local function GetRole()
    local arg = GetCommandLineArg("/group", 1)
    if not arg or not arg[1] then
        return false
    end

    return string.lower(tostring(arg[1]))
end

function CanUse()
    if canUseCached == nil then
        canUseCached = GROUP_DEV_ROLES[GetRole()] == true
    end

    return canUseCached
end

function IsAdmin()
    if isAdminCached == nil then
        isAdminCached = GetRole() == 'admin'
    end

    return isAdminCached
end

return {
    CanUse = CanUse,
    IsAdmin = IsAdmin,
}
