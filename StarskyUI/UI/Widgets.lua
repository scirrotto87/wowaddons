local addonName, ns = ...
local Widgets = {}
ns.Widgets = Widgets
Widgets.accents = { teal = { 0.21, 0.84, 0.70 }, blue = { 0.35, 0.65, 1 }, amber = { 1, 0.71, 0.30 } }

function Widgets.Frame(name, parent)
    local frame = CreateFrame("Frame", name, parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.055, 0.065, 0.085, 0.98)
    frame.background = background
    if frame.SetBackdrop then
        frame:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        frame:SetBackdropBorderColor(0.24, 0.29, 0.35, 1)
    end
    return frame
end

function Widgets.Label(parent, text, x, y, width, template)
    local label = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlight")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetWidth(width or 660)
    label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    label:SetText(text)
    return label
end

function Widgets.Button(parent, text, x, y, width, callback)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 150, 26)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetText(text)
    button:SetScript("OnClick", callback)
    return button
end

function Widgets.Input(parent, x, y, width, label)
    if label then Widgets.Label(parent, label, x, y + 20, width) end
    local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    input:SetSize(width, 24)
    input:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    input:SetAutoFocus(false)
    input:SetMaxLetters(64)
    input:SetScript("OnTextChanged", function(self, userInput)
        if userInput then self.dirty = true end
    end)
    input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    input:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    return input
end

function Widgets.Escape(frame)
    if type(UISpecialFrames) ~= "table" then return end
    local name = frame:GetName()
    for _, existing in ipairs(UISpecialFrames) do if existing == name then return end end
    UISpecialFrames[#UISpecialFrames + 1] = name
end
