local addonName, ns = ...
local Diagnostics = {}
ns.Diagnostics = Diagnostics

Diagnostics.nativeOptions = {
    { "uiScale", "UI scale", "Native" },
    { "useUiScale", "Use UI scale", "Native" },
    { "autoLootDefault", "Auto-loot", "Native preference" },
    { "cooldownViewerEnabled", "Cooldown viewer", "Native" },
    { "countdownForCooldowns", "Cooldown numbers", "Native" },
    { "damageMeterEnabled", "Damage meter", "Native" },
    { "damageMeterResetOnNewInstance", "Meter reset on new instance", "Native" },
    { "showSwingTimer", "Swing timer", "Native" },
    { "nameplateShowEnemies", "Enemy nameplates", "Native / Plater profile" },
    { "nameplateMaxDistance", "Nameplate distance", "Native / Plater profile" },
    { "SoftTargetInteract", "Soft interaction", "Native / Plater profile" },
    { "mapFade", "Map fade", "Native / Leatrix Maps" },
}

Diagnostics.providers = {
    { "Plater", "Nameplates" }, { "DarkMode", "Frame colors" },
    { "Leatrix_Plus", "Convenience" }, { "Leatrix_Maps", "Map" },
    { "SpeedyAutoLoot", "Loot execution" }, { "XLoot_Frame", "Loot window" },
    { "Bagnon", "Bags" }, { "Syndicator", "Item tooltips" },
    { "Auctionator", "Auction values" }, { "RXPGuides", "Leveling guide" },
    { "RareScanner", "Rare alerts" }, { "DBM-Core", "Boss warnings" },
    { "BigWigs", "Boss warnings" }, { "Overlord", "World-war fronts" },
    { "TalentsForeverBook", "Talent plans" }, { "EllesmereUI", "Other UI suite" },
}

local function nested(source, ...)
    for i = 1, select("#", ...) do
        if type(source) ~= "table" then return nil end
        source = source[select(i, ...)]
    end
    return source
end

function Diagnostics.Snapshot(api, globals)
    local snapshot = { build = api.Build(), layout = api.Layout(), options = {}, providers = {}, conflicts = {}, gates = {} }
    local loaded = {}
    for _, provider in ipairs(Diagnostics.providers) do
        loaded[provider[1]] = api.Loaded(provider[1])
        snapshot.providers[#snapshot.providers + 1] = {
            addon = provider[1], feature = provider[2], loaded = loaded[provider[1]],
        }
    end
    for _, option in ipairs(Diagnostics.nativeOptions) do
        snapshot.options[#snapshot.options + 1] = {
            key = option[1], label = option[2], owner = option[3], value = api.CVar(option[1]),
        }
    end
    local function conflict(text) snapshot.conflicts[#snapshot.conflicts + 1] = text end
    local lea = globals.LeaPlusDB
    if loaded.Leatrix_Plus and loaded.SpeedyAutoLoot and nested(lea, "FasterLooting") == "On" then
        conflict("Leatrix FasterLooting and SpeedyAutoLoot both handle loot. Choose one executor during migration.")
    end
    if loaded.Plater and loaded.DarkMode then
        local mode = nested(globals.DMTAB, "VALUES", "COLORMODENP")
        if mode ~= 8 then
            conflict("DarkMode and Plater may both color nameplates. Check DarkMode's nameplate color setting.")
        end
    end
    if loaded["DBM-Core"] and loaded.BigWigs then
        conflict("DBM and BigWigs are both loaded. Check which provider supplies the warnings you use.")
    end
    if loaded.EllesmereUI then
        conflict("Ellesmere's core is loaded. Check frame ownership before replacing any native UI feature.")
    end
    if loaded.Plater then
        conflict("Plater can store native nameplate and interaction settings in a shared profile. Check profile scope before changing them.")
    end
    if loaded.Leatrix_Maps and nested(globals.LeaMapsDB, "NoMapFade") == "On" then
        conflict("Leatrix Maps applies map fade Off at startup. Its setting can override a native map-fade change.")
    end
    for _, gate in ipairs({
        { "MinimapModder", "Minimap changes" }, { "TipModEnable", "Tooltip movement" },
        { "ClassColFrames", "Player/target class colors" }, { "SetEditModeLayout", "Automatic native layout selection" },
    }) do
        snapshot.gates[#snapshot.gates + 1] = {
            label = gate[2], value = loaded.Leatrix_Plus and nested(lea, gate[1]) or nil,
        }
    end
    return snapshot
end

function Diagnostics.Report(snapshot)
    local lines = { "StarskyUI " .. ns.VERSION .. " - local baseline", "Values are read-only. Loaded does not mean fully working." }
    local build = snapshot.build or {}
    lines[#lines + 1] = "Client: " .. ns.API.Text(build.version) .. " / interface " .. ns.API.Text(build.interface)
    lines[#lines + 1] = "Active native layout: " .. ns.API.Text(snapshot.layout)
    lines[#lines + 1] = "Native options:"
    for _, option in ipairs(snapshot.options) do
        lines[#lines + 1] = option.key .. " = " .. ns.API.Text(option.value)
    end
    lines[#lines + 1] = "Loaded providers:"
    for _, provider in ipairs(snapshot.providers) do
        local state = provider.loaded == nil and "unknown" or provider.loaded and "loaded" or "not loaded"
        lines[#lines + 1] = provider.addon .. " = " .. state
    end
    lines[#lines + 1] = "Leatrix parent options:"
    for _, gate in ipairs(snapshot.gates) do lines[#lines + 1] = gate.label .. " = " .. ns.API.Text(gate.value) end
    lines[#lines + 1] = "Ownership checks:"
    for _, conflict in ipairs(snapshot.conflicts) do lines[#lines + 1] = "- " .. conflict end
    if #snapshot.conflicts == 0 then lines[#lines + 1] = "No listed overlap detected. This is not a full compatibility test." end
    return table.concat(lines, "\n")
end
