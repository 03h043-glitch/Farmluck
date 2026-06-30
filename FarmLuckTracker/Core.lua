local addonName, ns = ...

local FLT = CreateFrame("Frame")
local FARMS = ns.Farms or {}
local FARM_BY_KEY = {}
for _, farm in ipairs(FARMS) do FARM_BY_KEY[farm.key] = farm end

local DEFAULT_DB = {
    scale = 1,
    width = 350,
    height = 320,
    locked = false,
    hidden = false,
    selectedKey = "golden-pearl",
    targetAmount = 1,
    point = { "CENTER", "CENTER", 0, 0 },
    customOdds = {},
}

local function copyDefaults(src, dst)
    dst = type(dst) == "table" and dst or {}
    for k, v in pairs(src) do
        if type(v) == "table" then dst[k] = copyDefaults(v, dst[k]) elseif dst[k] == nil then dst[k] = v end
    end
    return dst
end

local function trim(s) return (s or ""):match("^%s*(.-)%s*$") or "" end
local function lower(s) return string.lower(s or "") end
local function clamp(v, lo, hi) if v < lo then return lo elseif v > hi then return hi end return v end
local function pct(v) return v and string.format("%.2f%%", v * 100) or "--" end
local function rate(v) if not v then return "--" elseif v >= 1 then return string.format("%.2f", v) else return pct(v) end end
local function ratio(v) return v and string.format("%.2fx", v) or "--" end
local function round(v) if not v or v == math.huge or v ~= v then return "--" elseif v > 999 then return string.format("%.1fk", v / 1000) else return tostring(math.floor(v + 0.5)) end end
local function div(a, b) if not b or b <= 0 then return nil end return a / b end
local function show(frame, state) if state then frame:Show() else frame:Hide() end end

local function itemIdFromLink(link)
    local id = link and link:match("item:(%d+)")
    return id and tonumber(id) or nil
end

local function itemIdFromMsg(msg)
    local id = msg and msg:match("item:(%d+)")
    return id and tonumber(id) or nil
end

local function qtyFromMsg(msg)
    if not msg then return 1 end
    local qty = msg:match("|h%[.-%]|h|r%s*x(%d+)") or msg:match("%]%s*x(%d+)")
    return tonumber(qty) or 1
end

local function bagItemId(bag, slot)
    if C_Container and C_Container.GetContainerItemID then return C_Container.GetContainerItemID(bag, slot) end
    return itemIdFromLink(GetContainerItemLink and GetContainerItemLink(bag, slot))
end

local function spellNameFromSucceeded(...)
    local _, second, third, fourth, fifth = ...
    local spellID = type(fifth) == "number" and fifth or type(third) == "number" and third or type(fourth) == "number" and fourth
    if spellID and GetSpellInfo then
        local name = GetSpellInfo(spellID)
        if name then return name end
    end
    if type(second) == "string" and not second:find("%-") then return second end
    return nil
end

function FLT:Farm()
    return FARM_BY_KEY[self.db.selectedKey] or FARMS[1]
end

function FLT:Odds(farm)
    local c = self.db.customOdds[farm.key]
    if farm.mode == "twoStage" then
        return c and c.stage1 or farm.stage1.chance or 1, c and c.stage2 or farm.stage2.chance or 1
    end
    return c and c.chance or farm.chance or 1
end

function FLT:SaveOdds(farm, a, b)
    self.db.customOdds[farm.key] = self.db.customOdds[farm.key] or {}
    if farm.mode == "twoStage" then
        self.db.customOdds[farm.key].stage1 = a
        self.db.customOdds[farm.key].stage2 = b
    else
        self.db.customOdds[farm.key].chance = a
    end
end

function FLT:ChanceFromBox(box, fallback)
    local value = tonumber(trim(box:GetText()))
    if not value then return fallback end
    if value > 1 then value = value / 100 end
    return clamp(value, 0.000001, 10)
end

function FLT:Color(luck)
    local r, g, b = 0.10, 0.10, 0.10
    if luck and luck < 1 then
        local t = clamp(luck, 0, 1)
        r, g, b = 0.24 + (0.10 - 0.24) * t, 0.02 + (0.10 - 0.02) * t, 0.02 + (0.10 - 0.02) * t
    elseif luck and luck > 1 then
        local t = clamp((luck - 1) / 1.5, 0, 1)
        r, g, b = 0.10 + (0.95 - 0.10) * t, 0.10 + (0.62 - 0.10) * t, 0.10 + (0.05 - 0.10) * t
    end
    self.frame:SetBackdropColor(r, g, b, 0.94)
end

function FLT:Label(parent, template)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(false)
    return fs
end

function FLT:Button(parent, text, w, h)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w or 70, h or 22)
    b:SetText(text)
    return b
end

function FLT:Edit(parent, w)
    local e = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    e:SetSize(w or 80, 22)
    e:SetAutoFocus(false)
    e:SetFontObject("GameFontHighlightSmall")
    e:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
    e:SetScript("OnEnterPressed", function(box) box:ClearFocus() end)
    return e
end

function FLT:CreateUI()
    local template = BackdropTemplateMixin and "BackdropTemplate" or nil
    local f = CreateFrame("Frame", "FarmLuckTrackerFrame", UIParent, template)
    self.frame = f
    f:SetSize(self.db.width, self.db.height)
    f:SetScale(self.db.scale)
    f:SetMovable(true)
    f:SetResizable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    f:SetBackdropBorderColor(0.9, 0.72, 0.24, 0.85)
    if f.SetResizeBounds then f:SetResizeBounds(350, 320, 620, 520) elseif f.SetMinResize then f:SetMinResize(350, 320) end
    local p = self.db.point
    f:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    f:SetScript("OnDragStart", function() if not self.db.locked then f:StartMoving() end end)
    f:SetScript("OnDragStop", function() f:StopMovingOrSizing(); self:SavePosition() end)
    f:SetScript("OnSizeChanged", function(_, w, h) self.db.width, self.db.height = w, h; self:Layout() end)

    self.title = self:Label(f, "GameFontNormal")
    self.close = self:Button(f, "x", 22, 20)
    self.lock = self:Button(f, "L", 22, 20)
    self.search = self:Edit(f, 160)
    self.search:SetScript("OnTextChanged", function(_, user) if user then self:RefreshSearch() end end)
    self.close:SetScript("OnClick", function() self.db.hidden = true; f:Hide() end)
    self.lock:SetScript("OnClick", function() self.db.locked = not self.db.locked; self:Refresh() end)

    self.rows, self.setup = {}, {}
    for i = 1, 5 do
        local row = CreateFrame("Button", nil, f)
        row:SetHeight(18)
        row.text = self:Label(row)
        row.text:SetPoint("LEFT", 3, 0)
        row.text:SetPoint("RIGHT", -3, 0)
        row:SetScript("OnClick", function(btn) if btn.key then self:Select(btn.key) end end)
        self.rows[i] = row
        table.insert(self.setup, row)
    end

    self.selected = self:Label(f, "GameFontNormalSmall")
    self.locations = self:Label(f); self.locations:SetWordWrap(true)
    self.note = self:Label(f); self.note:SetWordWrap(true); self.note:SetTextColor(0.78, 0.78, 0.78)
    self.targetLabel = self:Label(f); self.target = self:Edit(f, 54)
    self.odds1Label = self:Label(f); self.odds1 = self:Edit(f, 54)
    self.odds2Label = self:Label(f); self.odds2 = self:Edit(f, 54)
    self.begin = self:Button(f, "Begin", 96, 30)
    self.begin:SetScript("OnClick", function() self:Begin() end)
    for _, obj in ipairs({ self.selected, self.locations, self.note, self.targetLabel, self.target, self.odds1Label, self.odds1, self.odds2Label, self.odds2, self.begin }) do table.insert(self.setup, obj) end

    self.sessionObjects, self.lines = {}, {}
    for i = 1, 8 do self.lines[i] = self:Label(f); table.insert(self.sessionObjects, self.lines[i]) end
    self.addTry = self:Button(f, "+", 64, 22); self.addTry:SetScript("OnClick", function() self:AddAttempt(1, true) end)
    self.subTry = self:Button(f, "- Try", 52, 22); self.subTry:SetScript("OnClick", function() self:AddAttempt(-1, true) end)
    self.addItem = self:Button(f, "+ Item", 58, 22); self.addItem:SetScript("OnClick", function() self:AddItem(1, true) end)
    self.subItem = self:Button(f, "- Item", 58, 22); self.subItem:SetScript("OnClick", function() self:AddItem(-1, true) end)
    self.endBtn = self:Button(f, "End", 70, 26); self.endBtn:SetScript("OnClick", function() self:End() end)
    for _, obj in ipairs({ self.addTry, self.subTry, self.addItem, self.subItem, self.endBtn }) do table.insert(self.sessionObjects, obj) end

    self:Layout(); self:Refresh(); show(f, not self.db.hidden)
end

function FLT:Layout()
    if not self.frame then return end
    local f, w, p = self.frame, self.frame:GetWidth(), 12
    self.title:ClearAllPoints(); self.title:SetPoint("TOPLEFT", p, -10); self.title:SetWidth(w - 92)
    self.close:ClearAllPoints(); self.close:SetPoint("TOPRIGHT", -p, -8)
    self.lock:ClearAllPoints(); self.lock:SetPoint("RIGHT", self.close, "LEFT", -4, 0)
    self.search:ClearAllPoints(); self.search:SetPoint("TOPLEFT", p, -34); self.search:SetPoint("TOPRIGHT", -p, -34)
    for i, row in ipairs(self.rows) do row:ClearAllPoints(); row:SetPoint("TOPLEFT", p, -62 - ((i - 1) * 19)); row:SetPoint("TOPRIGHT", -p, -62 - ((i - 1) * 19)) end
    self.selected:ClearAllPoints(); self.selected:SetPoint("TOPLEFT", p, -160); self.selected:SetPoint("TOPRIGHT", -p, -160)
    self.note:ClearAllPoints(); self.note:SetPoint("BOTTOMLEFT", p, 62); self.note:SetPoint("BOTTOMRIGHT", -p, 62); self.note:SetHeight(34)
    self.locations:ClearAllPoints(); self.locations:SetPoint("TOPLEFT", p, -180); self.locations:SetPoint("BOTTOMRIGHT", self.note, "TOPRIGHT", 0, 5)
    self.targetLabel:ClearAllPoints(); self.targetLabel:SetPoint("BOTTOMLEFT", p, 38); self.target:ClearAllPoints(); self.target:SetPoint("LEFT", self.targetLabel, "RIGHT", 8, 0)
    self.odds1Label:ClearAllPoints(); self.odds1Label:SetPoint("BOTTOMLEFT", p, 14); self.odds1:ClearAllPoints(); self.odds1:SetPoint("LEFT", self.odds1Label, "RIGHT", 8, 0)
    self.odds2Label:ClearAllPoints(); self.odds2Label:SetPoint("LEFT", self.odds1, "RIGHT", 12, 0); self.odds2:ClearAllPoints(); self.odds2:SetPoint("LEFT", self.odds2Label, "RIGHT", 8, 0)
    self.begin:ClearAllPoints(); self.begin:SetPoint("BOTTOMRIGHT", -p, 14)
    for i, line in ipairs(self.lines) do line:ClearAllPoints(); line:SetPoint("TOPLEFT", p, -42 - ((i - 1) * 19)); line:SetPoint("TOPRIGHT", -p, -42 - ((i - 1) * 19)) end
    self.addTry:ClearAllPoints(); self.addTry:SetPoint("BOTTOMLEFT", p, 14); self.subTry:ClearAllPoints(); self.subTry:SetPoint("LEFT", self.addTry, "RIGHT", 5, 0); self.addItem:ClearAllPoints(); self.addItem:SetPoint("LEFT", self.subTry, "RIGHT", 8, 0); self.subItem:ClearAllPoints(); self.subItem:SetPoint("LEFT", self.addItem, "RIGHT", 5, 0); self.endBtn:ClearAllPoints(); self.endBtn:SetPoint("BOTTOMRIGHT", -p, 14)
end

function FLT:SavePosition()
    local point, _, rel, x, y = self.frame:GetPoint(1)
    self.db.point = { point or "CENTER", rel or "CENTER", x or 0, y or 0 }
end

function FLT:Matches(q)
    q = lower(trim(q)); local out = {}
    if q == "" then for i = 1, math.min(5, #FARMS) do out[i] = FARMS[i] end return out end
    for _, farm in ipairs(FARMS) do
        local hay = lower((farm.name or "") .. " " .. tostring(farm.itemId or ""))
        for _, a in ipairs(farm.aliases or {}) do hay = hay .. " " .. lower(a) end
        if hay:find(q, 1, true) then table.insert(out, farm) end
    end
    return out
end

function FLT:RefreshSearch()
    local m = self:Matches(self.search:GetText())
    for i, row in ipairs(self.rows) do
        local farm = m[i]
        if farm then row.key = farm.key; row.text:SetText(farm.name); row:Show() else row.key = nil; row:Hide() end
    end
end

function FLT:Select(key)
    if not FARM_BY_KEY[key] then return end
    self.db.selectedKey = key
    self.search:SetText(FARM_BY_KEY[key].name)
    self.search:ClearFocus()
    self:Refresh()
end

function FLT:RefreshSetup()
    local farm = self:Farm(); if not farm then return end
    local a, b = self:Odds(farm)
    self.title:SetText("FarmLuck"); self.lock:SetText(self.db.locked and "U" or "L")
    self.selected:SetText(farm.name .. "  |  " .. (farm.sourceLabel or "Attempts"))
    self.targetLabel:SetText("Target"); self.target:SetText(tostring(self.db.targetAmount or 1))
    self.odds1Label:SetText(farm.mode == "twoStage" and "S1 %" or "Odds %"); self.odds1:SetText(string.format("%.3f", a * 100))
    if farm.mode == "twoStage" then self.odds2Label:Show(); self.odds2:Show(); self.odds2Label:SetText("S2 %"); self.odds2:SetText(string.format("%.3f", b * 100)) else self.odds2Label:Hide(); self.odds2:Hide() end
    self.locations:SetText(table.concat(farm.locations or {}, "\n"))
    self.note:SetText((farm.chanceLabel or (farm.stage1 and farm.stage1.chanceLabel) or "Odds") .. " - " .. (farm.oddsNote or "Editable estimate."))
    self:RefreshSearch(); self:Color(1)
end

function FLT:Refresh()
    local active = self.session ~= nil
    show(self.search, not active)
    for _, o in ipairs(self.setup) do show(o, not active) end
    for _, o in ipairs(self.sessionObjects) do show(o, active) end
    if active then self:RefreshSession() else self:RefreshSetup() end
end

function FLT:Begin()
    local farm = self:Farm(); if not farm then return end
    local target = math.max(1, math.floor((tonumber(trim(self.target:GetText())) or self.db.targetAmount or 1) + 0.5))
    local a, b = self:Odds(farm)
    a = self:ChanceFromBox(self.odds1, a)
    if farm.mode == "twoStage" then b = self:ChanceFromBox(self.odds2, b) end
    self.db.targetAmount = target; self:SaveOdds(farm, a, b)
    self.session = { farmKey = farm.key, startedAt = time(), targetAmount = target, attempts = 0, acquired = 0, stage1Count = 0, stage2Attempts = 0, manualAttempts = 0, manualItems = 0, chance = a, stage1Chance = a, stage2Chance = b }
    self.db.session = self.session
    self:Refresh()
end

function FLT:End()
    if not self.session then return end
    local farm = FARM_BY_KEY[self.session.farmKey]
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc33FarmLuck|r ended - " .. (farm and farm.name or "Session") .. ": " .. self.session.acquired .. "/" .. self.session.targetAmount)
    self.session = nil; self.db.session = nil; self:Refresh()
end

function FLT:AddAttempt(n, manual)
    if not self.session then return end
    self.session.attempts = math.max(0, self.session.attempts + n)
    if manual then self.session.manualAttempts = (self.session.manualAttempts or 0) + n end
    self.db.session = self.session; self:RefreshSession()
end

function FLT:AddItem(n, manual)
    if not self.session then return end
    self.session.acquired = math.max(0, self.session.acquired + n)
    if manual then self.session.manualItems = (self.session.manualItems or 0) + n end
    self.db.session = self.session; self:RefreshSession()
end

function FLT:AddStage1(n) if self.session then self.session.stage1Count = math.max(0, (self.session.stage1Count or 0) + n); self.db.session = self.session; self:RefreshSession() end end
function FLT:AddOpen(n) if self.session then self.session.stage2Attempts = math.max(0, (self.session.stage2Attempts or 0) + n); self.db.session = self.session; self:RefreshSession() end end

function FLT:Stats()
    local s = self.session; local farm = s and FARM_BY_KEY[s.farmKey]; if not farm then return end
    local st = { farm = farm, attempts = s.attempts or 0, acquired = s.acquired or 0, target = s.targetAmount or 1 }
    st.remaining = math.max(0, st.target - st.acquired)
    if farm.mode == "twoStage" then
        st.a, st.b = s.stage1Chance or 1, s.stage2Chance or 1; st.overall = st.a * st.b
        st.exp1, st.exp2, st.expAll = st.attempts * st.a, (s.stage2Attempts or 0) * st.b, st.attempts * st.overall
        st.r1, st.r2, st.rAll = div(s.stage1Count or 0, st.exp1), div(st.acquired, st.exp2), div(st.acquired, st.expAll)
        local held = math.max(0, (s.stage1Count or 0) - (s.stage2Attempts or 0))
        st.left = div(math.max(0, st.remaining - held * st.b), st.overall)
        st.luck = st.expAll >= 0.25 and st.rAll or st.exp1 >= 1 and st.r1 or 1
    else
        st.a = s.chance or farm.chance or 1; st.exp = st.attempts * st.a; st.obs = div(st.acquired, st.attempts); st.r = div(st.acquired, st.exp); st.left = div(st.remaining, st.a); st.luck = st.exp >= 0.25 and st.r or 1
    end
    return st
end

function FLT:RefreshSession()
    local st = self:Stats(); if not st then return end
    local s, farm = self.session, st.farm
    self.title:SetText(farm.name); self.lock:SetText(self.db.locked and "U" or "L"); self.addTry:SetText(farm.attemptButton or "+ Try")
    self.lines[1]:SetText("Goal " .. st.acquired .. "/" .. st.target .. " (" .. pct(st.acquired / st.target) .. ")")
    self.lines[2]:SetText((farm.sourceLabel or "Attempts") .. " " .. st.attempts .. "  |  Need about " .. round(st.left) .. " more")
    if farm.mode == "twoStage" then
        self.lines[3]:SetText((farm.stage1.label or "Stage 1") .. " " .. (s.stage1Count or 0) .. " / " .. round(st.exp1) .. " exp")
        self.lines[4]:SetText((farm.stage2.label or "Stage 2") .. " " .. st.acquired .. " / " .. round(st.exp2) .. " exp")
        self.lines[5]:SetText("Opened " .. (s.stage2Attempts or 0) .. "  |  Overall " .. rate(div(st.acquired, st.attempts)) .. " per attempt")
        self.lines[6]:SetText("Luck S1 " .. ratio(st.r1) .. "  |  S2 " .. ratio(st.r2) .. "  |  All " .. ratio(st.rAll))
        self.lines[7]:SetText("Odds " .. pct(st.a) .. " then " .. pct(st.b))
    else
        self.lines[3]:SetText((farm.targetLabel or "Items") .. " " .. st.acquired .. " / " .. round(st.exp) .. " exp  |  " .. rate(st.obs) .. " per attempt")
        self.lines[4]:SetText("Luck " .. ratio(st.r) .. "  |  Odds " .. pct(st.a))
        self.lines[5]:SetText(farm.oddsNote or "")
        self.lines[6]:SetText("Manual " .. (s.manualAttempts or 0) .. " tries, " .. (s.manualItems or 0) .. " items")
    end
    self.lines[8]:SetText("")
    self:Color(st.luck)
end

function FLT:Loot(msg)
    if not self.session then return end
    local farm = FARM_BY_KEY[self.session.farmKey]; local id = itemIdFromMsg(msg); if not farm or not id then return end
    local q = qtyFromMsg(msg)
    if farm.mode == "twoStage" and farm.stage1 and id == farm.stage1.itemId then self:AddStage1(q) end
    if id == farm.itemId then self:AddItem(q, false) end
end

function FLT:ContainerUse(bag, slot)
    local farm = self.session and FARM_BY_KEY[self.session.farmKey]
    if not farm or farm.mode ~= "twoStage" or not farm.stage2 then return end
    if bagItemId(bag, slot) == farm.stage2.sourceItemId then self:AddOpen(1) end
end

function FLT:Gather(spell)
    local farm = self.session and FARM_BY_KEY[self.session.farmKey]
    if not farm or not farm.gatherSpells then return end
    for _, name in ipairs(farm.gatherSpells) do if spell == name then self:AddAttempt(1, false); return end end
end

function FLT:Slash(msg)
    local cmd, rest = trim(msg):match("^(%S*)%s*(.-)$"); cmd = lower(cmd)
    if cmd == "" or cmd == "toggle" then self.db.hidden = self.frame:IsShown(); show(self.frame, not self.db.hidden)
    elseif cmd == "show" then self.db.hidden = false; self.frame:Show()
    elseif cmd == "hide" then self.db.hidden = true; self.frame:Hide()
    elseif cmd == "lock" then self.db.locked = true; self:Refresh()
    elseif cmd == "unlock" then self.db.locked = false; self:Refresh()
    elseif cmd == "scale" then local s = tonumber(rest); if s then self.db.scale = clamp(s, 0.5, 2.5); self.frame:SetScale(self.db.scale) end
    elseif cmd == "end" then self:End()
    else DEFAULT_CHAT_FRAME:AddMessage("|cffffcc33FarmLuck|r /flt show, hide, lock, unlock, scale <n>, end") end
end

function FLT:Loaded(name)
    if name ~= addonName then return end
    FarmLuckTrackerDB = copyDefaults(DEFAULT_DB, FarmLuckTrackerDB)
    self.db = FarmLuckTrackerDB
    if self.db.session and FARM_BY_KEY[self.db.session.farmKey] then self.session = self.db.session end
    self:CreateUI()
    SLASH_FARMLUCKTRACKER1 = "/flt"; SLASH_FARMLUCKTRACKER2 = "/farmluck"
    SlashCmdList.FARMLUCKTRACKER = function(msg) self:Slash(msg) end
    if C_Container and C_Container.UseContainerItem then hooksecurefunc(C_Container, "UseContainerItem", function(bag, slot) self:ContainerUse(bag, slot) end) end
    if UseContainerItem then hooksecurefunc("UseContainerItem", function(bag, slot) self:ContainerUse(bag, slot) end) end
end

FLT:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then self:Loaded(...)
    elseif event == "CHAT_MSG_LOOT" then self:Loot(...)
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subevent = CombatLogGetCurrentEventInfo and CombatLogGetCurrentEventInfo() or ...
        local farm = self.session and FARM_BY_KEY[self.session.farmKey]
        if subevent == "PARTY_KILL" and farm and farm.sourceKind == "kill" then self:AddAttempt(1, false) end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then local unit = ...; if unit == "player" then self:Gather(spellNameFromSucceeded(...)) end
    elseif event == "PLAYER_LOGOUT" then self.db.session = self.session; self:SavePosition() end
end)

FLT:RegisterEvent("ADDON_LOADED")
FLT:RegisterEvent("CHAT_MSG_LOOT")
FLT:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
FLT:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
FLT:RegisterEvent("PLAYER_LOGOUT")
