--****************************************************************************
--** Pure value transitions for the Aeon SACU Shield Amplifier.
--**
--** The aura preserves the absolute amount of shield damage already taken:
--** active shields gain or lose the bonus from both current and maximum HP,
--** while a depleted/recharging shield changes maximum HP only.
--****************************************************************************

local MathMax = math.max
local MathMin = math.min

---@param currentHealth number
---@param maximumHealth number
---@param bonus number
---@param shieldIsUp boolean
---@return number newCurrentHealth
---@return number newMaximumHealth
function ShieldAmplifierApplyValues(currentHealth, maximumHealth, bonus, shieldIsUp)
    bonus = MathMax(0, bonus or 0)
    local newMaximumHealth = maximumHealth + bonus
    local newCurrentHealth = currentHealth

    if shieldIsUp then
        newCurrentHealth = MathMin(currentHealth + bonus, newMaximumHealth)
    end

    return newCurrentHealth, newMaximumHealth
end

---@param currentHealth number
---@param maximumHealth number
---@param bonus number
---@param shieldIsUp boolean
---@return number newCurrentHealth
---@return number newMaximumHealth
---@return boolean collapseShield
function ShieldAmplifierRemoveValues(currentHealth, maximumHealth, bonus, shieldIsUp)
    bonus = MathMax(0, bonus or 0)
    local newMaximumHealth = MathMax(0, maximumHealth - bonus)

    if not shieldIsUp then
        return currentHealth, newMaximumHealth, false
    end

    local newCurrentHealth = currentHealth - bonus
    if newCurrentHealth <= 0 then
        return 0, newMaximumHealth, true
    end

    return MathMin(newCurrentHealth, newMaximumHealth), newMaximumHealth, false
end
