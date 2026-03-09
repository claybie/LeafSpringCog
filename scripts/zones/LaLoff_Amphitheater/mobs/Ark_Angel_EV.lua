-----------------------------------
-- Area: LaLoff Amphitheater
--  Mob: Ark Angel EV
-- TODO: Shield Bash every 10 seconds
-----------------------------------
mixins = { require('scripts/mixins/job_special') }
-----------------------------------
---@type TMobEntity
local entity = {}

local function isDivineMight(mob)
    local bf = mob:getBattlefield()
    return bf and bf:getID() == xi.battlefield.id.DIVINE_MIGHT
end

local function dmLinkUnlocked(mob)
    local bf = mob:getBattlefield()
    if not (bf and bf:getID() == xi.battlefield.id.DIVINE_MIGHT) then
        return true
    end

    local now = GetSystemTime()
    local unlock = bf:getLocalVar('DM_LINK_UNLOCK_TIME')
    if unlock == 0 then
        bf:setLocalVar('DM_LINK_UNLOCK_TIME', now + 15)
        unlock = now + 15
    end

    return now >= unlock
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
    xi.mix.jobSpecial.config(mob, {
        specials =
        {
            { id = xi.jsa.BENEDICTION, hpp = math.random(20, 30) }, -- "Uses Benediction once."
            { id = xi.jsa.INVINCIBLE, hpp = math.random(90, 95), cooldown = 90 }, -- "Uses Invincible many times."
        },
    })
end

entity.onMobEngage = function(mob, target)
    local mobid = mob:getID()

    -- Divine Might: block the immediate pile-on for the first 15s of the fight
    if dmLinkUnlocked(mob) then
        for member = mobid-4, mobid + 3 do
            local m = GetMobByID(member)
            if m and m:getCurrentAction() == xi.action.category.ROAMING then
                m:updateEnmity(target)
            end
        end
    end

    mob:setLocalVar('shieldStrikeTime', GetSystemTime() + 17)
end

entity.onMobFight = function(mob, target)
    if xi.combat.behavior.isEntityBusy(mob) then
        return
    end

    local currentTime = GetSystemTime()
    if currentTime >= mob:getLocalVar('shieldStrikeTime') then
        mob:useMobAbility(xi.mobSkill.SHIELD_STRIKE)
        mob:setLocalVar('shieldStrikeTime', currentTime + 17)
    end
end

return entity