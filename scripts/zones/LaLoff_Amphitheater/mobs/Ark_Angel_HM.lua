-----------------------------------
-- Area: LaLoff Amphitheater
--  Mob: Ark Angel HM
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
    mob:setMobMod(xi.mobMod.DUAL_WIELD, 1)
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
        between = 30,
        specials =
        {
            { id = xi.jsa.MIGHTY_STRIKES },
            { id = xi.jsa.MIJIN_GAKURE },
        },
    })
end

entity.onMobEngage = function(mob, target)
    local mobid = mob:getID()

    -- Divine Might: block the immediate pile-on for the first 15s of the fight
    if dmLinkUnlocked(mob) then
        for member = mobid, mobid + 7 do
            local m = GetMobByID(member)
            if m and m:getCurrentAction() == xi.action.category.ROAMING then
                m:updateEnmity(target)
            end
        end
    end
end

return entity