-----------------------------------
-- Area: LaLoff Amphitheater
--  Mob: Ark Angel HM
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
    mob:setMobMod(xi.mobMod.DUAL_WIELD, 1)

    -- Default (non-DM)
    mob:addMod(xi.mod.REGAIN, 90)
    mob:addMod(xi.mod.REGEN, 12)

    local battlefield = mob:getBattlefield()
    if battlefield and battlefield:getID() == xi.battlefield.id.DIVINE_MIGHT then
        -- Divine Might-only rebalance: lower sustain + TP pressure
        mob:delMod(xi.mod.REGAIN, 90)
        mob:delMod(xi.mod.REGEN, 12)
        mob:addMod(xi.mod.REGAIN, 30)
        mob:addMod(xi.mod.REGEN, 4)
    end
end

entity.onMobSpawn = function(mob)
    xi.mix.jobSpecial.config(mob, {
        between = 30,
        specials =
        {
            { id = xi.jsa.MIGHTY_STRIKES },
            { id = xi.jsa.MIJIN_GAKURE },
        },
    })

    -- Divine Might-only: lower special pressure by increasing the "between" window.
    local battlefield = mob:getBattlefield()
    if battlefield and battlefield:getID() == xi.battlefield.id.DIVINE_MIGHT then
        xi.mix.jobSpecial.config(mob, {
            between = 90, -- was 30
            specials =
            {
                { id = xi.jsa.MIGHTY_STRIKES },
                { id = xi.jsa.MIJIN_GAKURE },
            },
        })
    end
end

entity.onMobEngage = function(mob, target)
    local mobid = mob:getID()

    for member = mobid, mobid + 7 do
        local m = GetMobByID(member)
        if m and m:getCurrentAction() == xi.action.category.ROAMING then
            m:updateEnmity(target)
        end
    end
end

return entity