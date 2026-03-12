-----------------------------------
-- Area: LaLoff Amphitheater
-- Name: Divine Might
--
-- Staggered Ark Angels, 180s cadence:
-- Start: only TT remains spawned; HM/GK/MR/EV are despawned.
-- After TT first engages: HM @180, GK @360, MR @540, EV @720.
-- Anti-respawn: if a mob exists before its timer, despawn it; if dead, despawn if it reappears.
--
-- Pets:
-- NOT spawned here.
-- Pets are handled in Ark_Angel_GK.lua / Ark_Angel_MR.lua (which will also insertEntity).
-----------------------------------
local laLoffID = zones[xi.zone.LALOFF_AMPHITHEATER]

local content = Battlefield:new({
    zoneId        = xi.zone.LALOFF_AMPHITHEATER,
    battlefieldId = xi.battlefield.id.DIVINE_MIGHT,
    canLoseExp    = false,
    allowTrusts   = true,
    maxPlayers    = 6,
    levelCap      = 75,
    timeLimit     = utils.minutes(30),
    index         = 5,
    entryNpcs     = { 'qm1_1', 'qm1_2', 'qm1_3', 'qm1_4', 'qm1_5' },

    requiredItems = { xi.item.ARK_PENTASPHERE, wearMessage = laLoffID.text.THE_SEAL_FADES, wornMessage = { laLoffID.text.INK_HAS_FADED, xi.item.ARK_PENTASPHERE } },
})

function content:entryRequirement(player, npc, isRegistrant, trade)
    return player:getQuestStatus(xi.questLog.OUTLANDS, xi.quest.id.outlands.DIVINE_MIGHT) == xi.questStatus.QUEST_ACCEPTED or
        player:getQuestStatus(xi.questLog.OUTLANDS, xi.quest.id.outlands.DIVINE_MIGHT_REPEAT) == xi.questStatus.QUEST_ACCEPTED
end

local dmIds =
{
    [1] =
    {
        HM = laLoffID.mob.ARK_ANGEL_HM + 24,
        MR = laLoffID.mob.ARK_ANGEL_MR + 22,
        EV = laLoffID.mob.ARK_ANGEL_EV + 16,
        TT = laLoffID.mob.ARK_ANGEL_TT + 14,
        GK = laLoffID.mob.ARK_ANGEL_GK + 12,
    },
    [2] =
    {
        HM = laLoffID.mob.ARK_ANGEL_HM + 32,
        MR = laLoffID.mob.ARK_ANGEL_MR + 30,
        EV = laLoffID.mob.ARK_ANGEL_EV + 24,
        TT = laLoffID.mob.ARK_ANGEL_TT + 22,
        GK = laLoffID.mob.ARK_ANGEL_GK + 20,
    },
    [3] =
    {
        HM = laLoffID.mob.ARK_ANGEL_HM + 40,
        MR = laLoffID.mob.ARK_ANGEL_MR + 38,
        EV = laLoffID.mob.ARK_ANGEL_EV + 32,
        TT = laLoffID.mob.ARK_ANGEL_TT + 30,
        GK = laLoffID.mob.ARK_ANGEL_GK + 28,
    },
}

local function getId(battlefield, key)
    local t = dmIds[battlefield:getArea()]
    return t and t[key] or 0
end

local function setSeen(battlefield, key) battlefield:setLocalVar('DM_SEEN_' .. key, 1) end
local function hasSeen(battlefield, key) return battlefield:getLocalVar('DM_SEEN_' .. key) == 1 end
local function setDead(battlefield, key) battlefield:setLocalVar('DM_DEAD_' .. key, 1) end
local function isDead(battlefield, key) return battlefield:getLocalVar('DM_DEAD_' .. key) == 1 end

local function ttTarget(battlefield)
    local tt = GetMobByID(getId(battlefield, 'TT'))
    if tt and tt:isEngaged() then
        return tt:getTarget()
    end
    return nil
end

local function enableAndEngage(battlefield, mob, label)
    if not mob then
        return
    end

    mob:timer(500, function(m)
        m:setUntargetable(false)
        m:setMobMod(xi.mobMod.NO_AGGRO, 0)
        m:setMobMod(xi.mobMod.NO_LINK, 0)
        m:setMobMod(xi.mobMod.NO_MOVE, 0)

        local t = ttTarget(battlefield)
        if t then
            m:updateEnmity(t)
        end

        if label then
            dmDebug(battlefield, string.format('%s enabled id=%d targid=%d', label, m:getID(), m:getTargID()))
        end
    end)
end

local function spawnIfNeeded(id)
    local mob = GetMobByID(id)
    if mob and not mob:isSpawned() then
        SpawnMob(id)
    end
end

local function spawnAAOnce(battlefield, key, gateVar)
    if battlefield:getLocalVar(gateVar) == 1 or isDead(battlefield, key) then
        return
    end

    battlefield:setLocalVar(gateVar, 1)
    setSeen(battlefield, key)

    local id = getId(battlefield, key)
    dmDebug(battlefield, string.format('Spawning %s id=%d', key, id))

    spawnIfNeeded(id)
    enableAndEngage(battlefield, GetMobByID(id), key)
end

local function pollDeaths(battlefield)
    for _, key in ipairs({ 'TT', 'HM', 'GK', 'MR', 'EV' }) do
        if hasSeen(battlefield, key) and not isDead(battlefield, key) then
            local id = getId(battlefield, key)
            local mob = GetMobByID(id)
            if mob and mob:isSpawned() and not mob:isAlive() then
                setDead(battlefield, key)
                DespawnMob(id)
                dmDebug(battlefield, string.format('%s died id=%d marked dead', key, id))
            end
        end
    end
end

local function allDefeated(battlefield)
    for _, key in ipairs({ 'TT', 'HM', 'GK', 'MR', 'EV' }) do
        if not hasSeen(battlefield, key) or not isDead(battlefield, key) then
            return false
        end
    end
    return true
end

local function suppressBeforeAllowedOrAfterDeath(battlefield, key, gateVar)
    local id = getId(battlefield, key)
    local mob = GetMobByID(id)
    if not mob or not mob:isSpawned() then
        return
    end

    if isDead(battlefield, key) or battlefield:getLocalVar(gateVar) == 0 then
        DespawnMob(id)
    end
end

content.groups =
{
    {
        mobIds =
        {
            { dmIds[1].HM, dmIds[1].MR, dmIds[1].EV, dmIds[1].TT, dmIds[1].GK },
            { dmIds[2].HM, dmIds[2].MR, dmIds[2].EV, dmIds[2].TT, dmIds[2].GK },
            { dmIds[3].HM, dmIds[3].MR, dmIds[3].EV, dmIds[3].TT, dmIds[3].GK },
        },
        allDeath = function(battlefield, mob)
            -- Win via allDefeated()
        end,
    },
}

function content:onBattlefieldTick(battlefield, tick)
    Battlefield.onBattlefieldTick(self, battlefield, tick)

    if battlefield:getLocalVar('DM_LOGGED') == 0 then
        battlefield:setLocalVar('DM_LOGGED', 1)
        dmDebug(battlefield, string.format(
            'IDs TT=%d HM=%d GK=%d MR=%d EV=%d',
            getId(battlefield, 'TT'),
            getId(battlefield, 'HM'),
            getId(battlefield, 'GK'),
            getId(battlefield, 'MR'),
            getId(battlefield, 'EV')
        ))
    end

    pollDeaths(battlefield)

    if allDefeated(battlefield) then
        battlefield:setStatus(xi.battlefield.status.WON)
        return
    end

    if not hasSeen(battlefield, 'TT') then
        local tt = GetMobByID(getId(battlefield, 'TT'))
        if tt and tt:isSpawned() then
            setSeen(battlefield, 'TT')
            enableAndEngage(battlefield, tt, 'TT')
        end
    end

    suppressBeforeAllowedOrAfterDeath(battlefield, 'HM', 'DM_SPAWN_HM')
    suppressBeforeAllowedOrAfterDeath(battlefield, 'GK', 'DM_SPAWN_GK')
    suppressBeforeAllowedOrAfterDeath(battlefield, 'MR', 'DM_SPAWN_MR')
    suppressBeforeAllowedOrAfterDeath(battlefield, 'EV', 'DM_SPAWN_EV')

    if battlefield:getLocalVar('DM_START') == 0 then
        local tt = GetMobByID(getId(battlefield, 'TT'))
        if tt and tt:isEngaged() then
            battlefield:setLocalVar('DM_START', GetSystemTime())
            dmDebug(battlefield, 'Stagger timer started')
        else
            return
        end
    end

    local elapsed = GetSystemTime() - battlefield:getLocalVar('DM_START')

    if elapsed >= 180 then spawnAAOnce(battlefield, 'HM', 'DM_SPAWN_HM') end
    if elapsed >= 360 then spawnAAOnce(battlefield, 'GK', 'DM_SPAWN_GK') end
    if elapsed >= 540 then spawnAAOnce(battlefield, 'MR', 'DM_SPAWN_MR') end
    if elapsed >= 720 then spawnAAOnce(battlefield, 'EV', 'DM_SPAWN_EV') end
end

return content:register()
