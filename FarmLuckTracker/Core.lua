local addonName, ns = ...

local FLT = CreateFrame("Frame")
ns.Core = FLT

local FARMS = ns.Farms or {}
local BY_KEY = {}
for _, farm in ipairs(FARMS) do BY_KEY[farm.key] = farm end

local DEFAULT_DB = { scale = 1, width = 350, height = 320, locked = false, hidden = false, selectedKey = "golden-pearl", targetAmount = 1, point = { "CENTER", "CENTER", 0, 0 }, customOdds = {} }
local XP_PENDING_TTL = 6
local MOB_HINT_TTL = 10

local function defaults(src, dst)
    dst = type(dst) == "table" and dst or {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            dst[k] = defaults(v, dst[k])
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end

local function trim(s) return (s or ""):match("^%s*(.-)%s*$") or "" end
local function lower(s) return string.lower(s or "") end
local function clamp(v, lo, hi) if v < lo then return lo elseif v > hi then return hi end return v end
local function pct(v) return v and string.format("%.2f%%", v * 100) or "--" end
local function div(a, b) return b and b > 0 and a / b or nil end
local function num(v) if not v or v == math.huge or v ~= v then return "--" elseif v > 999 then return string.format("%.1fk", v / 1000) else return tostring(math.floor(v + 0.5)) end end
local function rate(v) return not v and "--" or v >= 1 and string.format("%.2f", v) or pct(v) end
local function ratio(v) return v and string.format("%.2fx", v) or "--" end
local function show(f, yes) if yes then f:Show() else f:Hide() end end
local function now() return (GetTime and GetTime()) or time() or 0 end
local function playerLevel() return (UnitLevel and tonumber(UnitLevel("player"))) or 0 end
local function parseNumber(value) if not value then return nil end; value = tostring(value):gsub(",", ""); return tonumber(value) end
local function currentXPState()
    local rested = GetXPExhaustion and GetXPExhaustion() or nil
    return playerLevel(), (UnitXP and UnitXP("player")) or 0, (UnitXPMax and UnitXPMax("player")) or 0, rested
end
local function itemFromMsg(msg) local id = msg and msg:match("item:(%d+)"); return id and tonumber(id) or nil end
local function qtyFromMsg(msg) local q = msg and (msg:match("|h%[.-%]|h|r%s*x(%d+)") or msg:match("%]%s*x(%d+)")); return tonumber(q) or 1 end
local function ownLoot(msg) msg = tostring(msg or ""); if msg:find("^You ") then return true end; local name = UnitName and UnitName("player"); return name and msg:find(name, 1, true) and true or false end
local function itemFromBag(bag, slot) if C_Container and C_Container.GetContainerItemID then return C_Container.GetContainerItemID(bag, slot) end; local link = GetContainerItemLink and GetContainerItemLink(bag, slot); local id = link and link:match("item:(%d+)"); return id and tonumber(id) or nil end
local function spellName(...) local _, second, third, fourth, fifth = ...; local id = type(fifth) == "number" and fifth or type(third) == "number" and third or type(fourth) == "number" and fourth; if id and GetSpellInfo then local name = GetSpellInfo(id); if name then return name end end; return type(second) == "string" and second or nil end

local function rangeText(farm)
    if not farm then return nil end
    if farm.levelMin and farm.levelMax then return "L" .. farm.levelMin .. "-" .. farm.levelMax end
    if farm.levelMin then return "L" .. farm.levelMin .. "+" end
    if farm.levelMax then return "up to L" .. farm.levelMax end
    return nil
end

local function levelDistance(farm, level)
    if not farm or not level or level <= 0 then return 500 end
    local minLevel, maxLevel = tonumber(farm.levelMin), tonumber(farm.levelMax)
    if not minLevel and not maxLevel then return 400 end
    minLevel, maxLevel = minLevel or 1, maxLevel or 60
    if level >= minLevel and level <= maxLevel then return 0 end
    if level < minLevel then return minLevel - level end
    return level - maxLevel
end

function FLT:Farm() return BY_KEY[self.db.selectedKey] or FARMS[1] end
function FLT:FarmLabel(farm)
    if not farm then return "" end
    local label = farm.name or "Farm"
    local r = rangeText(farm)
    if r then label = label .. " (" .. r .. ")" end
    return label
end
function FLT:Odds(farm) local c = self.db.customOdds[farm.key]; if farm.mode == "twoStage" then return c and c.stage1 or farm.stage1.chance or 1, c and c.stage2 or farm.stage2.chance or 1 end; return c and c.chance or farm.chance or 1 end
function FLT:SaveOdds(farm, a, b) self.db.customOdds[farm.key] = self.db.customOdds[farm.key] or {}; if farm.mode == "twoStage" then self.db.customOdds[farm.key].stage1 = a; self.db.customOdds[farm.key].stage2 = b else self.db.customOdds[farm.key].chance = a end end
function FLT:Chance(box, fallback) local v = tonumber(trim(box:GetText())); if not v then return fallback end; if v > 1 then v = v / 100 end; return clamp(v, 0.000001, 10) end

function FLT:Color(luck)
    if not self.frame then return end
    luck = luck or 1
    local r, g, b = 0.10, 0.10, 0.10
    if luck < 1 then
        local t = clamp(luck, 0, 1)
        r, g, b = 0.34 + (0.10 - 0.34) * t, 0.015 + (0.10 - 0.015) * t, 0.015 + (0.10 - 0.015) * t
    elseif luck > 1 then
        local t = clamp((luck - 1) / 2, 0, 1)
        r, g, b = 0.10 + (0.96 - 0.10) * t, 0.10 + (0.64 - 0.10) * t, 0.10 + (0.04 - 0.10) * t
    end
    self.frame:SetBackdropColor(r, g, b, 0.94)
    self.frame:SetBackdropBorderColor(math.min(r + 0.28, 1), math.min(g + 0.22, 1), math.min(b + 0.12, 1), 0.9)
end

function FLT:Label(parent, template) local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall"); fs:SetJustifyH("LEFT"); fs:SetWordWrap(false); return fs end
function FLT:Button(parent, text, w, h) local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate"); b:SetSize(w or 70, h or 22); b:SetText(text); return b end
function FLT:Edit(parent, w) local e = CreateFrame("EditBox", nil, parent, "InputBoxTemplate"); e:SetSize(w or 80, 22); e:SetAutoFocus(false); e:SetFontObject("GameFontHighlightSmall"); e:SetScript("OnEscapePressed", function(x) x:ClearFocus() end); e:SetScript("OnEnterPressed", function(x) x:ClearFocus() end); return e end

function FLT:CreateUI()
    local template = BackdropTemplateMixin and "BackdropTemplate" or nil
    local f = CreateFrame("Frame", "FarmLuckTrackerFrame", UIParent, template); self.frame = f
    f:SetSize(self.db.width, self.db.height); f:SetScale(self.db.scale); f:SetMovable(true); f:SetResizable(true); f:SetClampedToScreen(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    f:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    local p = self.db.point; f:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    f:SetScript("OnDragStart", function() if not self.db.locked then f:StartMoving() end end); f:SetScript("OnDragStop", function() f:StopMovingOrSizing(); self:SavePos() end); f:SetScript("OnSizeChanged", function(_, w, h) self.db.width, self.db.height = w, h; self:Layout() end)
    self.title = self:Label(f, "GameFontNormal"); self.close = self:Button(f, "x", 22, 20); self.lock = self:Button(f, "L", 22, 20); self.search = self:Edit(f, 160)
    self.close:SetScript("OnClick", function() self.db.hidden = true; f:Hide() end); self.lock:SetScript("OnClick", function() self.db.locked = not self.db.locked; self:Refresh() end); self.search:SetScript("OnTextChanged", function(_, user) if user then self:RefreshSearch() end end)
    self.rows, self.setup = {}, {}
    for i = 1, 5 do local row = CreateFrame("Button", nil, f); row:SetHeight(18); row.text = self:Label(row); row.text:SetPoint("LEFT", 3, 0); row.text:SetPoint("RIGHT", -3, 0); row:SetScript("OnClick", function(x) if x.key then self:Select(x.key) end end); self.rows[i] = row; table.insert(self.setup, row) end
    self.selected = self:Label(f, "GameFontNormalSmall"); self.locations = self:Label(f); self.locations:SetWordWrap(true); self.note = self:Label(f); self.note:SetWordWrap(true); self.note:SetTextColor(0.78, 0.78, 0.78)
    self.targetLabel = self:Label(f); self.target = self:Edit(f, 54); self.odds1Label = self:Label(f); self.odds1 = self:Edit(f, 54); self.odds2Label = self:Label(f); self.odds2 = self:Edit(f, 54); self.begin = self:Button(f, "Begin", 96, 30); self.begin:SetScript("OnClick", function() self:Begin() end)
    for _, o in ipairs({ self.selected, self.locations, self.note, self.targetLabel, self.target, self.odds1Label, self.odds1, self.odds2Label, self.odds2, self.begin }) do table.insert(self.setup, o) end
    self.sessionObjects, self.lines = {}, {}; for i = 1, 8 do self.lines[i] = self:Label(f); table.insert(self.sessionObjects, self.lines[i]) end
    self.addTry = self:Button(f, "+", 64, 22); self.addTry:SetScript("OnClick", function() self:AddAttempt(1, true) end); self.subTry = self:Button(f, "- Try", 52, 22); self.subTry:SetScript("OnClick", function() self:AddAttempt(-1, true) end); self.addItem = self:Button(f, "+ Item", 58, 22); self.addItem:SetScript("OnClick", function() self:AddItem(1, true) end); self.subItem = self:Button(f, "- Item", 58, 22); self.subItem:SetScript("OnClick", function() self:AddItem(-1, true) end); self.endBtn = self:Button(f, "End", 70, 26); self.endBtn:SetScript("OnClick", function() self:End() end)
    for _, o in ipairs({ self.addTry, self.subTry, self.addItem, self.subItem, self.endBtn }) do table.insert(self.sessionObjects, o) end
    self:Layout(); self:Refresh(); show(f, not self.db.hidden)
end

function FLT:Layout()
    if not self.frame then return end; local p, w = 12, self.frame:GetWidth()
    self.title:ClearAllPoints(); self.title:SetPoint("TOPLEFT", p, -10); self.title:SetWidth(w - 92); self.close:ClearAllPoints(); self.close:SetPoint("TOPRIGHT", -p, -8); self.lock:ClearAllPoints(); self.lock:SetPoint("RIGHT", self.close, "LEFT", -4, 0); self.search:ClearAllPoints(); self.search:SetPoint("TOPLEFT", p, -34); self.search:SetPoint("TOPRIGHT", -p, -34)
    for i, row in ipairs(self.rows) do row:ClearAllPoints(); row:SetPoint("TOPLEFT", p, -62 - ((i - 1) * 19)); row:SetPoint("TOPRIGHT", -p, -62 - ((i - 1) * 19)) end
    self.selected:ClearAllPoints(); self.selected:SetPoint("TOPLEFT", p, -160); self.selected:SetPoint("TOPRIGHT", -p, -160); self.note:ClearAllPoints(); self.note:SetPoint("BOTTOMLEFT", p, 62); self.note:SetPoint("BOTTOMRIGHT", -p, 62); self.note:SetHeight(34); self.locations:ClearAllPoints(); self.locations:SetPoint("TOPLEFT", p, -180); self.locations:SetPoint("BOTTOMRIGHT", self.note, "TOPRIGHT", 0, 5)
    self.targetLabel:ClearAllPoints(); self.targetLabel:SetPoint("BOTTOMLEFT", p, 38); self.target:ClearAllPoints(); self.target:SetPoint("LEFT", self.targetLabel, "RIGHT", 8, 0); self.odds1Label:ClearAllPoints(); self.odds1Label:SetPoint("BOTTOMLEFT", p, 14); self.odds1:ClearAllPoints(); self.odds1:SetPoint("LEFT", self.odds1Label, "RIGHT", 8, 0); self.odds2Label:ClearAllPoints(); self.odds2Label:SetPoint("LEFT", self.odds1, "RIGHT", 12, 0); self.odds2:ClearAllPoints(); self.odds2:SetPoint("LEFT", self.odds2Label, "RIGHT", 8, 0); self.begin:ClearAllPoints(); self.begin:SetPoint("BOTTOMRIGHT", -p, 14)
    for i, line in ipairs(self.lines) do line:ClearAllPoints(); line:SetPoint("TOPLEFT", p, -42 - ((i - 1) * 19)); line:SetPoint("TOPRIGHT", -p, -42 - ((i - 1) * 19)) end
    self.addTry:ClearAllPoints(); self.addTry:SetPoint("BOTTOMLEFT", p, 14); self.subTry:ClearAllPoints(); self.subTry:SetPoint("LEFT", self.addTry, "RIGHT", 5, 0); self.addItem:ClearAllPoints(); self.addItem:SetPoint("LEFT", self.subTry, "RIGHT", 8, 0); self.subItem:ClearAllPoints(); self.subItem:SetPoint("LEFT", self.addItem, "RIGHT", 5, 0); self.endBtn:ClearAllPoints(); self.endBtn:SetPoint("BOTTOMRIGHT", -p, 14)
end

function FLT:SavePos() local point, _, rel, x, y = self.frame:GetPoint(1); self.db.point = { point or "CENTER", rel or "CENTER", x or 0, y or 0 } end
function FLT:Find(q)
    q = lower(trim(q)); local out, level = {}, playerLevel()
    for _, f in ipairs(FARMS) do
        local h = lower((f.name or "") .. " " .. tostring(f.itemId or "") .. " " .. (f.routeName or "") .. " " .. (f.stage1 and f.stage1.name or ""))
        for _, a in ipairs(f.aliases or {}) do h = h .. " " .. lower(a) end
        if q == "" or h:find(q, 1, true) then table.insert(out, f) end
    end
    table.sort(out, function(a, b)
        local da, db = levelDistance(a, level), levelDistance(b, level)
        if da ~= db then return da < db end
        local am, bm = tonumber(a.levelMin) or 0, tonumber(b.levelMin) or 0
        if am ~= bm then return am < bm end
        return (a.name or "") < (b.name or "")
    end)
    return out
end
function FLT:RefreshSearch() local m = self:Find(self.search:GetText()); for i, row in ipairs(self.rows) do local f = m[i]; if f then row.key = f.key; row.text:SetText(self:FarmLabel(f)); row:Show() else row.key = nil; row:Hide() end end end
function FLT:Select(key) if BY_KEY[key] then self.db.selectedKey = key; self.search:SetText(self:FarmLabel(BY_KEY[key])); self.search:ClearFocus(); self:Refresh() end end

function FLT:RouteText(f)
    local rows, level = {}, playerLevel()
    local r = rangeText(f)
    if r then table.insert(rows, "Recommended " .. r .. (level > 0 and ("  |  You L" .. level) or "")) end
    for _, loc in ipairs(f.locations or {}) do table.insert(rows, loc) end
    return table.concat(rows, "\n")
end

function FLT:RefreshSetup()
    local f = self:Farm(); if not f then return end; local a, b = self:Odds(f)
    self.title:SetText("FarmLuck"); self.lock:SetText(self.db.locked and "U" or "L"); self.selected:SetText(self:FarmLabel(f) .. "  |  " .. (f.sourceLabel or "Attempts")); self.targetLabel:SetText("Target"); self.target:SetText(tostring(self.db.targetAmount or 1)); self.odds1Label:SetText(f.mode == "twoStage" and "S1 %" or "Odds %"); self.odds1:SetText(string.format("%.3f", a * 100))
    if f.mode == "twoStage" then self.odds2Label:Show(); self.odds2:Show(); self.odds2Label:SetText("S2 %"); self.odds2:SetText(string.format("%.3f", b * 100)) else self.odds2Label:Hide(); self.odds2:Hide() end
    self.locations:SetText(self:RouteText(f)); self.note:SetText((f.chanceLabel or f.stage1 and f.stage1.chanceLabel or "Odds") .. " - " .. (f.oddsNote or "Editable estimate.")); self:RefreshSearch(); self:Color(1)
end
function FLT:Refresh() local active = self.session ~= nil; show(self.search, not active); for _, o in ipairs(self.setup) do show(o, not active) end; for _, o in ipairs(self.sessionObjects) do show(o, active) end; if active then self:RefreshSession() else self:RefreshSetup() end end

function FLT:Begin() local f = self:Farm(); if not f then return end; local target = math.max(1, math.floor((tonumber(trim(self.target:GetText())) or self.db.targetAmount or 1) + 0.5)); local a, b = self:Odds(f); a = self:Chance(self.odds1, a); if f.mode == "twoStage" then b = self:Chance(self.odds2, b) end; self.db.targetAmount = target; self:SaveOdds(f, a, b); self:SnapshotXP(); self.session = { farmKey = f.key, startedAt = time(), targetAmount = target, attempts = 0, acquired = 0, stage1Count = 0, stage2Attempts = 0, manualAttempts = 0, manualItems = 0, chance = a, stage1Chance = a, stage2Chance = b, xpKills = 0, mobKills = {} }; self.db.session = self.session; self:Refresh() end
function FLT:End() if not self.session then return end; local f = BY_KEY[self.session.farmKey]; DEFAULT_CHAT_FRAME:AddMessage("|cffffcc33FarmLuck|r ended - " .. (f and f.name or "Session") .. ": " .. self.session.acquired .. "/" .. self.session.targetAmount); self.session = nil; self.db.session = nil; self:Refresh() end
function FLT:AddAttempt(n, manual) if self.session then self.session.attempts = math.max(0, (self.session.attempts or 0) + n); if manual then self.session.manualAttempts = (self.session.manualAttempts or 0) + n end; self.db.session = self.session; self:RefreshSession() end end
function FLT:AddItem(n, manual) if self.session then self.session.acquired = math.max(0, (self.session.acquired or 0) + n); if manual then self.session.manualItems = (self.session.manualItems or 0) + n end; self.db.session = self.session; self:RefreshSession() end end
function FLT:AddStage1(n) if self.session then self.session.stage1Count = math.max(0, (self.session.stage1Count or 0) + n); self.db.session = self.session; self:RefreshSession() end end
function FLT:AddOpen(n) if self.session then self.session.stage2Attempts = math.max(0, (self.session.stage2Attempts or 0) + n); self.db.session = self.session; self:RefreshSession() end end

function FLT:Stats()
    local s = self.session; local f = s and BY_KEY[s.farmKey]; if not f then return end; local st = { farm = f, attempts = s.attempts or 0, acquired = s.acquired or 0, target = s.targetAmount or 1 }; st.remaining = math.max(0, st.target - st.acquired)
    if f.mode == "twoStage" then
        st.a, st.b = s.stage1Chance or 1, s.stage2Chance or 1; st.overall = st.a * st.b; st.exp1, st.exp2, st.expAll = st.attempts * st.a, (s.stage2Attempts or 0) * st.b, st.attempts * st.overall; st.r1, st.r2, st.rAll = div(s.stage1Count or 0, st.exp1), div(st.acquired, st.exp2), div(st.acquired, st.expAll); local held = math.max(0, (s.stage1Count or 0) - (s.stage2Attempts or 0)); st.left = div(math.max(0, st.remaining - held * st.b), st.overall)
        local value, weight = 0, 0
        local w1 = math.min(st.exp1 or 0, 8); if w1 >= 0.15 and st.r1 then value, weight = value + st.r1 * w1, weight + w1 end
        local w2 = math.min((st.exp2 or 0) * 4, 8); if w2 >= 0.2 and st.r2 then value, weight = value + st.r2 * w2, weight + w2 end
        local w3 = math.min((st.expAll or 0) * 4, 8); if w3 >= 0.2 and st.rAll then value, weight = value + st.rAll * w3, weight + w3 end
        st.luck = weight > 0 and value / weight or 1
    else
        st.a = s.chance or f.chance or 1; st.exp = st.attempts * st.a; st.obs = div(st.acquired, st.attempts); st.r = div(st.acquired, st.exp); st.left = div(st.remaining, st.a); st.luck = st.exp >= 0.15 and st.r or 1
    end
    return st
end

function FLT:RefreshSession()
    local st = self:Stats(); if not st then return end; local s, f = self.session, st.farm; self.title:SetText(self:FarmLabel(f)); self.lock:SetText(self.db.locked and "U" or "L"); self.addTry:SetText(f.attemptButton or "+ Try"); self.lines[1]:SetText("Goal " .. st.acquired .. "/" .. st.target .. " (" .. pct(st.acquired / st.target) .. ")"); self.lines[2]:SetText((f.sourceLabel or "Attempts") .. " " .. st.attempts .. "  |  Need about " .. num(st.left) .. " more")
    if f.mode == "twoStage" then self.lines[3]:SetText((f.stage1.label or "Stage 1") .. " " .. (s.stage1Count or 0) .. " / " .. num(st.exp1) .. " exp"); self.lines[4]:SetText((f.stage2.label or "Stage 2") .. " " .. st.acquired .. " / " .. num(st.exp2) .. " exp"); self.lines[5]:SetText("Opened " .. (s.stage2Attempts or 0) .. "  |  Overall " .. rate(div(st.acquired, st.attempts)) .. " per kill"); self.lines[6]:SetText("Luck S1 " .. ratio(st.r1) .. "  |  S2 " .. ratio(st.r2) .. "  |  All " .. ratio(st.rAll)); self.lines[7]:SetText("Odds " .. pct(st.a) .. " then " .. pct(st.b)) else self.lines[3]:SetText((f.targetLabel or "Items") .. " " .. st.acquired .. " / " .. num(st.exp) .. " exp  |  " .. rate(st.obs) .. " per attempt"); self.lines[4]:SetText("Luck " .. ratio(st.r) .. "  |  Odds " .. pct(st.a)); self.lines[5]:SetText(f.oddsNote or ""); self.lines[6]:SetText("Manual " .. (s.manualAttempts or 0) .. " tries, " .. (s.manualItems or 0) .. " items"); self.lines[7]:SetText("") end
    local last = s.lastMobName and ("  |  Last " .. s.lastMobName .. (s.lastMobLevel and (" L" .. s.lastMobLevel) or "")) or ""
    self.lines[8]:SetText("Auto XP kills " .. (s.xpKills or 0) .. last); self:Color(st.luck)
end

function FLT:SnapshotXP()
    self.pendingXP = {}
    self.lastXPLevel, self.lastXP, self.lastXPMax, self.lastRested = currentXPState()
end

function FLT:AddPendingXP(source, amount, rested, context)
    self.pendingXP = self.pendingXP or {}
    table.insert(self.pendingXP, { source = source or "OTHER", amount = amount and math.floor(amount) or nil, rested = rested and math.floor(rested) or nil, context = context or {}, time = now() })
end

function FLT:PrunePendingXP(t)
    self.pendingXP = self.pendingXP or {}
    for i = #self.pendingXP, 1, -1 do if t - (self.pendingXP[i].time or 0) > XP_PENDING_TTL then table.remove(self.pendingXP, i) end end
end

function FLT:ConsumePendingXP(delta)
    local t = now(); self:PrunePendingXP(t)
    for i = #self.pendingXP, 1, -1 do local p = self.pendingXP[i]; if p.amount and math.abs(p.amount - delta) <= math.max(2, math.floor(delta * 0.02)) then table.remove(self.pendingXP, i); return p end end
    for i = #self.pendingXP, 1, -1 do local p = self.pendingXP[i]; if not p.amount and t - (p.time or 0) <= 3 then table.remove(self.pendingXP, i); return p end end
    return nil
end

function FLT:RememberUnit(unit)
    if not UnitName or not UnitLevel then return end
    if UnitExists and not UnitExists(unit) then return end
    if UnitCanAttack and not UnitCanAttack("player", unit) then return end
    local name = UnitName(unit); name = trim(name)
    local level = tonumber(UnitLevel(unit))
    if name == "" or not level or level <= 0 then return end
    self.recentUnits = self.recentUnits or {}
    local t = now()
    self.recentUnits[name] = { level = level, time = t }
    self.lastHostile = { name = name, level = level, time = t }
end

function FLT:ResolveMobContext(context)
    context = context or {}
    local t = now()
    self.recentUnits = self.recentUnits or {}
    if context.mobName then
        local remembered = self.recentUnits[context.mobName]
        if remembered and t - (remembered.time or 0) <= MOB_HINT_TTL then context.mobLevel = context.mobLevel or remembered.level end
    elseif self.lastHostile and t - (self.lastHostile.time or 0) <= MOB_HINT_TTL then
        context.mobName, context.mobLevel = self.lastHostile.name, self.lastHostile.level
    end
    return context
end

function FLT:ParseCombatXP(message)
    message = tostring(message or "")
    local lowerMsg = lower(message)
    local amount = parseNumber(message:match("([%d,]+)%s+experience"))
    local rested = parseNumber(message:match("%+([%d,]+)%s+exp%s+Rested"))
    local source, mobName = "OTHER", nil
    if lowerMsg:find(" dies", 1, true) or lowerMsg:find(" slain", 1, true) then
        source = "KILL"
        mobName = trim(message:match("^(.-)%s+dies") or message:match("^(.-)%s+is slain"))
        if mobName == "" then mobName = nil end
    elseif lowerMsg:find("discovered", 1, true) or lowerMsg:find("discover", 1, true) then
        source = "EXPLORATION"
    end
    return source, amount, rested, self:ResolveMobContext({ message = message, mobName = mobName })
end

function FLT:OnCombatXPGain(message)
    local source, amount, rested, context = self:ParseCombatXP(message)
    if amount and amount > 0 then self:AddPendingXP(source, amount, rested, context) end
end

function FLT:OnPlayerXPUpdate(unit)
    if unit and unit ~= "player" then return end
    local level, xp, xpMax, rested = currentXPState()
    if not self.lastXPLevel then self:SnapshotXP(); return end
    local delta = 0
    if level == self.lastXPLevel then delta = xp - (self.lastXP or 0) elseif level > self.lastXPLevel then delta = ((self.lastXPMax or 0) - (self.lastXP or 0)) + xp else self:SnapshotXP(); return end
    if delta > 0 then
        local pending = self:ConsumePendingXP(delta)
        if pending and pending.source == "KILL" then self:RecordKillAttempt(pending.context or {}) end
    end
    self.lastXPLevel, self.lastXP, self.lastXPMax, self.lastRested = level, xp, xpMax, rested
end

function FLT:RecordKillAttempt(context)
    local f = self.session and BY_KEY[self.session.farmKey]
    if not f or f.sourceKind ~= "kill" then return end
    local s = self.session
    context = self:ResolveMobContext(context)
    s.xpKills = (s.xpKills or 0) + 1
    if context.mobName then
        s.mobKills = s.mobKills or {}
        s.mobKills[context.mobName] = (s.mobKills[context.mobName] or 0) + 1
        s.lastMobName = context.mobName
        s.lastMobLevel = context.mobLevel
        if context.mobLevel then s.minMobLevel = math.min(s.minMobLevel or context.mobLevel, context.mobLevel); s.maxMobLevel = math.max(s.maxMobLevel or context.mobLevel, context.mobLevel) end
    end
    self.lastXPRecordedAt = now()
    self:AddAttempt(1, false)
end

function FLT:PartyKillFallback()
    local f = self.session and BY_KEY[self.session.farmKey]
    if not f or f.sourceKind ~= "kill" then return end
    if playerLevel() < 60 then return end
    if now() - (self.lastXPRecordedAt or 0) < 1.5 then return end
    self:RecordKillAttempt({ message = "PARTY_KILL fallback" })
end

function FLT:Loot(msg)
    if not self.session or not ownLoot(msg) then return end
    local f, id = BY_KEY[self.session.farmKey], itemFromMsg(msg); if not f or not id then return end
    local q = qtyFromMsg(msg); if f.mode == "twoStage" and f.stage1 and id == f.stage1.itemId then self:AddStage1(q) end; if id == f.itemId then self:AddItem(q, false) end
end
function FLT:ContainerUse(bag, slot) local f = self.session and BY_KEY[self.session.farmKey]; if f and f.mode == "twoStage" and f.stage2 and itemFromBag(bag, slot) == f.stage2.sourceItemId then self:AddOpen(1) end end
function FLT:Gather(name) local f = self.session and BY_KEY[self.session.farmKey]; if not f or not f.gatherSpells then return end; for _, spell in ipairs(f.gatherSpells) do if name == spell then self:AddAttempt(1, false); return end end end
function FLT:Slash(msg)
    local cmd, rest = trim(msg):match("^(%S*)%s*(.-)$"); cmd = lower(cmd)
    if cmd == "" or cmd == "toggle" then self.db.hidden = self.frame:IsShown(); show(self.frame, not self.db.hidden) elseif cmd == "show" then self.db.hidden = false; self.frame:Show() elseif cmd == "hide" then self.db.hidden = true; self.frame:Hide() elseif cmd == "lock" then self.db.locked = true; self:Refresh() elseif cmd == "unlock" then self.db.locked = false; self:Refresh() elseif cmd == "scale" then local s = tonumber(rest); if s then self.db.scale = clamp(s, 0.5, 2.5); self.frame:SetScale(self.db.scale) end elseif cmd == "reset" then self.db.scale = 1; self.db.width = DEFAULT_DB.width; self.db.height = DEFAULT_DB.height; self.db.point = { "CENTER", "CENTER", 0, 0 }; self.frame:SetScale(1); self.frame:SetSize(self.db.width, self.db.height); self.frame:ClearAllPoints(); self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0); self:Refresh() elseif cmd == "end" then self:End() else DEFAULT_CHAT_FRAME:AddMessage("|cffffcc33FarmLuck|r /flt show, hide, lock, unlock, reset, scale <n>, end") end
end

function FLT:Loaded(name)
    if name ~= addonName then return end
    FarmLuckTrackerDB = defaults(DEFAULT_DB, FarmLuckTrackerDB); self.db = FarmLuckTrackerDB; if self.db.session and BY_KEY[self.db.session.farmKey] then self.session = self.db.session end; self.pendingXP = {}; self.recentUnits = {}; self:SnapshotXP(); self:CreateUI(); SLASH_FARMLUCKTRACKER1 = "/flt"; SLASH_FARMLUCKTRACKER2 = "/farmluck"; SlashCmdList.FARMLUCKTRACKER = function(msg) self:Slash(msg) end; if C_Container and C_Container.UseContainerItem then hooksecurefunc(C_Container, "UseContainerItem", function(bag, slot) self:ContainerUse(bag, slot) end) end; if UseContainerItem then hooksecurefunc("UseContainerItem", function(bag, slot) self:ContainerUse(bag, slot) end) end
end

FLT:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then self:Loaded(...)
    elseif event == "PLAYER_LOGIN" then self:SnapshotXP()
    elseif event == "PLAYER_XP_UPDATE" then self:OnPlayerXPUpdate(...)
    elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then self:OnCombatXPGain(...)
    elseif event == "PLAYER_TARGET_CHANGED" then self:RememberUnit("target")
    elseif event == "UPDATE_MOUSEOVER_UNIT" then self:RememberUnit("mouseover")
    elseif event == "CHAT_MSG_LOOT" then self:Loot(...)
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then local _, subevent; if CombatLogGetCurrentEventInfo then _, subevent = CombatLogGetCurrentEventInfo() else _, subevent = ... end; if subevent == "PARTY_KILL" then self:PartyKillFallback() end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then local unit = ...; if unit == "player" then self:Gather(spellName(...)) end
    elseif event == "PLAYER_LOGOUT" then self.db.session = self.session; self:SavePos() end
end)

FLT:RegisterEvent("ADDON_LOADED")
FLT:RegisterEvent("PLAYER_LOGIN")
FLT:RegisterEvent("PLAYER_XP_UPDATE")
FLT:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
FLT:RegisterEvent("PLAYER_TARGET_CHANGED")
FLT:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
FLT:RegisterEvent("CHAT_MSG_LOOT")
FLT:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
FLT:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
FLT:RegisterEvent("PLAYER_LOGOUT")
