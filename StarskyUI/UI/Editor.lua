local addonName, ns = ...
local Editor = { editing = false }
ns.Editor = Editor

local function copyWidget(widget)
    return { enabled = widget.enabled, x = widget.x, y = widget.y, scale = widget.scale }
end

local function finite(value, low, high)
    return type(value) == "number" and value == value and value >= low and value <= high
end

local function snap(value) return math.floor(value / 8 + 0.5) * 8 end

function Editor:EnsureFrame()
    if self.frame then return end
    local anchor = CreateFrame("Frame", "StarskyUIStatusAnchor", UIParent)
    anchor:SetMovable(true)
    anchor:EnableMouse(true)
    anchor:SetClampedToScreen(true)
    anchor:RegisterForDrag("LeftButton")
    local visual = ns.Widgets.Frame(nil, anchor)
    visual:SetSize(270, 54)
    visual:SetPoint("CENTER", anchor, "CENTER", 0, 0)
    visual:EnableMouse(false)
    self.title = ns.Widgets.Label(visual, "StarskyUI", 12, -9, 246)
    self.hint = ns.Widgets.Label(visual, "Click for settings", 12, -29, 246, "GameFontHighlightSmall")
    self.frame, self.visual = anchor, visual
    anchor:SetScript("OnDragStart", function(frame)
        if self.editing and ns.API.CombatFree() then frame:StartMoving() end
    end)
    anchor:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing()
        if not self.editing or not ns.API.CombatFree() then return end
        local x, y = frame:GetCenter()
        local parentX, parentY = UIParent:GetCenter()
        if not x or not y or not parentX or not parentY then return end
        self:Preview(snap(x - parentX), snap(y - parentY), self.draft.scale)
        ns.Panel:Refresh()
    end)
    anchor:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" and not self.editing then ns.Panel:Show() end
    end)
end

function Editor:Apply()
    if not ns.App.store then return end
    local profile = ns.App.store:GetProfile()
    local widget = self.editing and self.draft or profile.widget
    if not widget.enabled and not self.editing and not self.frame then return end
    self:EnsureFrame()
    self.frame:SetFrameStrata(self.editing and "FULLSCREEN_DIALOG" or "MEDIUM")
    self.frame:StopMovingOrSizing()
    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", UIParent, "CENTER", widget.x, widget.y)
    self.frame:SetSize(270 * widget.scale, 54 * widget.scale)
    self.visual:SetScale(widget.scale)
    local color = ns.Widgets.accents[profile.appearance.accent]
    self.title:SetTextColor(color[1], color[2], color[3])
    self.title:SetText("StarskyUI - " .. ns.API.Text(ns.App.store:GetSelectedName()))
    self.hint:SetText(self.editing and "Drag to move - 8-unit grid" or "Click for settings")
    if self.visual.SetBackdropBorderColor then
        self.visual:SetBackdropBorderColor(color[1], color[2], color[3], self.editing and 1 or 0.5)
    end
    if widget.enabled or self.editing then self.frame:Show() else self.frame:Hide() end
end

function Editor:Start()
    local allowed, reason = ns.API.CombatFree()
    if not allowed then return nil, reason end
    if not ns.App.store then return nil, "Profiles are not available." end
    if self.editing then return true end
    self.draft = copyWidget(ns.App.store:GetProfile().widget)
    self.editing = true
    ns.Panel:ResetEditorInputs()
    self:Apply()
    return true
end

function Editor:Preview(x, y, scale)
    if not self.editing then return nil, "Start the status-panel editor first." end
    local allowed, reason = ns.API.CombatFree()
    if not allowed then return nil, reason end
    if not finite(x, -10000, 10000) or not finite(y, -10000, 10000) or not finite(scale, 0.5, 2) then
        return nil, "Use offsets from -10000 to 10000 and a scale from 0.5 to 2."
    end
    self.draft.x, self.draft.y, self.draft.scale = x, y, scale
    ns.Panel:ResetEditorInputs()
    self:Apply()
    return true
end

function Editor:Save()
    if not self.editing then return nil, "There is no position preview to save." end
    local allowed, reason = ns.API.CombatFree()
    if not allowed then return nil, reason end
    local store = ns.App.store
    for _, key in ipairs({ "x", "y", "scale" }) do
        local ok, err = store:Set("widget." .. key, self.draft[key])
        if not ok then return nil, err end
    end
    self.editing, self.draft = false, nil
    ns.Panel:ResetEditorInputs()
    self:Apply()
    return true
end

function Editor:Cancel()
    self.editing, self.draft = false, nil
    ns.Panel:ResetEditorInputs()
    self:Apply()
end
