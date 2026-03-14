/*
===========================================================================

  Copyright (c) 2010-2015 Darkstar Dev Teams

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see http://www.gnu.org/licenses/

===========================================================================
*/

#include "range_state.h"

#include "action/action.h"
#include "action/interrupts.h"
#include "ai/ai_container.h"
#include "entities/charentity.h"
#include "entities/trustentity.h"
#include "enums/action/category.h"
#include "items/item_weapon.h"
#include "packets/s2c/0x028_battle2.h"
#include "packets/s2c/0x029_battle_message.h"
#include "status_effect_container.h"
#include "utils/battleutils.h"
#include "utils/charutils.h"

namespace
{
static void DebugTrustRangeFail(CBattleEntity* PEntity, const char* reason, MsgBasic msg = MsgBasic::NONE)
{
    if (PEntity && PEntity->objtype == TYPE_TRUST)
    {
        if (msg != MsgBasic::NONE)
        {
            ShowDebug("[TRUST][RANGE] %s: %s (MsgBasic=%u)", PEntity->getName(), reason, static_cast<uint16>(msg));
        }
        else
        {
            ShowDebug("[TRUST][RANGE] %s: %s", PEntity->getName(), reason);
        }
    }
}
} // namespace

CRangeState::CRangeState(CBattleEntity* PEntity, uint16 targid)
: CState(PEntity, targid)
, m_PEntity(PEntity)
{
    auto* PTarget = m_PEntity->IsValidTarget(m_targid, TARGET_ENEMY, m_errorMsg);

    if (!PTarget || this->HasErrorMsg())
    {
        DebugTrustRangeFail(m_PEntity, "invalid target or HasErrorMsg() during IsValidTarget()");
        if (this->HasErrorMsg())
        {
            throw CStateInitException(m_errorMsg->copy());
        }
        else
        {
            throw CStateInitException(std::make_unique<CBasicPacket>());
        }
    }

    if (!CanUseRangedAttack(PTarget, false))
    {
        // CanUseRangedAttack will have filled m_errorMsg with a battle message.
        DebugTrustRangeFail(m_PEntity, "CanUseRangedAttack() returned false at start");
        if (this->HasErrorMsg())
        {
            throw CStateInitException(m_errorMsg->copy());
        }
        else
        {
            throw CStateInitException(std::make_unique<CBasicPacket>());
        }
    }

    if (distance(m_PEntity->loc.p, PTarget->loc.p) > 25)
    {
        DebugTrustRangeFail(m_PEntity, "target too far away (>25)");
        m_errorMsg = std::make_unique<GP_SERV_COMMAND_BATTLE_MESSAGE>(m_PEntity, PTarget, 0, 0, MsgBasic::TOO_FAR_AWAY);
        throw CStateInitException(m_errorMsg->copy());
    }

    // https://www.bg-wiki.com/ffxi/Delay#Ranged_Delay
    auto delay = m_PEntity->GetRangedWeaponDelay(false);

    // Trust hardening: if ranged delay isn't available, use a sane baseline so aim time isn't 0ms.
    if (m_PEntity->objtype == TYPE_TRUST && delay <= 0)
    {
        DebugTrustRangeFail(m_PEntity, "GetRangedWeaponDelay(false) <= 0; applying fallback delay");
        delay = 3000;
    }

    delay = battleutils::GetRangedDelayReduction(m_PEntity, delay);

    // Rapid Shot
    if (m_PEntity->objtype == TYPE_PC || m_PEntity->objtype == TYPE_TRUST)
    {
        CItemWeapon* weapon     = dynamic_cast<CItemWeapon*>(m_PEntity->m_Weapons[SLOT_RANGED]);
        bool         isThrowing = weapon && weapon->isThrowing();
        // Don't apply Rapid Shot to throwing weapons
        if (!isThrowing)
        {
            auto chance{ m_PEntity->getMod(Mod::RAPID_SHOT) };

            if (auto* PChar = dynamic_cast<CCharEntity*>(m_PEntity))
            {
                chance += PChar->PMeritPoints->GetMeritValue(MERIT_RAPID_SHOT_RATE, PChar);
            }

            // Don't bother if we cant even proc
            if (chance > 0)
            {
                if (xirand::GetRandomNumber(100) < chance)
                {
                    delay       = (int16)(delay * (1.0f - xirand::GetRandomNumber<uint16>(2, 50) / 100.0f));
                    m_rapidShot = true;
                }
            }
        }
    }

    m_aimTime  = std::chrono::milliseconds(delay);
    m_startPos = m_PEntity->loc.p;

    action_t action{
        .actorId    = m_PEntity->id,
        .actiontype = ActionCategory::RangedStart,
        .actionid   = static_cast<uint32_t>(FourCC::RangedStart),
        .targets    = {
            {
                   .actorId = m_PEntity->id,
                   .results = {
                    {
                        // Empty result
                    },
                },
            },
        },
    };

    m_PEntity->PAI->EventHandler.triggerListener("RANGE_START", m_PEntity, &action);
    m_PEntity->loc.zone->PushPacket(m_PEntity, CHAR_INRANGE_SELF, std::make_unique<GP_SERV_COMMAND_BATTLE2>(action));
}

void CRangeState::SpendCost()
{
}

bool CRangeState::CanChangeState()
{
    return false;
}

bool CRangeState::Update(timer::time_point tick)
{
    if (m_PEntity && m_PEntity->isAlive() && (tick > GetEntryTime() + m_aimTime && !IsCompleted()))
    {
        auto* PTarget = m_PEntity->IsValidTarget(m_targid, TARGET_ENEMY, m_errorMsg);

        CanUseRangedAttack(PTarget, true);

        if (HasMoved())
        {
            DebugTrustRangeFail(m_PEntity, "HasMoved() interrupted ranged attack", MsgBasic::MOVE_AND_INTERRUPT);
            m_errorMsg = std::make_unique<GP_SERV_COMMAND_BATTLE_MESSAGE>(m_PEntity, m_PEntity, 0, 0, MsgBasic::MOVE_AND_INTERRUPT);
        }

        action_t action{};
        auto*    cast_errorMsg = dynamic_cast<GP_SERV_COMMAND_BATTLE_MESSAGE*>(m_errorMsg.get());
        if (m_errorMsg && (!cast_errorMsg || cast_errorMsg->getMessageId() != MsgBasic::CANNOT_SEE))
        {
            if (auto* PChar = dynamic_cast<CCharEntity*>(m_PEntity))
            {
                PChar->pushPacket(m_errorMsg->copy());
            }

            m_aimTime = 0s;
            ActionInterrupts::RangedInterrupt(m_PEntity);
            m_PEntity->PAI->EventHandler.triggerListener("RANGE_STATE_EXIT", m_PEntity, nullptr, &action);
        }
        else
        {
            m_errorMsg.reset();

            if (!PTarget || distance(m_PEntity->loc.p, PTarget->loc.p) > 25)
            {
                m_isOutOfRange = true;
            }

            m_PEntity->OnRangedAttack(*this, action);
            if (!action.targets.empty())
            {
                m_PEntity->loc.zone->PushPacket(m_PEntity, CHAR_INRANGE_SELF, std::make_unique<GP_SERV_COMMAND_BATTLE2>(action));
            }
            m_PEntity->PAI->EventHandler.triggerListener("RANGE_STATE_EXIT", m_PEntity, PTarget, &action);
        }

        Complete();
    }

    if (IsCompleted() && tick > GetEntryTime() + m_aimTime + m_returnWeaponDelay)
    {
        if (auto* PChar = dynamic_cast<CCharEntity*>(m_PEntity))
        {
            PChar->m_LastRangedAttackTime = GetEntryTime() + m_aimTime + m_returnWeaponDelay;
        }
        return true;
    }

    return false;
}

void CRangeState::Cleanup(timer::time_point tick)
{
}

bool CRangeState::CanUseRangedAttack(CBattleEntity* PTarget, bool isEndOfAttack)
{
    if (!PTarget)
    {
        DebugTrustRangeFail(m_PEntity, "no target", MsgBasic::CANNOT_ATTACK_TARGET);
        m_errorMsg = std::make_unique<GP_SERV_COMMAND_BATTLE_MESSAGE>(m_PEntity, m_PEntity, 0, 0, MsgBasic::CANNOT_ATTACK_TARGET);
        return false;
    }

    if (auto* PChar = dynamic_cast<CCharEntity*>(m_PEntity))
    {
        CItemWeapon* PRanged = dynamic_cast<CItemWeapon*>(PChar->getEquip(SLOT_RANGED));
        CItemWeapon* PAmmo   = dynamic_cast<CItemWeapon*>(PChar->getEquip(SLOT_AMMO));

        if (!((PRanged && PRanged->isType(ITEM_WEAPON)) || (PAmmo && PAmmo->isThrowing())))
        {
            m_errorMsg = std::make_unique<GP_SERV_COMMAND_BATTLE_MESSAGE>(PChar, PChar, 0, 0, MsgBasic::NO_RANGED_WEAPON);
            return false;
        }

        auto SkillType = PRanged ? PRanged->getSkillType() : PAmmo->getSkillType();

        switch (SkillType)
        {
            case SKILL_THROWING:
            {
                PChar->StatusEffectContainer->DelStatusEffect(EFFECT_BARRAGE);
                break;
            }
            case SKILL_ARCHERY:
            case SKILL_MARKSMANSHIP:
            {
                PRanged = dynamic_cast<CItemWeapon*>(PChar->getEquip(SLOT_AMMO));
                if (PRanged != nullptr && PRanged->isType(ITEM_WEAPON))
                {
                    break;
                }
                else
                {
                    m_errorMsg = std::make_unique<GP_SERV_COMMAND_BATTLE_MESSAGE>(PChar, PChar, 0, 0, MsgBasic::NO_RANGED_WEAPON);
                    return false;
                }
            }
            default:
            {
                m_errorMsg = std::make_unique<GP_SERV_COMMAND_BATTLE_MESSAGE>(PChar, PChar, 0, 0, MsgBasic::NO_RANGED_WEAPON);
                return false;
            }
        }
    }

    if (!facing(m_PEntity->loc.p, PTarget->loc.p, 64))
    {
        DebugTrustRangeFail(m_PEntity, "not facing target", MsgBasic::CANNOT_SEE);
        m_errorMsg = std::make_unique<GP_SERV_COMMAND_BATTLE_MESSAGE>(m_PEntity, PTarget, 0, 0, MsgBasic::CANNOT_SEE);
        return false;
    }

    if (!isEndOfAttack && !m_PEntity->CanSeeTarget(PTarget, false))
    {
        DebugTrustRangeFail(m_PEntity, "cannot see target (CanSeeTarget failed)", MsgBasic::CANNOT_PERFORM_ACTION);
        m_errorMsg = std::make_unique<GP_SERV_COMMAND_BATTLE_MESSAGE>(m_PEntity, PTarget, 0, 0, MsgBasic::CANNOT_PERFORM_ACTION);
        return false;
    }

    if (auto PChar = dynamic_cast<CCharEntity*>(m_PEntity))
    {
        if (m_PEntity->PAI->getTick() - PChar->m_LastRangedAttackTime < m_freePhaseTime)
        {
            m_errorMsg = std::make_unique<GP_SERV_COMMAND_BATTLE_MESSAGE>(m_PEntity, PTarget, 0, 0, MsgBasic::WAIT_LONGER);
            return false;
        }
    }

    uint8 anim = m_PEntity->animation;
    if (anim != ANIMATION_NONE && anim != ANIMATION_ATTACK)
    {
        DebugTrustRangeFail(m_PEntity, "bad animation state for ranged", MsgBasic::CANNOT_PERFORM_ACTION);
        m_errorMsg = std::make_unique<GP_SERV_COMMAND_BATTLE_MESSAGE>(m_PEntity, PTarget, 0, 0, MsgBasic::CANNOT_PERFORM_ACTION);
        return false;
    }

    return true;
}

bool CRangeState::HasMoved()
{
    return floorf(m_startPos.x * 10 + 0.5f) / 10 != floorf(m_PEntity->loc.p.x * 10 + 0.5f) / 10 ||
           floorf(m_startPos.y * 10 + 0.5f) / 10 != floorf(m_PEntity->loc.p.y * 10 + 0.5f) / 10 ||
           floorf(m_startPos.z * 10 + 0.5f) / 10 != floorf(m_PEntity->loc.p.z * 10 + 0.5f) / 10;
}