-----------------------------------
-- ID: 15533
-- Item: Chocobo Whistle
--
-- Customized:
--   - Keep chocobo license behavior in place (required to use)
--   - Require at least one job level 60+ to use as a mount call
-----------------------------------
---@type TItem
local itemObject = {}

local function hasAnyJobLevelAtLeast(player, level)
    for jobId = 1, (xi.MAX_JOB_TYPE - 1) do
        if player:getJobLevel(jobId) >= level then
            return true
        end
    end

    return false
end

itemObject.onItemCheck = function(target, item, param, caster)
    if not target:canUseMisc(xi.zoneMisc.MOUNT) then
        return xi.msg.basic.CANT_BE_USED_IN_AREA
    end

    -- Leave chocobo license (renting) behavior intact: still required to use the whistle.
    if not target:hasKeyItem(xi.ki.CHOCOBO_LICENSE) or target:hasEnmity() then
        return xi.msg.basic.ITEM_UNABLE_TO_USE -- Todo: Verify/correct message, order of message priority.
    end

    -- New rule: must have at least one job at level 60+ (job does not need to be active).
    if not hasAnyJobLevelAtLeast(target, 60) then
        return xi.msg.basic.ITEM_UNABLE_TO_USE
    end

    return 0
end

itemObject.onItemUse = function(target)
    -- Base duration 30 min, in seconds.
    local duration = 1800 + (target:getMod(xi.mod.CHOCOBO_RIDING_TIME) * 60)
    target:addStatusEffectEx(xi.effect.MOUNTED, xi.effect.MOUNTED, xi.mount.CHOCOBO, 0, duration, 0, 64, true)
end

return itemObject