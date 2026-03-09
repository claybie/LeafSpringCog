-- scripts/zones/LaLoff_Amphitheater/npcs/qm1_1.lua
-----------------------------------
-- Area: LaLoff Amphitheater
--  NPC: qm1_1 (Shimmering Circle)
-- Battlefield entrance (Ark Angels / Divine Might)
-----------------------------------
local ID = zones[xi.zone.LALOFF_AMPHITHEATER]

require('scripts/globals/battlefield')

---@type TNpcEntity
local entity = {}

local function openMenuOrMessage(player, npc, trade)
    local options = xi.battlefield.getBattlefieldOptions(player, npc, trade)

    -- GM override (same logic as Battlefield.onEntryTrigger)
    if trade == nil and player:getGMLevel() > 0 and player:getVisibleGMLevel() >= 3 then
        options = 268435455
    end

    if options == 0 then
        local noEntryMessage = ID.text.NO_BATTLEFIELD_ENTRY
        if noEntryMessage then
            player:messageSpecial(noEntryMessage)
        end
        return
    end

    player:startEvent(32000, 0, 0, 0, options, 0, 0, 0, 0)
end

entity.onTrade = function(player, npc, trade)
    -- Mirror Battlefield.onEntryTrade’s early guards (lightweight)
    if not trade then
        return
    end

    if xi.battlefield.rejectLevelSyncedParty(player, npc) then
        return
    end

    -- If any party member has battlefield effect, deny (Battlefield.onEntryTrade behavior)
    for _, member in pairs(player:getAlliance()) do
        if member:hasStatusEffect(xi.effect.BATTLEFIELD) then
            player:messageBasic(xi.msg.basic.WAIT_LONGER, 0, 0)
            return
        end
    end

    openMenuOrMessage(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    if xi.battlefield.rejectLevelSyncedParty(player, npc) then
        return
    end

    -- If player already has battlefield status effect, let Battlefield.lua handle the “enter existing” menu
    if player:hasStatusEffect(xi.effect.BATTLEFIELD) then
        Battlefield.onEntryTrigger(player, npc)
        return
    end

    -- If another member has battlefield effect, show engaged message
    for _, member in pairs(player:getAlliance()) do
        if member:hasStatusEffect(xi.effect.BATTLEFIELD) then
            player:messageSpecial(ID.text.PARTY_MEMBERS_ARE_ENGAGED)
            return
        end
    end

    openMenuOrMessage(player, npc, nil)
end

entity.onEventUpdate = function(player, csid, option, npc)
    if csid == 32000 then
        Battlefield.redirectEventUpdate(player, csid, option, npc)
    elseif csid == 32003 then
        Battlefield.redirectEventCall('onExitEventUpdate', player, csid, option)
    end
end

entity.onEventFinish = function(player, csid, option, npc)
    if csid == 32000 then
        Battlefield.redirectEventCall('onEventFinishEnter', player, csid, option)
    elseif csid == 32001 then
        Battlefield.redirectEventCall('onEventFinishWin', player, csid, option)
    elseif csid == 32002 then
        Battlefield.redirectEventCall('onEventFinishLeave', player, csid, option)
    elseif csid == 32003 then
        Battlefield.redirectEventCall('onEventFinishExit', player, csid, option)
    elseif csid == 32004 then
        Battlefield.redirectEventCall('onEventFinishBattlefield', player, csid, option)
    end
end

return entity
