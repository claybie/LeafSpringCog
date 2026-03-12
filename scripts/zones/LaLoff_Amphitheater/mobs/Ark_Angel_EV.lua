-----------------------------------
-- Area: LaLoff Amphitheater
--  Mob: Ark Angel EV
-- TODO: Shield Bash every 10 seconds
-----------------------------------
mixins = { require('scripts/mixins/job_special') }
-----------------------------------
---@type TMobEntity
local entity = {}

entity.onMobInitialize = function(mob)
    mob:addImmunity(xi.immunity.DARK_SLEEP)
    mob:addImmunity(xi.immunity.LIGHT_SLEEP)
    mob:addImmunity(xi.immunity.PETRIFY)
    mob:addImmunity(xi.immunity.SILENCE)
    mob:addImmunity(xi.immunity.STUN)
    mob:addImmunity(xi.immunity.TERROR)
    mob:setMobMod(xi.mobMod.CAN_PARRY, 3)

    -- Solo fight (non-DM)
    mob:addMod(xi.mod.REGAIN, 90)
    mob:addMod(xi.mod.REGEN, 12)

    local battlefield = mob:getBattlefield()
    if battlefield and battlefield:getID() == xi.battlefield.id.DIVINE_MIGHT then
        -- Divine Might-only rebalance: lower sustain + TP pressure
        mob:delMod(xi.mod.REGAIN, 90)
        mob:delMod(xi.mod.REGEN, 12)
        mob:addMod(xi.mod.REGAIN, 30)
        mob:addMod(xi.mod.REGEN, 4)

        -- (TT already uses MAGIC_COOL in its script; EV doesn't, so set it here for DM only)
        mob:setMobMod(xi.mobMod.MAGIC_COOL, 35) -- higher = less frequent casting
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

    -- Divine Might-only: lower special pressure (Invincible cadence)
    local battlefield = mob:getBattlefield()
    if battlefield and battlefield:getID() == xi.battlefield.id.DIVINE_MIGHT then
        xi.mix.jobSpecial.config(mob, {
            specials =
            {
                { id = xi.jsa.BENEDICTION, hpp = math.random(20, 30) },
                { id = xi.jsa.INVINCIBLE, hpp = math.random(85, 90), cooldown = 180 }, -- was 90
            },
        })
    end
end

entity.onMobEngage = function(mob, target)
    local mobid = mob:getID()

    for member = mobid-4, mobid + 3 do
        local m = GetMobByID(member)
        if m and m:getCurrentAction() == xi.action.category.ROAMING then
            m:updateEnmity(target)
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
