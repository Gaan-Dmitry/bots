-- ============================================================================
-- PBot v6.5: ФИКС ЧЕРНОГО КВАДРАТА + ПРИОРИТЕТ СЕЙВА ТАНКА НАД АОЕ
-- ============================================================================

-- Если старый фрейм уже был создан (например, из WA), прячем его
if PatriarchSignalFrame then
    PatriarchSignalFrame:Hide()
end

local f = CreateFrame("Frame", "PatriarchSignalFrameV65", UIParent)
f:SetWidth(30)
f:SetHeight(30)
f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
f:SetFrameStrata("TOOLTIP")
f:SetFrameLevel(999)

local tex = f:CreateTexture(nil, "OVERLAY")
tex:SetAllPoints(f)
tex:SetTexture(0, 0, 0, 1)

local label = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
label:SetPoint("LEFT", f, "RIGHT", 6, 0)
label:SetText("PBot v6.5: Выдели танка и жми X")

-- Точные названия спеллов
local SP_REJUV     = GetSpellInfo(48441) or "Омоложение"
local SP_REGROWTH  = GetSpellInfo(48443) or "Восстановление"
local SP_SWIFTMEND = GetSpellInfo(18562) or "Быстрое восстановление"
local SP_WILDGROW  = GetSpellInfo(53251) or "Буйный рост"
local SP_INNERVATE = GetSpellInfo(29166) or "Озарение"
local SP_REBIRTH   = GetSpellInfo(48477) or "Возрождение"
local SP_REVIVE    = GetSpellInfo(50763) or "Оживление"

-- 1. ВНУТРЕННИЕ БЕЗОПАСНЫЕ МАКРО-КНОПКИ АДДОНА
local BotButtons = {
    -- Фокус + Следование (F5)
    { key = "F5",      macro = "/focus [help,nodead]\n/follow focus\n/cast !Древо Жизни" },

    -- Чистое Омоложение на 5 человек (F6..F10 -> G:40..120)
    { key = "F6",      macro = "/dismount\n/cast [target=player] " .. SP_REJUV },
    { key = "F7",      macro = "/dismount\n/cast [target=party1] " .. SP_REJUV },
    { key = "F8",      macro = "/dismount\n/cast [target=party2] " .. SP_REJUV },
    { key = "F9",      macro = "/dismount\n/cast [target=party3] " .. SP_REJUV },
    { key = "F10",     macro = "/dismount\n/cast [target=party4] " .. SP_REJUV },

    -- Прямой сейв: Быстрое восстановление + Восстановление (F11..Numpad3 -> G:140..220)
    { key = "F11",     macro = "/dismount\n/cast [target=player] Дубовая кожа\n/cast [target=player] " .. SP_SWIFTMEND .. "\n/cast [target=player] " .. SP_REGROWTH },
    { key = "F12",     macro = "/dismount\n/cast [target=party1] " .. SP_SWIFTMEND .. "\n/cast [target=party1] " .. SP_REGROWTH },
    { key = "NUMPAD1", macro = "/dismount\n/cast [target=party2] " .. SP_SWIFTMEND .. "\n/cast [target=party2] " .. SP_REGROWTH },
    { key = "NUMPAD2", macro = "/dismount\n/cast [target=party3] " .. SP_SWIFTMEND .. "\n/cast [target=party3] " .. SP_REGROWTH },
    { key = "NUMPAD3", macro = "/dismount\n/cast [target=party4] " .. SP_SWIFTMEND .. "\n/cast [target=party4] " .. SP_REGROWTH },

    -- АОЕ, Озарение, Фоллоу, Маунт, Стоп-каст (Numpad4..Numpad8 -> G:230..255)
    { key = "NUMPAD4", macro = "/dismount\n/cast [target=player] " .. SP_WILDGROW },
    { key = "NUMPAD5", macro = "/cast [target=player] " .. SP_INNERVATE .. "\n/cast [target=player] Дубовая кожа" },
    { key = "NUMPAD6", macro = "/follow focus\n/cast [nocombat] !Древо Жизни" },
    { key = "NUMPAD7", macro = "/cast [outdoors,nocombat] !Походный облик\n/follow focus" },
    { key = "NUMPAD8", macro = "/stopcasting\n/follow focus" },

    -- Диспел Ядов/Проклятий и Рес/БР (Канал B: Синий!)
    { key = "NUMPAD9", macro = "/castsequence [target=player] reset=3 Устранение яда, Снятие проклятия" },
    { key = "NUMPAD0", macro = "/cast [dead,combat,target=party1] " .. SP_REBIRTH .. "; [dead,nocombat,target=party1] " .. SP_REVIVE .. "\n/castsequence [nodead,target=party1] reset=3 Устранение яда, Снятие проклятия" },
    { key = "MINUS",   macro = "/cast [dead,combat,target=party2] " .. SP_REBIRTH .. "; [dead,nocombat,target=party2] " .. SP_REVIVE .. "\n/castsequence [nodead,target=party2] reset=3 Устранение яда, Снятие проклятия" },
    { key = "EQUALS",  macro = "/cast [dead,combat,target=party3] " .. SP_REBIRTH .. "; [dead,nocombat,target=party3] " .. SP_REVIVE .. "\n/castsequence [nodead,target=party3] reset=3 Устранение яда, Снятие проклятия" },
    { key = "BACKSPACE", macro = "/cast [dead,combat,target=party4] " .. SP_REBIRTH .. "; [dead,nocombat,target=party4] " .. SP_REVIVE .. "\n/castsequence [nodead,target=party4] reset=3 Устранение яда, Снятие проклятия" },
}

local function BindBotKeys()
    if InCombatLockdown() then return end
    ClearOverrideBindings(f)
    for i, b in ipairs(BotButtons) do
        local btnName = "PBotV65Btn" .. i
        local btn = _G[btnName] or CreateFrame("Button", btnName, UIParent, "SecureActionButtonTemplate")
        btn:SetAttribute("type", "macro")
        btn:SetAttribute("macrotext", b.macro)
        SetOverrideBindingClick(f, true, b.key, btnName)
    end
end

local setupFrame = CreateFrame("Frame")
setupFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
setupFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
setupFrame:SetScript("OnEvent", BindBotKeys)
BindBotKeys()

-- 2. БЫТОВЫЕ АВТО-ФУНКЦИИ
local ev = CreateFrame("Frame")
local events = {
    "PARTY_INVITE_REQUEST", "LFG_ROLE_CHECK_SHOW", "LFG_PROPOSAL_SHOW",
    "RESURRECT_REQUEST", "START_LOOT_ROLL", "CONFIRM_LOOT_ROLL",
    "CONFIRM_DISENCHANT_ROLL", "LOOT_BIND_CONFIRM", "MERCHANT_SHOW", "QUEST_DETAIL"
}
for _, e in ipairs(events) do ev:RegisterEvent(e) end

ev:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "PARTY_INVITE_REQUEST" then AcceptGroup(); StaticPopup_Hide("PARTY_INVITE")
    elseif event == "LFG_ROLE_CHECK_SHOW" then CompleteLFGRoleCheck(true)
    elseif event == "LFG_PROPOSAL_SHOW" then AcceptProposal()
    elseif event == "RESURRECT_REQUEST" then AcceptResurrect(); StaticPopup_Hide("RESURRECT_NO_TIMER")
    elseif event == "START_LOOT_ROLL" then RollOnLoot(arg1, 2)
    elseif event == "CONFIRM_LOOT_ROLL" or event == "CONFIRM_DISENCHANT_ROLL" then ConfirmLootRoll(arg1, arg2); StaticPopup_Hide("CONFIRM_LOOT_ROLL")
    elseif event == "LOOT_BIND_CONFIRM" then ConfirmLootSlot(arg1); StaticPopup_Hide("LOOT_BIND")
    elseif event == "QUEST_DETAIL" then AcceptQuest()
    elseif event == "MERCHANT_SHOW" then
        if CanMerchantRepair() then
            local cost = GetRepairAllCost()
            if cost > 0 and cost <= GetMoney() then RepairAllItems() end
        end
        for bag = 0, 4 do
            for slot = 1, GetContainerNumSlots(bag) do
                local link = GetContainerItemLink(bag, slot)
                if link then
                    local _, _, quality, _, _, _, _, _, _, _, vendorPrice = GetItemInfo(link)
                    if quality == 0 and vendorPrice and vendorPrice > 0 then
                        UseContainerItem(bag, slot)
                    end
                end
            end
        end
    end
end)

-- 3. СКАНЕР АУР
local function ScanUnitState(unit)
    local state = { rejuv = false, regrowth = false, innervate = false, dispel = false }
    for i = 1, 40 do
        local name, _, _, _, _, _, _, caster = UnitBuff(unit, i)
        if not name then break end
        if caster == "player" then
            if name == SP_REJUV or name == "Омоложение" then state.rejuv = true
            elseif name == SP_REGROWTH or name == "Восстановление" then state.regrowth = true end
        end
        if name == SP_INNERVATE or name == "Озарение" then state.innervate = true end
    end
    for i = 1, 40 do
        local name, _, _, _, debuffType = UnitDebuff(unit, i)
        if not name then break end
        if debuffType == "Curse" or debuffType == "Poison" then
            state.dispel = true
            break
        end
    end
    return state
end

local function IsValidUnit(unit)
    if not UnitExists(unit) or not UnitIsConnected(unit) or not UnitIsVisible(unit) then return false end
    if unit == "player" then return true end
    local r = IsSpellInRange(SP_REJUV, unit)
    if r ~= nil then return (r == 1) end
    return (UnitInRange(unit) == 1)
end

local function IsTankMounted()
    if not UnitExists("focus") then return false end
    for i = 1, 40 do
        local name = UnitBuff("focus", i)
        if not name then break end
        if string.find(name, "Походный") or string.find(name, "скакун") or string.find(name, "конь") or string.find(name, "медведь") or string.find(name, "дракон") or string.find(name, "тигр") or string.find(name, "волк") or string.find(name, "раптор") or string.find(name, "баран") or string.find(name, "механодолгоног") or string.find(name, "крылобег") or string.find(name, "кодо") or string.find(name, "мамонт") then
            return true
        end
    end
    return false
end

local function IsSpellReady(spellName)
    local usable, nomana = IsUsableSpell(spellName)
    if not usable or nomana then return false end
    local start, duration = GetSpellCooldown(spellName)
    if not start then return false end
    return (start == 0 or duration <= 1.5)
end

-- ГАРАНТИРОВАННАЯ ОТРИСОВКА ЦВЕТА ЧЕРЕЗ SetTexture + SetVertexColor
local function SendSignal(gCode, bCode, text)
    local g = gCode / 255
    local b = bCode / 255
    tex:SetTexture(0, g, b, 1)
    tex:SetVertexColor(0, g, b, 1)
    label:SetText(text)
end

local allUnits = {
    { unit = "player", rejuvG = 40,  directG = 140, utilB = 60  },
    { unit = "party1", rejuvG = 60,  directG = 160, utilB = 100 },
    { unit = "party2", rejuvG = 80,  directG = 180, utilB = 140 },
    { unit = "party3", rejuvG = 100, directG = 200, utilB = 180 },
    { unit = "party4", rejuvG = 120, directG = 220, utilB = 220 },
}

local currentCastUnit = nil
local lastFollowTime = 0
local needReFollow = false
local wasFeared = false
local elapsedTotal = 0

f:SetScript("OnUpdate", function(self, elapsed)
    elapsedTotal = elapsedTotal + elapsed
    if elapsedTotal < 0.12 then return end
    elapsedTotal = 0

    if UnitIsDeadOrGhost("player") then
        SendSignal(0, 0, "PBot: Мертв")
        return
    end

    if not HasFullControl() then
        wasFeared = true; needReFollow = true
        SendSignal(0, 0, "PBot: В Фире / Контроле!")
        return
    elseif wasFeared then
        wasFeared = false
        SendSignal(250, 0, "Вышел из Фира -> /follow")
        return
    end

    -- Стоп-каст на оверхиле (>93% ХП -> G: 245)
    local castingSpell = UnitCastingInfo("player")
    if castingSpell then
        needReFollow = true
        if castingSpell ~= SP_REVIVE and currentCastUnit and UnitExists(currentCastUnit) then
            local hp = (UnitHealth(currentCastUnit) / UnitHealthMax(currentCastUnit)) * 100
            if hp >= 93 then
                SendSignal(245, 0, "СТОП-КАСТ (Оверхил >93%)")
                return
            end
        end
        SendSignal(0, 0, "Кастую: " .. castingSpell)
        return
    end

    local inCombat = UnitAffectingCombat("player") or (UnitExists("focus") and UnitAffectingCombat("focus"))

    -- Маунт-режим за танком
    if not inCombat and (IsMounted() or IsTankMounted()) then
        local now = GetTime()
        if now - lastFollowTime > 3 then
            lastFollowTime = now
            SendSignal(255, 0, "Маунт: Бегу за танком!")
            return
        end
        SendSignal(0, 0, "Маунт: Следую за танком")
        return
    end

    if inCombat and IsMounted() then
        Dismount()
        SendSignal(250, 0, "Бой! Снимаю маунта")
        return
    end

    -- Воскрешение мертвых тиммейтов
    for _, u in ipairs(allUnits) do
        if u.unit ~= "player" and IsValidUnit(u.unit) and UnitIsDeadOrGhost(u.unit) and not UnitIsGhost(u.unit) then
            if (inCombat and IsSpellReady(SP_REBIRTH)) or not inCombat then
                needReFollow = true
                SendSignal(0, u.utilB, "Воскрешение -> " .. (UnitName(u.unit) or u.unit))
                return
            end
        end
    end

    -- Сканируем ХП и ауры группы
    local myMana = (UnitMana("player") / UnitManaMax("player")) * 100
    local lowestUnit = nil
    local lowestHP = 100
    local lowestAuras = nil
    local damagedCount = 0
    local unitStates = {}

    for _, u in ipairs(allUnits) do
        if IsValidUnit(u.unit) and not UnitIsDeadOrGhost(u.unit) then
            local maxHP = UnitHealthMax(u.unit)
            local hp = (maxHP > 0) and ((UnitHealth(u.unit) / maxHP) * 100) or 100
            local auras = ScanUnitState(u.unit)
            unitStates[u.unit] = { hp = hp, auras = auras, info = u }
            if hp < 88 then damagedCount = damagedCount + 1 end
            if hp < lowestHP then
                lowestHP = hp
                lowestUnit = u
                lowestAuras = auras
            end
        end
    end

    -- 1. Озарение по мане (< 35% -> G: 240)
    if myMana < 35 and IsSpellReady(SP_INNERVATE) and unitStates["player"] and not unitStates["player"].auras.innervate then
        SendSignal(240, 0, "Озарение по мане!")
        return
    end

    -- 2. ЭКСТРЕННЫЙ СЕЙВ: если кто-то просел ниже 65% ХП (как Кент на скрине) -> сначала хот и прямой сейв!
    if lowestUnit and lowestHP < 65 then
        if not lowestAuras.rejuv then
            SendSignal(lowestUnit.rejuvG, 0, "Срочно Омоложение -> " .. (UnitName(lowestUnit.unit) or lowestUnit.unit))
            return
        end
        if IsSpellReady(SP_SWIFTMEND) or not lowestAuras.regrowth then
            currentCastUnit = lowestUnit.unit
            needReFollow = true
            SendSignal(lowestUnit.directG, 0, "Сейв/Восст -> " .. (UnitName(lowestUnit.unit) or lowestUnit.unit) .. " (" .. math.floor(lowestHP) .. "%)")
            return
        end
    end

    -- 3. Буйный рост (G: 230) — только если спелл реально изучен и доступен!
    if (damagedCount >= 2 or lowestHP < 78) and IsSpellReady(SP_WILDGROW) then
        SendSignal(230, 0, "Буйный рост (АОЕ)!")
        return
    end

    -- 4. Раздача Омоложения (< 90% ХП)
    for _, u in ipairs(allUnits) do
        local st = unitStates[u.unit]
        if st and st.hp < 90 and not st.auras.rejuv then
            SendSignal(u.rejuvG, 0, "Омоложение -> " .. (UnitName(u.unit) or u.unit) .. " (" .. math.floor(st.hp) .. "%)")
            return
        end
    end

    -- 5. Обычный прямой хил при < 74% ХП
    if lowestUnit and lowestHP < 74 and (IsSpellReady(SP_SWIFTMEND) or not lowestAuras.regrowth) then
        currentCastUnit = lowestUnit.unit
        needReFollow = true
        SendSignal(lowestUnit.directG, 0, "Сейв/Восст -> " .. (UnitName(lowestUnit.unit) or lowestUnit.unit) .. " (" .. math.floor(lowestHP) .. "%)")
        return
    end

    -- 6. Диспел Ядов и Проклятий (Канал B)
    for _, u in ipairs(allUnits) do
        local st = unitStates[u.unit]
        if st and st.auras.dispel then
            SendSignal(0, u.utilB, "Диспел -> " .. (UnitName(u.unit) or u.unit))
            return
        end
    end

    -- 7. Авто-возврат на /follow focus
    local now = GetTime()
    if UnitExists("focus") and not UnitIsDeadOrGhost("focus") and (needReFollow or (now - lastFollowTime > 3.8)) then
        needReFollow = false
        lastFollowTime = now
        SendSignal(250, 0, "Обновляю /follow focus")
        return
    end

    SendSignal(0, 0, "Танк: " .. (UnitName("focus") or "Жми X!") .. " [ОК]")
end)