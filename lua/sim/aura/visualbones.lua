--****************************************************************************
--** Helpers for persistent aura status effects attached to moving units.
--****************************************************************************

local MathHuge = math.huge

--- Returns the bone closest to the centre of the unit's physical volume.
--- Bone zero is used as a safe fallback for meshes without usable bones.
---@param unit Unit
---@return integer
function GetClosestVisualBone(unit)
    local count = unit:GetBoneCount()
    if not count or count <= 0 then
        return 0
    end

    local bp = unit.Blueprint or unit:GetBlueprint()
    local origin = unit:GetPosition()
    local centreX = origin[1] + (bp.CollisionOffsetX or 0)
    local centreY = origin[2] + (bp.CollisionOffsetY or 0) + (bp.SizeY or 1) * 0.5
    local centreZ = origin[3] + (bp.CollisionOffsetZ or 0)
    local closestBone = 0
    local closestDistance = MathHuge

    for bone = 0, count - 1 do
        local position = unit:GetPosition(bone)
        if position then
            local dx = position[1] - centreX
            local dy = position[2] - centreY
            local dz = position[3] - centreZ
            local distance = dx * dx + dy * dy + dz * dz
            if distance < closestDistance then
                closestDistance = distance
                closestBone = bone
            end
        end
    end

    return closestBone
end
