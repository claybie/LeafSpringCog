-----------------------------------
-- Area: Upper Jeuno
--  NPC: Mapitoto
-- Type: Mount KI trade npc
-- !pos -54.310 8.200 85.940 244
-----------------------------------
local ID = zones[xi.zone.UPPER_JEUNO]
-----------------------------------
---@type TNpcEntity
local entity = {}

local function hasAnyJobLevelAtLeast(player, level)
    -- Iterate all playable jobs (1..xi.MAX_JOB_TYPE-1), ignore NONE=0
    for jobId = 1, (xi.MAX_JOB_TYPE - 1) do
        if player:getJobLevel(jobId) >= level then
            return true
        end
    end

    return false
end

entity.onTrade = function(player, npc, trade)
    -- Must be 60+ on at least one job to obtain mounts via this NPC.
    if not hasAnyJobLevelAtLeast(player, 60) then
        -- No custom text ID; silently ignore trade (or you can add a messageSpecial if you have one).
        return
    end

    if trade:getSlotCount() ~= 1 then
        return
    end

    -- The Fenrir (10057) and Omega (10067) items and mounts have their own questlines, so they aren't valid trades here
    if npcUtil.tradeHasExactly(trade, xi.item.MOUNT_FENRIR) or npcUtil.tradeHasExactly(trade, xi.item.MOUNT_OMEGA) then
        return
    end

    local item  = trade:getItemId(0)
    local mount = item - xi.item.MOUNT_TIGER

    if item == xi.item.CHOCOBO_WHISTLE then
        player:startEvent(10227, xi.item.CHOCOBO_WHISTLE, 0, xi.mount.CHOCOBO)
        player:setLocalVar('MountTradeRewardKI', xi.ki.CHOCOBO_COMPANION)

    elseif item == xi.item.RED_RAPTOR_NOTEBOOK then
        -- Key Items, Items, and Mount IDs don't line up for 4 mounts starting with Red Raptor
        player:setLocalVar('MountTradeRewardKI', xi.ki.TIGER_COMPANION + mount + 3)
        player:startEvent(10227, item, 0, xi.mount.TIGER + mount + 2)

    elseif item >= xi.item.GOLDEN_BOMB_NOTEBOOK and item <= xi.item.WIVRE_NOTEBOOK then
        -- These are all offset by one due to Red Raptor
        player:setLocalVar('MountTradeRewardKI', xi.ki.TIGER_COMPANION + mount - 1)
        player:startEvent(10227, item, 0, xi.mount.TIGER + mount - 2)

    elseif mount >= xi.mount.CHOCOBO and mount <= xi.mount.MOUNT_MAX then
        player:setLocalVar('MountTradeRewardKI', xi.ki.TIGER_COMPANION + mount)
        player:startEvent(10227, item, 0, xi.mount.TIGER + mount - 1)
    end
end

entity.onTrigger = function(player, npc)
    -- No minigame quest for obtaining mounts; stipulation is to trade KI and be level 60+
    -- If you want dialogue, wire it to an event; otherwise do nothing.
    return
end

entity.onEventFinish = function(player, csid, option, npc)
    if csid ~= 10227 then
        return
    end

    local rewardKI = player:getLocalVar('MountTradeRewardKI')
    player:setLocalVar('MountTradeRewardKI', 0)

    if rewardKI == 0 then
        return
    end

    if rewardKI == xi.ki.CHOCOBO_COMPANION then
        -- NOTE: This does not consume the whistle, do not take it!
        -- TODO: Get chocobo visual information from whistle
        -- TODO: player:registerChocobo(info)
    else
        player:tradeComplete()
    end

    npcUtil.giveKeyItem(player, rewardKI)
end

return entity