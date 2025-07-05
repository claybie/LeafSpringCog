-----------------------------------
-- Area: RuAun_Gardens
--  NPC: HomePoint#4
-- !pos 500 -42 158 130
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    local menu =
    {
        title   = "What will you do?",
        onStart = function(playerArg)
	playerArg:printToPlayer("A home point can be set as a spot for you to return to when you have been K.O.'d", xi.msg.channel.NS_SAY)
        end,

        options =
        {
            {
                "Set this as your home point.",
                function(playerArg)
                    playerArg:printToPlayer("Home point set!", xi.msg.channel.NS_SAY)
                    playerArg:setHomePoint()
		    playerArg:independentAnimation(playerArg, 43, 3)
                end,
            },
            {
                "On second thought, never mind.",
                function(playerArg)
                end,
            },
        },

        onCancelled = function(playerArg)
        end,

        onEnd = function(playerArg)
        end,
    }
    player:customMenu(menu)
end

entity.onEventUpdate = function(player, csid, option)
end

entity.onEventFinish = function(player, csid, option)
end

return entity
