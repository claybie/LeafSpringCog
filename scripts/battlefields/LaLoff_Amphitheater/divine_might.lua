-----------------------------------
-- Area: LaLoff Amphitheater
-- Name: Divine Might
--
-- One-at-a-time timer spawn using CANONICAL Divine Might mob IDs:
--  - Battlefield owns the correct Ark Angel mob IDs via the original DM mobIds list.
--  - At start we force ONLY TT to remain spawned; HM/GK/MR/EV are despawned.
--  - After TT first engages, HM/GK/MR/EV are spawned on timers.
--  - Anti-respawn: if a mob exists before its timer, despawn it; if it is dead, despawn if it reappears.
--  - Victory: only when all 5 have spawned at least once AND are dead.
--
-- Pet fix (NEW):
--  - Spawn GK/MR pets explicitly from the battlefield script when GK/MR spawn.
--  - Insert pet entities into the battlefield so they are valid targets.
--  - (We do NOT rely on Ark_Angel_GK.lua / Ark_Angel_MR.lua pet logic, which may be brittle in this variant.)
-----------------------------------
local laLoffID = zones[xi.zone.LALOFF_AMPHITHEATER]

print('[DM] Loaded scripts/battlefields/LaLoff_Amphitheater/divine_might.lua (v14 canonical-IDs despawn-gated + pet-spawn)')

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

local function dmDebug(battlefield, msg)
    print(string.format('[DM][area=%d] %s', battlefield:getArea(), msg))
end

-- Canonical DM mob IDs (copied from original Divine Might group list)
local dmIds =
{
    [1] =
    {
        HM = laLoffID.mob.ARK_ANGEL_HM + 24,
        MR = laLoffID.mob.ARK_ANGEL_MR + 22,
        EV = laLoffID.mob.ARK_ANGEL_EV + 16,
        TT = laLoffID.mob.ARK_ANGEL_TT + 14,
        GK = laLoffID.mob.ARK_ANGEL_GK + 12,

        -- Pets (from original DM pet groups)
        GK_PET    = laLoffID.mob.ARK_ANGEL_GK + 13,
        MR_TIGER  = laLoffID.mob.ARK_ANGEL_MR + 23,
        MR_MANDY  = laLoffID.mob.ARK_ANGEL_MR + 24,
    },
    [2] =
    {
        HM = laLoffID.mob.ARK_ANGEL_HM + 32,
        MR = laLoffID.mob.ARK_ANGEL_MR + 30,
        EV = laLoffID.mob.ARK_ANGEL_EV + 24,
        TT = laLoffID.mob.ARK_ANGEL_TT + 22,
        GK = laLoffID.mob.ARK_ANGEL_GK + 20,

        GK_PET    = laLoffID.mob.ARK_ANGEL_GK + 21,
        MR_TIGER  = laLoffID.mob.ARK_ANGEL_MR + 31,
        MR_MANDY  = laLoffID.mob.ARK_ANGEL_MR + 32,
    },
    [3] =
    {
        HM = laLoffID.mob.ARK_ANGEL_HM + 40,
        MR = laLoffID.mob.ARK_ANGEL_MR + 38,
        EV = laLoffID.mob.ARK_ANGEL_EV + 32,
        TT = laLoffID.mob.ARK_ANGEL_TT + 30,
        GK = laLoffID.mob.ARK_ANGEL_GK + 28,

        GK_PET    = laLoffID.mob.ARK_ANGEL_GK + 29,
        MR_TIGER  = laLoffID.mob.ARK_ANGEL_MR + 39,
        MR_MANDY  = laLoffID.mob.ARK_ANGEL_MR + 40,
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

local function despawnIfSpawned(id)
    local mob = GetMobByID(id)
    if mob and mob:isSpawned() then
        DespawnMob(id)
    end
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

    if isDead(battlefield, key) then
        DespawnMob(id)
        return
    end

    if battlefield:getLocalVar(gateVar) == 0 then
        DespawnMob(id)
        return
    end
end

-- -------------------------
-- Pet spawning (NEW)
-- -------------------------
local function spawnPetOnce(battlefield, who)
    if who == 'GK' then
        if battlefield:getLocalVar('DM_PET_GK_SPAWNED') == 1 then
            return
        end
        battlefield:setLocalVar('DM_PET_GK_SPAWNED', 1)

        local id = getId(battlefield, 'GK_PET')
        dmDebug(battlefield, string.format('Spawning GK pet id=%d', id))
        spawnIfNeeded(id)

        local pet = GetMobByID(id)
        if pet then
            battlefield:insertEntity(pet:getTargID(), false, true)
            enableAndEngage(battlefield, pet, 'GK_PET')
        end
        return
    end

    if who == 'MR' then
        if battlefield:getLocalVar('DM_PET_MR_SPAWNED') == 1 then
            return
        end
        battlefield:setLocalVar('DM_PET_MR_SPAWNED', 1)

        local tiger = getId(battlefield, 'MR_TIGER')
        local mandy = getId(battlefield, 'MR_MANDY')
        local id = (math.random(2) == 1) and tiger or mandy

        dmDebug(battlefield, string.format('Spawning MR pet id=%d', id))
        spawnIfNeeded(id)

        local pet = GetMobByID(id)
        if pet then
            battlefield:insertEntity(pet:getTargID(), false, true)
            enableAndEngage(battlefield, pet, 'MR_PET')
        end
    end
end

content.groups =
{
    -- Canonical DM mob list (battlefield owns correct IDs).
    -- We will despawn HM/GK/MR/EV immediately in tick until their timers.
    {
        mobIds =
        {
            {
                dmIds[1].HM,
                dmIds[1].MR,
                dmIds[1].EV,
                dmIds[1].TT,
                dmIds[1].GK,
            },
            {
                dmIds[2].HM,
                dmIds[2].MR,
                dmIds[2].EV,
                dmIds[2].TT,
                dmIds[2].GK,
            },
            {
                dmIds[3].HM,
                dmIds[3].MR,
                dmIds[3].EV,
                dmIds[3].TT,
                dmIds[3].GK,
            },
        },

        allDeath = function(battlefield, mob)
            -- Don't win here; we win via allDefeated() to support stagger spawns
        end,
    },
}

function content:onBattlefieldTick(battlefield, tick)
    Battlefield.onBattlefieldTick(self, battlefield, tick)

    if battlefield:getLocalVar('DM_LOGGED') == 0 then
        battlefield:setLocalVar('DM_LOGGED', 1)
        dmDebug(battlefield, string.format(
            'Canonical IDs TT=%d HM=%d GK=%d MR=%d EV=%d | pets GK=%d MRt=%d MRm=%d',
            getId(battlefield, 'TT'),
            getId(battlefield, 'HM'),
            getId(battlefield, 'GK'),
            getId(battlefield, 'MR'),
            getId(battlefield, 'EV'),
            getId(battlefield, 'GK_PET'),
            getId(battlefield, 'MR_TIGER'),
            getId(battlefield, 'MR_MANDY')
        ))
    end

    pollDeaths(battlefield)

    if allDefeated(battlefield) then
        battlefield:setStatus(xi.battlefield.status.WON)
        return
    end

    -- Ensure TT is considered "seen" once spawned
    if not hasSeen(battlefield, 'TT') then
        local tt = GetMobByID(getId(battlefield, 'TT'))
        if tt and tt:isSpawned() then
            setSeen(battlefield, 'TT')
            enableAndEngage(battlefield, tt, 'TT')
        end
    end

    -- Hard gate: keep later AAs despawned until their spawn var flips
    suppressBeforeAllowedOrAfterDeath(battlefield, 'HM', 'DM_SPAWN_HM')
    suppressBeforeAllowedOrAfterDeath(battlefield, 'GK', 'DM_SPAWN_GK')
    suppressBeforeAllowedOrAfterDeath(battlefield, 'MR', 'DM_SPAWN_MR')
    suppressBeforeAllowedOrAfterDeath(battlefield, 'EV', 'DM_SPAWN_EV')

    -- Also suppress pets until their owner is spawned (so pets won't show early)
    if battlefield:getLocalVar('DM_SPAWN_GK') == 0 then
        despawnIfSpawned(getId(battlefield, 'GK_PET'))
    end
    if battlefield:getLocalVar('DM_SPAWN_MR') == 0 then
        despawnIfSpawned(getId(battlefield, 'MR_TIGER'))
        despawnIfSpawned(getId(battlefield, 'MR_MANDY'))
    end

    -- Start timer when TT engages
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

    if elapsed >=  90 then
        spawnAAOnce(battlefield, 'HM', 'DM_SPAWN_HM')
    end

    if elapsed >= 180 then
        spawnAAOnce(battlefield, 'GK', 'DM_SPAWN_GK')
        spawnPetOnce(battlefield, 'GK')
    end

    if elapsed >= 270 then
        spawnAAOnce(battlefield, 'MR', 'DM_SPAWN_MR')
        spawnPetOnce(battlefield, 'MR')
    end

    if elapsed >= 360 then
        spawnAAOnce(battlefield, 'EV', 'DM_SPAWN_EV')
    end
end

return content:register()