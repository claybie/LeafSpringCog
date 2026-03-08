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
    callPetJob = xi.job.DRG,
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

    local battlefieldId   = battlefield:getID()
    local battlefieldArea = battlefield:getArea()
    local content         = xi.battlefield.contents[battlefieldId]
    local petGroupIndex   = battlefieldId == xi.battlefield.id.DIVINE_MIGHT and 4 or 2
    local petId           = content.groups[petGroupIndex]['mobIds'][battlefieldArea][1]

    if xi.mob.callPets(mob, petId, callPetParams) then
        local pet = GetMobByID(petId)
        if pet then
            battlefield:insertEntity(pet:getTargID(), false, true)

            pet:addListener('DEATH', 'AAGK_PET_DEATH', function(petArg)
                local petBattlefield = petArg:getBattlefield()
                petBattlefield:setLocalVar('petRespawnGK', GetSystemTime() + 30)
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

    -- Divine Might 75-cap solo+trust tuning: reduce TP spam and sustain
    if isDivineMight(mob) then
        mob:addMod(xi.mod.REGAIN, -75) -- 90 -> 15
        mob:addMod(xi.mod.REGEN,  -10) -- 12 -> 2
    end
end

entity.onMobSpawn = function(mob)
    local dm = isDivineMight(mob)

    xi.mix.jobSpecial.config(mob,
    {
        specials =
        {
            -- "Meikyo Shisui is used very frequently."
            {
                id       = xi.jsa.MEIKYO_SHISUI,
                hpp      = dm and math.random(65, 75) or math.random(90, 95),
                cooldown = dm and 180 or 90,

                begCode  = function(mobArg)
                    mobArg:setLocalVar('order', 0)
                end,
            },
        },
    })
end

entity.onMobEngage = function(mob, target)
    -- Divine Might 75-cap solo+trust tuning: wyvern spawns once only
    if isDivineMight(mob) then
        if mob:getLocalVar('DM_WYVERN_SPAWNED') == 1 then
            return
        end
        mob:setLocalVar('DM_WYVERN_SPAWNED', 1)
    end

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

            -- Divine Might 75-cap solo+trust tuning: no wyvern respawns
            if isDivineMight(mob) then
                return
            end

            spawnArkAngelPet(mob)
        end
    end
end

return entity