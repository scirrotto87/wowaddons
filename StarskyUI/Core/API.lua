local addonName, ns = ...
ns.VERSION = "0.1.1"

local API = {}
ns.API = API

local function invoke(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    if ok then return value end
end

function API.Build()
    if type(GetBuildInfo) ~= "function" then return nil end
    local ok, version, build, date, interface = pcall(GetBuildInfo)
    if not ok then return nil end
    return { version = version, build = build, interface = tonumber(interface) }
end

function API.CombatFree()
    if type(InCombatLockdown) ~= "function" then
        return nil, "Combat state is unavailable. Try again after login."
    end
    local ok, combat = pcall(InCombatLockdown)
    -- Classic clients can return nil outside combat. Keep that separate from a failed call.
    if ok and (combat == false or combat == nil) then return true end
    if ok and (combat == true or combat == 1) then return nil, "Finish combat before making this change." end
    return nil, "Combat state is unavailable. Try again after login."
end

function API.CharacterKey()
    local guid = invoke(UnitGUID, "player")
    if type(guid) == "string" and guid ~= "" then return guid end
    return nil, "Character identity is unavailable. Try again after login."
end

function API.Loaded(name)
    local fn = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
    local result = invoke(fn, name)
    if type(result) == "boolean" then return result end
    return nil
end

function API.CVar(name)
    local fn = C_CVar and C_CVar.GetCVar or GetCVar
    local value = invoke(fn, name)
    if type(value) == "string" then return value end
    return nil
end

function API.Layout()
    local manager = EditModeManagerFrame
    if not manager then return nil end
    local info = invoke(manager.GetActiveLayoutInfo, manager)
    if type(info) == "table" and type(info.layoutName) == "string" then
        return info.layoutName
    end
end

function API.OpenNativeEditor()
    local allowed, reason = API.CombatFree()
    if not allowed then return nil, reason end
    local manager = EditModeManagerFrame
    if not manager or type(ShowUIPanel) ~= "function" then
        return nil, "Open Edit Mode from the game menu. Its window is not available here."
    end
    local ok = pcall(ShowUIPanel, manager)
    if not ok then return nil, "WoW could not open Edit Mode. Use the game menu."
    end
    if invoke(manager.IsShown, manager) ~= true then
        return nil, "Edit Mode did not report an open window. Use the game menu."
    end
    return true
end

function API.Text(value)
    if value == nil then return "Unavailable" end
    return tostring(value):gsub("[%c]", " "):gsub("|", "||"):sub(1, 180)
end

function API.Print(message)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cff36d6b3StarskyUI:|r " .. tostring(message))
    end
end
