Functions_AddOnAccess = {}

-- GetAddOnInfo moved: Classic Era uses the global GetAddOnInfo,
-- TBC Anniversary/Retail moved it to C_AddOns.GetAddOnInfo.
function Functions_AddOnAccess:IsAddOnInstalled(addonName)
    local getAddOnInfo = GetAddOnInfo or C_AddOns.GetAddOnInfo
    local name = getAddOnInfo(addonName)
    return name ~= nil
end
