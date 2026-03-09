-----------------------------------
-- Area: LaLoff Amphitheater
--  Mob: Ark Angel MR
-----------------------------------
mixins = { require('scripts/mixins/job_special') }
-----------------------------------
---@type TMobEntity
local entity = {}

local callPetParams =
{
    inactiveTime = 1000,
}

local function isDivineMight(mob)
    local bf = mob:getBattlefield()
    return bf and bf:getID() == xi.battlefield.id.DIVINE_MIGHT
end

local function spawnArkAngelPet(mob)
    local battlefield = mob:getBattlefield()
    if not battlefield then
        return
    end

    -- Divine Might: only one pet alive at a time
    if isDivineMight(mob) then
        local existingPetId = mob:getLocalVar('DM_MR_PET_ID')
        if existingPetId ~= 0 then
            local existingPet = GetMobByID(existingPetId)
            if existingPet and existingPet:isAlive() then
                return
            end
        end
    end

    local battlefieldId    = battlefield:getID()
    local battlefieldArea  = battlefield:getArea()
    local content          = xi.battlefield.contents[battlefieldId]
    local selectedPetGroup = math.random(2, 3) -- 2 = Tiger, 3 = Mandragora
    local petId            = content.groups[selectedPetGroup]['mobIds'][battlefieldArea][1]

    if xi.mob.callPets(mob, petId, callPetParams) then
        local pet = GetMobByID(petId)
        if pet then
            battlefield:insertEntity(pet:getTargID(), false, true)

            if isDivineMight(mob) then
                mob:setLocalVar('DM_MR_PET_ID', petId)
            end

            pet:addListener('DEATH', 'AAMR_PET_DEATH_' .. petId, function(petArg)
                local petBattlefield = petArg:getBattlefield()
                local respawnDelay   = 30

                -- Divine Might: slower respawn
                if petBattlefield and petBattlefield:getID() == xi.battlefield.id.DIVINE_MIGHT then
                    respawnDelay = 150
                end

                petBattlefield:setLocalVar('petRespawnMR', GetSystemTime() + respawnDelay)
            end)
        end
    end
end

entity.onMobInitialize = function(mob)
    mob:addImmunity(xi.immunity.DARK_SLEEP)
    mob:addImmunity(xi.immunity.LIGHT_SLEEP)
    mob:addImmunity(xi.immunity.PETRIFY)
    mob:addImmunity(xi.immunity.SILENCE)
    mob:addImmunity(xi.immunity.STUN)
    mob:addImmunity(xi.immunity.TERROR)
    mob:setMobMod(xi.mobMod.CAN_PARRY, 3)
    mob:addMod(xi.mod.REGAIN, 90)
    mob:addMod(xi.mod.REGEN, 12)

    -- Divine Might 75-cap solo+trust tuning: reduce TP spam and sustain
    if isDivineMight(mob) then
        mob:addMod(xi.mod.REGAIN, -75) -- 90 -> 15
        mob:addMod(xi.mod.REGEN,  -10) -- 12 -> 2
    end
end

entity.onMobSpawn = function(mob)
    xi.mix.jobSpecial.config(mob,
    {
        specials =
        {
            { id = xi.jsa.PERFECT_DODGE },
        },
    })
end

entity.onMobEngage = function(mob, target)
    -- Divine Might: delay initial pet spawn to avoid opening add pile-on
    if isDivineMight(mob) then
        mob:timer(10000, function(mobArg)
            if mobArg:isAlive() and mobArg:isEngaged() and mobArg:getHPP() < 90 then
                spawnArkAngelPet(mobArg)
            end
        end)
        return
    end

    spawnArkAngelPet(mob)
end

entity.onMobFight = function(mob, target)
    if mob:getLocalVar('Charm') == 0 and mob:getHPP() < 50 then
        mob:useMobAbility(xi.mobSkill.CHARM)
        mob:setLocalVar('Charm', 1)
    end

    local battlefield = mob:getBattlefield()
    if battlefield then
        local respawnTime = battlefield:getLocalVar('petRespawnMR')
        if respawnTime ~= 0 and respawnTime <= GetSystemTime() then
            -- Divine Might: pet respawns only in late phase
            if not isDivineMight(mob) or mob:getHPP() < 40 then
                battlefield:setLocalVar('petRespawnMR', 0)
                spawnArkAngelPet(mob)
            end
        end
    end
end

return entity