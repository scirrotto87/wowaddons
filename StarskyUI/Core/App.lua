local addonName, ns = ...
local App = {}
ns.App = App

function App:Initialize()
    if self.store then return true end
    local build = ns.API.Build()
    if not build or build.interface ~= 16001 then
        self.error = "This version supports WoW Forever interface 16001. No profile was changed."
        return nil, self.error
    end
    local key, reason = ns.API.CharacterKey()
    if not key then self.error = reason; return nil, reason end
    local store, err = ns.Profiles.Open(StarskyUIDB, key)
    if not store then self.error = err; return nil, err end
    self.store, self.error = store, nil
    StarskyUIDB = store.db
    ns.Editor:Apply()
    return true
end

function App:Set(path, value)
    local allowed, reason = ns.API.CombatFree()
    if not allowed then return nil, reason end
    if not self.store then return nil, self.error or "Profiles are not ready." end
    local ok, err = self.store:Set(path, value)
    if not ok then return nil, err end
    ns.Editor:Cancel()
    return true
end

function App:ProfileAction(action, name, copyCurrent)
    local allowed, reason = ns.API.CombatFree()
    if not allowed then return nil, reason end
    if not self.store then return nil, self.error or "Profiles are not ready." end
    local ok, err
    if action == "create" then ok, err = self.store:CreateProfile(name, copyCurrent)
    elseif action == "select" then ok, err = self.store:SelectProfile(name)
    elseif action == "reset" then ok, err = self.store:ResetProfile()
    else return nil, "Profile action is not supported." end
    if ok then
        ns.Panel.resetArmed = false
        ns.Editor:Cancel()
        ns.Panel:ApplyPosition()
    end
    return ok, err
end

function App:Command(input)
    local command = (input or ""):match("^%s*(.-)%s*$"):lower()
    if not self.store then
        local ok, err = self:Initialize()
        if not ok then ns.API.Print(err); return end
    end
    if command == "native" then
        ns.Editor:Cancel()
        local ok, err = ns.API.OpenNativeEditor()
        if not ok then ns.API.Print(err) end
    elseif command == "report" then ns.Panel:Show("Local report")
    elseif command == "edit" then ns.Panel:Show("Status panel")
    elseif command == "" then ns.Panel:Show()
    else ns.API.Print("Use /starskyui, /starskyui native, /starskyui edit, or /starskyui report.") end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("CVAR_UPDATE")
events:SetScript("OnEvent", function(_, event, name)
    if event == "PLAYER_LOGIN" or (event == "ADDON_LOADED" and name == addonName and type(IsLoggedIn) == "function" and IsLoggedIn()) then
        local ok, reason = App:Initialize()
        if not ok then ns.API.Print(reason) end
    elseif event == "PLAYER_REGEN_DISABLED" and ns.Editor.editing then
        ns.Editor:Cancel()
        ns.Panel:SetMessage("Position preview canceled because combat started.")
    end
    if ns.Panel.frame and ns.Panel.frame:IsShown() then ns.Panel:Refresh() end
end)

SLASH_STARSKYUI1 = "/starskyui"
SlashCmdList.STARSKYUI = function(input) App:Command(input) end
