local addonName, ns = ...

local Profiles = {}
local Store = {}
Store.__index = Store

local function defaultProfile()
    return {
        appearance = { accent = "teal" },
        panel = { x = 0, y = 0 },
        widget = { enabled = false, x = 0, y = 0, scale = 1 },
    }
end

local function boundedNumber(value, minimum, maximum)
    return type(value) == "number" and value == value
        and value >= minimum and value <= maximum
end

local function offset(value)
    return boundedNumber(value, -10000, 10000)
end

local validators = {
    ["appearance.accent"] = function(value)
        return value == "teal" or value == "blue" or value == "amber"
    end,
    ["panel.x"] = offset,
    ["panel.y"] = offset,
    ["widget.enabled"] = function(value) return type(value) == "boolean" end,
    ["widget.x"] = offset,
    ["widget.y"] = offset,
    ["widget.scale"] = function(value) return boundedNumber(value, 0.5, 2) end,
}

local function normalizeProfile(source)
    local result = defaultProfile()
    if type(source) ~= "table" then return result end
    for path, validate in pairs(validators) do
        local section, field = string.match(path, "^([^.]+)%.([^.]+)$")
        local values = source[section]
        if type(values) == "table" and validate(values[field]) then
            result[section][field] = values[field]
        end
    end
    return result
end

local function profileName(value)
    if type(value) ~= "string" then return nil, "Profile name must be text." end
    if string.find(value, "%c") then return nil, "Profile name contains a control character." end
    local name = string.match(value, "^%s*(.-)%s*$")
    if #name < 1 or #name > 32 then return nil, "Profile name must contain 1 to 32 bytes." end
    return name
end

local function normalizeCharacter(source)
    local result = { selected = "Default", profiles = {} }
    if type(source) == "table" and type(source.profiles) == "table" then
        for name, profile in pairs(source.profiles) do
            local validName = profileName(name)
            if validName == name then result.profiles[name] = normalizeProfile(profile) end
        end
        if type(source.selected) == "string" and result.profiles[source.selected] then
            result.selected = source.selected
        end
    end
    if not result.profiles.Default then result.profiles.Default = defaultProfile() end
    return result
end

function Profiles.Open(saved, characterKey)
    if type(characterKey) ~= "string" or characterKey == "" then
        return nil, "Character key must be nonempty text."
    end
    if saved ~= nil then
        if type(saved) ~= "table" then return nil, "Saved profiles must be a table." end
        if saved.schemaVersion ~= 1 then return nil, "Saved profile schema is not supported." end
    end

    local db = saved or { schemaVersion = 1, characters = {} }
    local characters = type(db.characters) == "table" and db.characters or {}
    local character = normalizeCharacter(characters[characterKey])
    characters[characterKey] = character
    db.characters = characters
    return setmetatable({ db = db, _character = character }, Store)
end

function Store:GetProfile()
    return normalizeProfile(self._character.profiles[self._character.selected])
end

function Store:GetSelectedName()
    return self._character.selected
end

function Store:ListProfiles()
    local names = {}
    for name in pairs(self._character.profiles) do names[#names + 1] = name end
    table.sort(names)
    return names
end

function Store:CreateProfile(name, copyCurrent)
    local validName, err = profileName(name)
    if not validName then return nil, err end
    if copyCurrent ~= nil and type(copyCurrent) ~= "boolean" then
        return nil, "Copy option must be a boolean."
    end
    if self._character.profiles[validName] then return nil, "Profile already exists." end
    self._character.profiles[validName] = copyCurrent and self:GetProfile() or defaultProfile()
    self._character.selected = validName
    return true
end

function Store:SelectProfile(name)
    local validName, err = profileName(name)
    if not validName then return nil, err end
    if not self._character.profiles[validName] then return nil, "Profile does not exist." end
    self._character.selected = validName
    return true
end

function Store:ResetProfile()
    self._character.profiles[self._character.selected] = defaultProfile()
    return true
end

function Store:Set(path, value)
    local validate = type(path) == "string" and validators[path]
    if not validate then return nil, "Profile field is not supported." end
    if not validate(value) then return nil, "Profile value is not valid." end
    local section, field = string.match(path, "^([^.]+)%.([^.]+)$")
    self._character.profiles[self._character.selected][section][field] = value
    return true
end

ns.Profiles = Profiles
