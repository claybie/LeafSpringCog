-----------------------------------
-- Area: LaLoff Amphitheater
--  Mob: Ark Angel GK
-----------------------------------
mixins = { require('scripts/mixins/job_special') }
-----------------------------------
---@type TMobEntity
local entity = {}

local callPetParams =
{
    inactiveTime = 1000,
}

local function getGKPetIdForDivineMight(area, laLoffID)
    if area == 1 then
        return laLoffID.mob.ARK_ANGEL_GK + 13
    elseif area == 2 then
        return laLoffID.mob.ARK_ANGEL_GK + 21
    else
        return laLoffID.mob.ARK_ANGEL_GK + 29
    end
end

local function spawnArkAngelPet(mob)
    local battlefield = mob:getBattlefield()
    if not battlefield then
        return
    end

    local battlefieldId   = battlefield:getID()
    local battlefieldArea = battlefield:getArea()
    local petId           = nil

    -- Divine Might: compute pet IDs directly (do not rely on xi.battlefield.contents[].groups)
    if battlefieldId == xi.battlefield.id.DIVINE_MIGHT then
        local laLoff = zones[xi.zone.LALOFF_AMPHITHEATER]
        petId = getGKPetIdForDivineMight(battlefieldArea, laLoff)
    else
        -- Fallback to existing behavior for other battlefields (as before)
        local content = xi.battlefield.contents[battlefieldId]
        local petGroupIndex = 2
        if content and content.groups and content.groups[petGroupIndex] and content.groups[petGroupIndex].mobIds then
            petId = content.groups[petGroupIndex].mobIds[battlefieldArea][1]
        end
    end

    if not petId then
        return
    end

    if xi.mob.callPets(mob, petId, callPetParams) then
        local pet = GetMobByID(petId)
        if pet then
            battlefield:insertEntity(pet:getTargID(), false, true)

            pet:addListener('DEATH', 'AAGK_PET_DEATH', function(petArg)
                local petBattlefield = petArg:getBattlefield()
                if petBattlefield then
                    petBattlefield:setLocalVar('petRespawnGK', GetSystemTime() + 30)
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
    mob:setMobMod(xi.mobMod.SPECIAL_SKILL, 732)
    mob:setMobMod(xi.mobMod.SPECIAL_COOL, 60)
    mob:addMod(xi.mod.REGAIN, 90)
    mob:addMod(xi.mod.REGEN, 12)
end

entity.onMobSpawn = function(mob)
    xi.mix.jobSpecial.config(mob,
    {
        specials =
        {
            {
                id       = xi.jsa.MEIKYO_SHISUI,
                hpp      = math.random(90, 95),
                cooldown = 90,
                begCode  = function(mobArg)
                    mobArg:setLocalVar('order', 0)
                end,
            },
        },
    })
end

entity.onMobEngage = function(mob, target)
    spawnArkAngelPet(mob)
end

entity.onMobFight = function(mob, target)
    local order = mob:getLocalVar('order')
    if mob:hasStatusEffect(xi.effect.MEIKYO_SHISUI) then
        if order == 0 then
            mob:useMobAbility(xi.mobSkill.TACHI_YUKIKAZE)
            mob:setLocalVar('order', 1)
        elseif order == 1 then
            mob:useMobAbility(xi.mobSkill.TACHI_GEKKO)
            mob:setLocalVar('order', 2)
        elseif order == 2 then
            mob:useMobAbility(xi.mobSkill.TACHI_KASHA)
            mob:setLocalVar('order', 3)
        end
    end

    local battlefield = mob:getBattlefield()
    if battlefield then
        local respawnTime = battlefield:getLocalVar('petRespawnGK')
        if respawnTime ~= 0 and respawnTime <= GetSystemTime() then
            battlefield:setLocalVar('petRespawnGK', 0)
            spawnArkAngelPet(mob)
        end
    end
end

return entity