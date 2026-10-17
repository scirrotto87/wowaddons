local addonName, ns = ...
local Panel = { page = "Overview", resetArmed = false }
ns.Panel = Panel
local W = ns.Widgets

local function join(lines) return table.concat(lines, "\n") end
local function done(ok, reason)
    Panel:SetMessage(ok and "Saved for this character." or reason)
    Panel:Refresh()
end

function Panel:SetMessage(message)
    self.message = message or ""
    if self.messageLabel then self.messageLabel:SetText(self.message) end
end

function Panel:Select(name)
    self.resetArmed = false
    self.page = name
    self:Refresh()
end

function Panel:ResetEditorInputs()
    for _, field in ipairs({ "x", "y", "scale" }) do
        if self[field] then self[field].dirty = false end
    end
end

function Panel:EnsureFrame()
    if self.frame then return end
    local frame = W.Frame("StarskyUIWindow", UIParent)
    self.frame = frame
    frame:SetSize(820, 610)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    W.Escape(frame)
    self.title = W.Label(frame, "StarskyUI", 20, -18, 650, "GameFontNormalLarge")
    W.Label(frame, "Your native layout stays in Edit Mode.", 20, -42, 700, "GameFontHighlightSmall")
    W.Button(frame, "Close", 740, -16, 60, function() frame:Hide() end)
    local drag = CreateFrame("Frame", nil, frame)
    drag:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    drag:SetSize(730, 58)
    drag:EnableMouse(true)
    drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart", function() if ns.API.CombatFree() then frame:StartMoving() end end)
    drag:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        if not ns.API.CombatFree() then self:ApplyPosition(); return end
        local x, y = frame:GetCenter()
        local px, py = UIParent:GetCenter()
        if x and y and px and py then
            ns.App.store:Set("panel.x", x - px)
            ns.App.store:Set("panel.y", y - py)
        end
    end)
    frame:SetScript("OnHide", function()
        ns.Editor:Cancel()
        self.resetArmed = false
    end)
    self.pages, self.nav = {}, {}
    for i, name in ipairs({ "Overview", "Native options", "Providers", "Profiles", "Status panel", "Local report" }) do
        local tab = name
        self.nav[name] = W.Button(frame, name, 18, -78 - (i - 1) * 34, 150, function() self:Select(tab) end)
        local page = CreateFrame("Frame", nil, frame)
        page:SetPoint("TOPLEFT", frame, "TOPLEFT", 188, -78)
        page:SetSize(602, 450)
        self.pages[name] = page
    end
    W.Button(frame, "Refresh status", 18, -316, 150, function() self:Refresh(); self:SetMessage("Status refreshed from WoW.") end)
    W.Button(frame, "Native Edit Mode", 18, -352, 150, function()
        ns.Editor:Cancel()
        local ok, reason = ns.API.OpenNativeEditor()
        if ok then frame:Hide() else self:SetMessage(reason) end
    end)
    self.messageLabel = W.Label(frame, "", 20, -550, 780)
    W.Label(frame, "v" .. ns.VERSION .. "  |  /starskyui  |  Only StarskyUI settings are saved here.", 20, -586, 760, "GameFontHighlightSmall")
    self.overview = W.Label(self.pages.Overview, "", 0, 0, 590)
    self.native = W.Label(self.pages["Native options"], "", 0, 0, 590)
    self.providers = W.Label(self.pages.Providers, "", 0, 0, 590)
    self:BuildProfiles()
    self:BuildEditor()
    self:BuildReport()
    self:ApplyPosition()
    frame:Hide()
end

function Panel:BuildProfiles()
    local page = self.pages.Profiles
    self.profileInfo = W.Label(page, "", 0, 0, 590)
    W.Label(page, "Create or select a profile by name. Profiles apply to this character only.", 0, -70, 590)
    self.profileName = W.Input(page, 5, -124, 300, "Profile name")
    W.Button(page, "Create new", 0, -164, 140, function()
        done(ns.App:ProfileAction("create", self.profileName:GetText(), false))
    end)
    W.Button(page, "Copy current", 150, -164, 140, function()
        done(ns.App:ProfileAction("create", self.profileName:GetText(), true))
    end)
    W.Button(page, "Use named profile", 300, -164, 180, function()
        done(ns.App:ProfileAction("select", self.profileName:GetText()))
    end)
    W.Label(page, "Accent color for StarskyUI windows", 0, -218, 590)
    for i, name in ipairs({ "teal", "blue", "amber" }) do
        local color = name
        W.Button(page, name, (i - 1) * 150, -246, 140, function() done(ns.App:Set("appearance.accent", color)) end)
    end
    self.resetButton = W.Button(page, "Reset current profile", 0, -306, 230, function()
        if not self.resetArmed then
            self.resetArmed = true
            self.resetButton:SetText("Click again to reset")
            self:SetMessage("This resets the current StarskyUI profile. Other profiles stay saved.")
            return
        end
        self.resetArmed = false
        done(ns.App:ProfileAction("reset"))
    end)
    W.Label(page, "Native layouts and other addon profiles are managed in their own settings.", 0, -352, 590)
end

function Panel:BuildEditor()
    local page = self.pages["Status panel"]
    W.Label(page, "StarskyUI status panel", 0, 0, 590, "GameFontNormalLarge")
    W.Label(page, "A small launcher for these settings. Edit only this addon-owned frame here.\nUse native Edit Mode for your bars, unit frames, chat, meter and cooldowns.", 0, -34, 590)
    self.widgetToggle = W.Button(page, "Show status panel", 0, -98, 210, function()
        done(ns.App:Set("widget.enabled", not ns.App.store:GetProfile().widget.enabled))
    end)
    W.Button(page, "Start position preview", 230, -98, 240, function()
        local ok, reason = ns.Editor:Start()
        self:SetMessage(ok and "Drag the status panel, or enter offsets below." or reason)
        self:Refresh()
    end)
    -- Keep controls below the largest centered preview (scale 2).
    self.x = W.Input(page, 5, -310, 140, "Horizontal offset")
    self.y = W.Input(page, 165, -310, 140, "Vertical offset")
    self.scale = W.Input(page, 325, -310, 140, "Scale (0.5 to 2)")
    W.Button(page, "Preview values", 0, -352, 145, function()
        local ok, reason = ns.Editor:Preview(tonumber(self.x:GetText()), tonumber(self.y:GetText()), tonumber(self.scale:GetText()))
        self:SetMessage(ok and "Position preview updated. Save or cancel below." or reason)
        if ok then self:Refresh() end
    end)
    W.Button(page, "Save position", 155, -352, 145, function()
        local ok, reason = ns.Editor:Preview(tonumber(self.x:GetText()), tonumber(self.y:GetText()), tonumber(self.scale:GetText()))
        if not ok then self:SetMessage(reason); return end
        done(ns.Editor:Save())
    end)
    W.Button(page, "Cancel preview", 310, -352, 160, function()
        ns.Editor:Cancel(); self:SetMessage("Position preview canceled."); self:Refresh()
    end)
    self.editorState = W.Label(page, "", 0, -144, 590)
    W.Label(page, "Dragging uses an 8-unit grid. Numeric offsets use native UI units.\nThe preview closes on combat, profile change, or closing this window.\nSaving a position keeps the current show/hide setting.", 0, -400, 590)
end

function Panel:BuildReport()
    local page = self.pages["Local report"]
    W.Label(page, "Select the text below to copy a local baseline. Nothing is sent automatically.", 0, 0, 590)
    local scroll = CreateFrame("ScrollFrame", nil, page, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -42)
    scroll:SetSize(560, 380)
    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject(ChatFontNormal)
    edit:SetWidth(550)
    edit:SetTextInsets(4, 4, 4, 4)
    local measure = page:CreateFontString(nil, "OVERLAY")
    measure:SetFontObject(ChatFontNormal)
    measure:SetWidth(542)
    measure:Hide()
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnTextChanged", function(self)
        measure:SetText(self:GetText())
        self:SetHeight(math.max(380, measure:GetStringHeight() + 24))
    end)
    scroll:SetScrollChild(edit)
    self.report = edit
end

function Panel:ApplyPosition()
    if not self.frame or not ns.App.store then return end
    local profile = ns.App.store:GetProfile()
    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", UIParent, "CENTER", profile.panel.x, profile.panel.y)
end

function Panel:Refresh()
    if not self.frame or not ns.App.store then return end
    local snapshot = ns.Diagnostics.Snapshot(ns.API, _G)
    self.snapshot = snapshot
    local profile = ns.App.store:GetProfile()
    local color = W.accents[profile.appearance.accent]
    self.title:SetTextColor(color[1], color[2], color[3])
    for name, page in pairs(self.pages) do
        if name == self.page then page:Show(); self.nav[name]:Disable() else page:Hide(); self.nav[name]:Enable() end
    end
    local overview = {
        "Native layout: " .. ns.API.Text(snapshot.layout),
        "Profile: " .. ns.API.Text(ns.App.store:GetSelectedName()), "",
        "Native Edit Mode owns native frame placement.",
        "StarskyUI owns its settings window and optional status panel.",
        "Other addons keep their existing functions and profiles.", "", "Ownership checks:",
    }
    for _, conflict in ipairs(snapshot.conflicts) do overview[#overview + 1] = "- " .. conflict; overview[#overview + 1] = "" end
    if #snapshot.conflicts == 0 then overview[#overview + 1] = "No listed overlap detected. Check actual gameplay before replacing a provider." end
    self.overview:SetText(join(overview))
    local native = { "Current native options (read-only)", "Edit these in WoW or the provider's settings.", "" }
    for _, option in ipairs(snapshot.options) do native[#native + 1] = option.label .. ": " .. ns.API.Text(option.value) .. "  [" .. option.owner .. "]" end
    native[#native + 1], native[#native + 2] = "", "Leatrix parent options (child values do not enable their parent):"
    for _, gate in ipairs(snapshot.gates) do native[#native + 1] = gate.label .. ": " .. ns.API.Text(gate.value) end
    self.native:SetText(join(native))
    local providers = { "Runtime loading status", "Not loaded can mean disabled, absent, or waiting to load.", "" }
    for _, provider in ipairs(snapshot.providers) do
        local status = provider.loaded == nil and "unknown" or provider.loaded and "loaded" or "not loaded"
        providers[#providers + 1] = provider.addon .. " - " .. provider.feature .. " - " .. status
    end
    self.providers:SetText(join(providers))
    local names = ns.App.store:ListProfiles()
    local shown = {}
    for i = 1, math.min(4, #names) do shown[#shown + 1] = ns.API.Text(names[i]) end
    if #names > 4 then shown[#shown + 1] = "... more profiles available by name" end
    self.profileInfo:SetText("Current: " .. ns.API.Text(ns.App.store:GetSelectedName()) .. "\nSaved: " .. table.concat(shown, ", "))
    self.resetButton:SetText(self.resetArmed and "Click again to reset" or "Reset current profile")
    self.widgetToggle:SetText(profile.widget.enabled and "Hide status panel" or "Show status panel")
    local widget = ns.Editor.editing and ns.Editor.draft or profile.widget
    -- Keep all entered coordinates until Preview/Save/Cancel, even after focus changes.
    for field, value in pairs({ x = widget.x, y = widget.y, scale = widget.scale }) do
        if not self[field].dirty then self[field]:SetText(string.format("%.2f", value)) end
    end
    self.editorState:SetText(ns.Editor.editing and "Position preview is active. Changes are not saved yet." or "Position editor is closed.")
    if not self.report:HasFocus() then self.report:SetText(ns.Diagnostics.Report(snapshot)); self.report:SetCursorPosition(0) end
    self.messageLabel:SetText(self.message or "")
end

function Panel:Show(page)
    if not ns.App.store then ns.API.Print(ns.App.error or "Wait until login finishes."); return end
    self:EnsureFrame()
    self.page = page or self.page
    self:Refresh()
    self.frame:Show()
end
