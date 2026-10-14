-- ============================================================================
-- LuraBot v2.0: УМНЫЙ РЕНДЖ + АВТО-РАЗВОРОТ К МОБАМ + ОБХОД СТЕН (LoS)
-- ============================================================================

local f = CreateFrame("Frame", "LuraSignalFrame", UIParent)
f:SetWidth(28)
f:SetHeight(28)
f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
f:SetFrameStrata("TOOLTIP")

local tex = f:CreateTexture(nil, "OVERLAY")
tex:SetAllPoints(f)
tex:SetTexture(1, 1, 1, 1)

local label = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
label:SetPoint("LEFT", f, "RIGHT", 6, 0)
label:SetText("LuraBot v2: Выдели танка и жми X")

-- 1. ВНУТРЕННИЕ БЕЗОПАСНЫЕ МАКРО-КНОПКИ АДДОНА
local BotButtons = {
    -- Фокус танка + Следование + Бафф Доспеха Скверны (F5 -> по кнопке X)
    { key = "F5",      macro = "/focus [help,nodead]\n/follow focus\n/petfollow\n/cast !Доспех Скверны" },

    -- R:20 -> Экстренный стоп-каст + Лик смерти при ХП <= 5%
    { key = "F6",      macro = "/stopcasting\n/cast [target=focustarget,harm,nodead][harm,nodead] Лик смерти" },

    -- R:40 -> Жизнеотвод (Мана-менеджмент)
    { key = "F7",      macro = "/dismount\n/cast Жизнеотвод" },

    -- R:60 -> Ожог души (Нон-стоп под проком Истребления)
    { key = "F8",      macro = "/dismount\n/target [target=focustarget,harm,nodead]\n/petattack\n/cast Демоническое могущество\n/cast [target=focustarget,harm,nodead] Ожог души" },

    -- R:80 -> Метаморфоза + тринкеты + бурст пета
    { key = "F9",      macro = "/dismount\n/cast Метаморфоза\n/cast Демоническое могущество\n/use 13\n/use 14" },

    -- R:100 -> Проклятие стихий (Мгновенный старт боя + выбор цели)
    { key = "F10",     macro = "/dismount\n/target [target=focustarget,harm,nodead]\n/petattack\n/cast [target=focustarget,harm,nodead] Проклятие стихий" },

    -- R:120 -> Жертвенный огонь
    { key = "F11",     macro = "/dismount\n/target [target=focustarget,harm,nodead]\n/cast [target=focustarget,harm,nodead] Жертвенный огонь" },

    -- R:140 -> Порча (Мгновенный дот)
    { key = "F12",     macro = "/dismount\n/target [target=focustarget,harm,nodead]\n/petattack\n/cast [target=focustarget,harm,nodead] Порча" },

    -- R:180 (АОЕ) -> Семя порчи
    { key = "NUMPAD1", macro = "/dismount\n/target [target=focustarget,harm,nodead]\n/petattack\n/cast [target=focustarget,harm,nodead] Семя порчи" },

    -- R:160 -> Стрела Тьмы (Основной филлер)
    { key = "NUMPAD2", macro = "/dismount\n/target [target=focustarget,harm,nodead]\n/petattack\n/cast Демоническое могущество\n/cast [target=focustarget,harm,nodead] Стрела Тьмы" },

    -- R:220 -> Взять цель танка в таргет для авто-разворота через Interact (Numpad5)
    { key = "NUMPAD3", macro = "/target [target=focustarget,harm,nodead]" },

    -- R:250 -> Возврат на /follow focus + отзыв пета
    { key = "NUMPAD6", macro = "/petfollow\n/follow focus" },
}

local setupFrame = CreateFrame("Frame")
setupFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
setupFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
setupFrame:SetScript("OnEvent", function()
    if InCombatLockdown() then return end
    for i, b in ipairs(BotButtons) do
        local btnName = "LuraBotV2Btn" .. i
        local btn = _G[btnName] or CreateFrame("Button", btnName, UIParent, "SecureActionButtonTemplate")
        btn:SetAttribute("type", "macro")
        btn:SetAttribute("macrotext", b.macro)
        SetOverrideBindingClick(f, true, b.key, btnName)
    end
end)

-- 2. ОТСЛЕЖИВАНИЕ ОШИБОК КАСТА (Стена / Спиной к мобу / Движение)
local needFaceTarget = false
local losMoveUntil = 0
local isFollowing = true

local errFrame = CreateFrame("Frame")
errFrame:RegisterEvent("UI_ERROR_MESSAGE")
errFrame:SetScript("OnEvent", function(self, event, msg)
    if not msg then return end
    -- Если моб за спиной / сбоку
    if string.find(msg, "перед вами") or string.find(msg, "front of you") then
        needFaceTarget = true
    -- Если моб за углом стены или колонной (Line of Sight)
    elseif string.find(msg, "поля зрения") or string.find(msg, "line of sight") or string.find(msg, "слишком далеко") then
        losMoveUntil = GetTime() + 1.6
    -- Если каст сорвался из-за того, что /follow еще не остановился
    elseif string.find(msg, "на ходу") or string.find(msg, "while moving") then
        isFollowing = true
    end
end)

-- 3. БЫТОВЫЕ АВТО-ФУНКЦИИ
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
            if cost > 0 and cost <= GetMoney() then
                RepairAllItems()
            end
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

-- 4. СКАНЕРЫ БАФФОВ И ДЕБАФФОВ
local function HasDecimation()
    for i = 1, 40 do
        local name = UnitBuff("player", i)
        if not name then break end
        if name == "Истребление" then return true end
    end
    return false
end

local function ScanTargetDebuffs(unit)
    local debuffs = { coe = false, immolate = false, corruption = false }
    for i = 1, 40 do
        local name, _, _, _, _, _, expirationTime, caster = UnitDebuff(unit, i)
        if not name then break end
        local remain = expirationTime and (expirationTime - GetTime()) or 0
        if (name == "Проклятие стихий" or name == "Земля и Луна" or name == "Черная чума") and remain > 1.5 then
            debuffs.coe = true
        end
        if caster == "player" then
            if name == "Жертвенный огонь" and remain > 1.5 then
                debuffs.immolate = true
            elseif name == "Порча" and remain > 1.0 then
                debuffs.corruption = true
            end
        end
    end
    return debuffs
end

local function IsSpellReady(spellName)
    local start, duration = GetSpellCooldown(spellName)
    if not start then return false end
    return (start == 0 or duration <= 1.5)
end

local function IsValidEnemy(unit)
    if not UnitExists(unit) or UnitIsDeadOrGhost(unit) or not UnitCanAttack("player", unit) then
        return false
    end
    return (IsSpellInRange("Стрела Тьмы", unit) == 1)
end

local function SendSignal(rCode, text)
    tex:SetVertexColor(rCode / 255, 0, 0)
    label:SetText(text)
end

local lastFollowTime = 0
local needReFollow = false
local wasFeared = false
local lifeTapActive = false
local lifeTapTargetMana = 55
local lastImmolateCast = 0
local elapsedTotal = 0

f:SetScript("OnUpdate", function(self, elapsed)
    elapsedTotal = elapsedTotal + elapsed
    if elapsedTotal < 0.12 then return end
    elapsedTotal = 0

    if UnitIsDeadOrGhost("player") then
        lifeTapActive = false
        SendSignal(0, "LuraBot: Мертв")
        return
    end

    if not HasFullControl() then
        wasFeared = true; needReFollow = true; isFollowing = true
        SendSignal(0, "LuraBot: В контроле!")
        return
    elseif wasFeared then
        wasFeared = false
        SendSignal(250, "Вышел из контроля -> /follow")
        return
    end

    local now = GetTime()
    local myHP = (UnitHealth("player") / UnitHealthMax("player")) * 100
    local myMana = (UnitMana("player") / UnitManaMax("player")) * 100
    local hasTarget = IsValidEnemy("focustarget")
    local isMoving = (GetUnitSpeed("player") > 0)

    -- 1. Экстренный Лик Смерти при ХП <= 5%
    if myHP <= 5 and hasTarget and IsSpellReady("Лик смерти") then
        lifeTapActive = false
        SendSignal(20, "ХП <= 5%! ЛИК СМЕРТИ!")
        return
    end

    -- 2. Если уже кастуем спелл — сбрасываем флаги ошибок и не мешаем
    local castingSpell = UnitCastingInfo("player") or UnitChannelInfo("player")
    if castingSpell then
        isFollowing = false
        needFaceTarget = false
        if castingSpell == "Жертвенный огонь" then
            lastImmolateCast = now
        end
        SendSignal(0, "Кастую: " .. castingSpell)
        return
    end

    -- 3. ОБХОД СТЕНЫ (Line of Sight): если моб за стеной, бежим к танку 1.6 сек!
    if now < losMoveUntil and UnitExists("focus") then
        isFollowing = true
        needReFollow = true
        SendSignal(230, "Стена (LoS)! Подбегаю к танку...")
        return
    end

    -- 4. Мана-менеджмент (Жизнеотвод)
    if myMana <= 5 and myHP > 25 then
        if not lifeTapActive then
            lifeTapActive = true
            lifeTapTargetMana = math.random(38, 60)
        end
    end
    if lifeTapActive then
        if myMana >= lifeTapTargetMana or myMana >= 60 or myHP <= 25 then
            lifeTapActive = false
        else
            SendSignal(40, "Жизнеотвод -> до " .. lifeTapTargetMana .. "%")
            return
        end
    end

    -- 5. БОЕВАЯ ЛОГИКА + ДЕРЖАТЬ ДИСТАНЦИЮ + ПОВОРОТ К МОБУ
    local tankInCombat = UnitExists("focus") and UnitAffectingCombat("focus")
    local tankCloseEnough = UnitExists("focus") and (CheckInteractDistance("focus", 4) == 1) -- ~28 ярдов до танка

    if (UnitAffectingCombat("player") or tankInCombat) and hasTarget then
        needReFollow = true
        local debuffs = ScanTargetDebuffs("focustarget")

        -- СТАРТ БОЯ: сначала вешаем МГНОВЕННЫЕ доты (работают даже на бегу и спиной!)
        if not debuffs.coe then
            SendSignal(100, "Пул: Проклятие стихий")
            return
        end
        if not debuffs.corruption then
            SendSignal(140, "Пул: Порча")
            return
        end

        -- ТОРМОЖЕНИЕ НА ДИСТАНЦИИ: если мы всё ещё бежим на /follow и до танка < 28 ярдов — СТОП!
        if (isMoving or isFollowing) and tankCloseEnough then
            isFollowing = false
            SendSignal(210, "Держу рендж! Стоп /follow")
            return
        end

        -- РАЗВОРОТ К МОБУ: если сработала ошибка "Цель должна быть перед вами"
        if needFaceTarget then
            needFaceTarget = false
            SendSignal(220, "Поворот лицом к мобу!")
            return
        end

        -- Бурст по КД
        if IsSpellReady("Метаморфоза") then
            SendSignal(80, "МЕТАМОРФОЗА (Бурст!)")
            return
        end

        -- Кастуемые спеллы (Жертвенный огонь -> Ожог души -> Стрела Тьмы)
        if not debuffs.immolate and (now - lastImmolateCast > 1.8) then
            SendSignal(120, "Жертвенный огонь")
            return
        end

        if HasDecimation() then
            SendSignal(60, "ИСТРЕБЛЕНИЕ -> Ожог души!")
            return
        end

        SendSignal(160, "Стрела Тьмы")
        return
    end

    -- 6. ВНЕ БОЯ ИЛИ ДАЛЕКО ОТ ТАНКА -> СЛЕДУЕМ ЗА ФОКУСОМ
    if UnitExists("focus") and not UnitIsDeadOrGhost("focus") then
        -- Если в бою танк убежал дальше 28 ярдов — догоняем его
        if (tankInCombat and not tankCloseEnough) or (not tankInCombat and (needReFollow or (now - lastFollowTime > 3.2))) then
            needReFollow = false
            isFollowing = true
            lastFollowTime = now
            SendSignal(250, "Догоняю танка (/follow)")
            return
        end
    end

    SendSignal(0, "Танк: " .. (UnitName("focus") or "Жми X!") .. " [ОК]")
end)