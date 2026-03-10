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

local function getMRPetIdsForDivineMight(area, laLoffID)
    if area == 1 then
        return laLoffID.mob.ARK_ANGEL_MR + 23, laLoffID.mob.ARK_ANGEL_MR + 24
    elseif area == 2 then
        return laLoffID.mob.ARK_ANGEL_MR + 31, laLoffID.mob.ARK_ANGEL_MR + 32
    else
        return laLoffID.mob.ARK_ANGEL_MR + 39, laLoffID.mob.ARK_ANGEL_MR + 40
    end
end

local function spawnArkAngelPet(mob)
    local battlefield = mob:getBattlefield()
    if not battlefield then
        return
    end

    local battlefieldId    = battlefield:getID()
    local battlefieldArea  = battlefield:getArea()
    local petId            = nil

    if battlefieldId == xi.battlefield.id.DIVINE_MIGHT then
        local laLoff = zones[xi.zone.LALOFF_AMPHITHEATER]
        local tigerId, mandyId = getMRPetIdsForDivineMight(battlefieldArea, laLoff)
        petId = (math.random(2) == 1) and tigerId or mandyId
    else
        -- Original behavior for other battlefields (guarded)
        local content = xi.battlefield.contents[battlefieldId]
        if content and content.groups and content.groups[2] and content.groups[3] then
            local selectedPetGroup = math.random(2, 3) -- 2 = Tiger, 3 = Mandragora
            local mobIds = content.groups[selectedPetGroup].mobIds
            if mobIds and mobIds[battlefieldArea] then
                petId = mobIds[battlefieldArea][1]
            end
        end
    end

    if not petId then
        return
    end

    if xi.mob.callPets(mob, petId, callPetParams) then
        local pet = GetMobByID(petId)
        if pet then
            battlefield:insertEntity(pet:getTargID(), false, true)

            pet:addListener('DEATH', 'AAMR_PET_DEATH_' .. petId, function(petArg)
                local petBattlefield = petArg:getBattlefield()
                if petBattlefield then
                    petBattlefield:setLocalVar('petRespawnMR', GetSystemTime() + 30)
                end
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
            battlefield:setLocalVar('petRespawnMR', 0)
            spawnArkAngelPet(mob)
        end
    end
end

return entity