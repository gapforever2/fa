-- The six real barrels share Turret_Fake; the stock weapon uses the same bone.
-- Callers must suspend Gun01 before handing its bones to this module.
local BarrelBones = {
    'Turret_Barrel_A_B01', 'Turret_Barrel_B_B01', 'Turret_Barrel_C_B01',
    'Turret_Barrel_D_B01', 'Turret_Barrel_E_B01', 'Turret_Barrel_F_B01',
}
-- The lift is baked into this local animation. A live slider can throttle
-- the entire bone hierarchy to sim ticks and hide continuous rotation.
local OpenAnimation = '/units/URL0401/URL0401_CopterOpen.sca'
-- Avoid a 60-degree step per sim tick: six identical blades look stationary.
local RotorSpeed = 540
local RotorAcceleration = 180
local RotorLiftHeight = 1

local function Alive(unit)
    return not unit.Dead and not unit:BeenDestroyed()
end

local function Wait(unit, ticks, cancellable)
    for tick = 1, ticks do
        WaitTicks(1)
        if not Alive(unit) or (cancellable and unit.CopterCancelTakeoff) then
            return false
        end
    end
    return true
end

local function Destroy(manipulator)
    if manipulator then
        manipulator:Destroy()
    end
end

local function ProbeRotation(unit, rotor)
    local previousAngle = rotor:GetCurrentAngle()
    -- Three bounded samples, spaced off the six-blade rotational symmetry.
    for sample = 1, 3 do
        WaitTicks(7)
        if not Alive(unit) or unit.CopterRotor ~= rotor or unit.CopterRotorStopping then
            return
        end
        local angle = rotor:GetCurrentAngle()
        local delta = math.mod(angle - previousAngle + 540, 360) - 180
        local centerX, centerY, centerZ = unit:GetPositionXYZ()
        local tipX, tipY, tipZ = unit:GetPositionXYZ('Turret_Barrel_A_B03')
        LOG(string.format('[ScathisCopter] rotor-motion id=%d sample=%d angle=%.2f delta=%.2f tip=(%.3f,%.3f,%.3f)',
            unit.EntityId, sample, angle, delta, tipX - centerX, tipY - centerY, tipZ - centerZ))
        previousAngle = angle
    end
end

-- instant is used when replacing the ground entity with its flying counterpart.
function Start(unit, instant)
    if unit.CopterRotor then
        return true
    end

    local animator = CreateAnimator(unit)
    unit.CopterAnimator = animator
    unit.Trash:Add(animator)
    animator:PlayAnim(OpenAnimation)
    animator:SetPrecedence(0)
    local fraction = instant and 1 or (unit.CopterDeployFraction or 0)
    animator:SetAnimationFraction(fraction)
    animator:SetRate(instant and 0 or 2.5)
    if not instant then
        local ticks = math.ceil((1 - fraction) * animator:GetAnimationDuration() * 4)
        if not Wait(unit, ticks + 1, true) then
            animator:SetRate(0)
            return false
        end
        animator:SetAnimationFraction(1)
        animator:SetRate(0)
    end

    LOG(string.format('[ScathisCopter] rotor-bases-raised id=%d height=%.1f mode=animation',
        unit.EntityId, RotorLiftHeight))

    -- URL0401_Aopen ends at 35 degrees above horizontal. A positive local x
    -- rotation cancels that pitch, creating six horizontal rotor blades.
    unit.CopterPitchRotators = {}
    for index, bone in BarrelBones do
        local rotator = CreateRotator(unit, bone, 'x')
        rotator:SetPrecedence(20)
        if instant then
            rotator:SetCurrentAngle(35)
        else
            rotator:SetSpeed(35)
            rotator:SetGoal(35)
        end
        unit.CopterPitchRotators[index] = rotator
        unit.Trash:Add(rotator)
    end
    if not instant and not Wait(unit, 11, true) then
        return false
    end

    local rotor = CreateRotator(unit, 'Turret_Fake', 'y')
    rotor:SetPrecedence(20)
    rotor:SetAccel(RotorAcceleration)
    if instant then
        rotor:SetSpeed(RotorSpeed)
    end
    rotor:SetTargetSpeed(RotorSpeed)
    unit.CopterRotor = rotor
    unit.CopterRotorStopping = false
    unit.Trash:Add(rotor)
    unit:ForkThread(ProbeRotation, rotor)
    LOG(string.format('[ScathisCopter] rotor-start id=%d instant=%s speed=%d',
        unit.EntityId, tostring(instant == true), RotorSpeed))
    return instant or Wait(unit, 34, true)
end

function Stop(unit, instant)
    local rotor = unit.CopterRotor
    unit.CopterRotorStopping = true
    if rotor and not instant then
        rotor:SetAccel(RotorAcceleration)
        rotor:SetTargetSpeed(0)
        if not Wait(unit, 34) then
            return false
        end
        -- Align the stopped assembly before packing the six barrels.
        rotor:SetSpeed(180)
        rotor:SetGoal(0)
        if not Wait(unit, 21) then
            return false
        end
    end
    Destroy(rotor)
    unit.CopterRotor = nil
    if not instant and unit.CopterPitchRotators then
        for index, rotator in unit.CopterPitchRotators do
            rotator:SetSpeed(35)
            rotator:SetGoal(0)
        end
        if not Wait(unit, 11) then
            return false
        end
    end
    for index, rotator in unit.CopterPitchRotators or {} do
        Destroy(rotator)
    end
    unit.CopterPitchRotators = nil

    -- Reversing the same animation lowers the bases while folding. The
    -- continuous rotor and all pitch rotators are already released here.
    local animator = unit.CopterAnimator
    if animator and not instant then
        animator:SetRate(-2.5)
        local ticks = math.ceil(animator:GetAnimationFraction() * animator:GetAnimationDuration() * 4)
        if not Wait(unit, ticks + 1) then
            return false
        end
    end
    Destroy(animator)
    unit.CopterAnimator = nil
    unit.CopterDeployFraction = nil
    unit.CopterRotorStopping = nil
    if Alive(unit) then
        LOG(string.format('[ScathisCopter] rotor-bases-lowered id=%d mode=animation', unit.EntityId))
        LOG(string.format('[ScathisCopter] rotor-stop id=%d', unit.EntityId))
    end
    return true
end
