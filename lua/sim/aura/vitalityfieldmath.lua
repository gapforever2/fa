--****************************************************************************
--** Pure health-value transitions for the Seraphim SACU Vitality Field.
--****************************************************************************

local MathMax = math.max
local MathMin = math.min

---@param currentHealth number
---@param maximumHealth number
---@param bonus number
---@return number newCurrentHealth
---@return number newMaximumHealth
function VitalityFieldApplyValues(currentHealth, maximumHealth, bonus)
    bonus = MathMax(0, bonus or 0)
    local newMaximumHealth = maximumHealth + bonus
    return MathMin(currentHealth + bonus, newMaximumHealth), newMaximumHealth
end

---@param currentHealth number
---@param maximumHealth number
---@param bonus number
---@return number newCurrentHealth
---@return number newMaximumHealth
---@return boolean lethal
function VitalityFieldRemoveValues(currentHealth, maximumHealth, bonus)
    bonus = MathMax(0, bonus or 0)
    local rawCurrentHealth = currentHealth - bonus
    local newMaximumHealth = MathMax(0, maximumHealth - bonus)
    return MathMax(0, MathMin(rawCurrentHealth, newMaximumHealth)), newMaximumHealth, rawCurrentHealth <= 0
end

---@param currentHealth number
---@param bonus number
---@return boolean
function VitalityFieldIsLethal(currentHealth, bonus)
    return currentHealth - MathMax(0, bonus or 0) <= 0
end
