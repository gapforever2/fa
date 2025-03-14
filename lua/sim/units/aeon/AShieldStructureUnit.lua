--**********************************************************************************
--** Copyright (c) 2023 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--**********************************************************************************

local ShieldStructureUnit = import('/lua/defaultunits.lua').ShieldStructureUnit

---@class AShieldStructureUnit : ShieldStructureUnit
---@field Rotator? moho.RotateManipulator
AShieldStructureUnit = ClassUnit(ShieldStructureUnit) {
    RotateSpeed = 60,

    ---@param self AShieldStructureUnit
    OnShieldEnabled = function(self)
        ShieldStructureUnit.OnShieldEnabled(self)
        if not self.Rotator then
            self.Rotator = CreateRotator(self, 'Pod', 'z', nil, 0, 50, 0)
            self.Trash:Add(self.Rotator)
        end
        self.Rotator:SetSpinDown(false)
        self.Rotator:SetTargetSpeed(self.RotateSpeed)
    end,

    ---@param self AShieldStructureUnit
    OnShieldDisabled = function(self)
        ShieldStructureUnit.OnShieldDisabled(self)
        if self.Rotator then
            self.Rotator:SetTargetSpeed(0)
        end
    end,
}
