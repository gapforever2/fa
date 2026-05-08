
--******************************************************************************************************
--** Each key press: append the next nearest on-screen friendly mass extractor (T1/T2 only; T3 and
--** upgrading/building extractors are skipped), lowest tech first then distance, skipping extractors
--** already selected, and register with the same control groups as the prior selection.
--******************************************************************************************************

local SelectionUtils = import("/lua/ui/game/selection.lua")
local GetDistanceBetweenTwoVectors = import("/lua/utilities.lua").GetDistanceBetweenTwoVectors

local EntityCategoryFilterDown = EntityCategoryFilterDown
local EntityCategoryContains = EntityCategoryContains
local GetMouseWorldPos = GetMouseWorldPos
local GetSelectedUnits = GetSelectedUnits
local SelectUnits = SelectUnits
local AddSelectUnits = AddSelectUnits
local UISelectionByCategory = UISelectionByCategory
local GetFocusArmy = GetFocusArmy

local CategoriesMex = categories.STRUCTURE * categories.MASSEXTRACTION
local TechCategories = {
    CategoriesMex * categories.TECH1,
    CategoriesMex * categories.TECH2,
}

--- T3 extractors and those with active upgrade or construction are not eligible.
---@param u UserUnit
---@return boolean
local function isEligibleMex(u)
    if EntityCategoryContains(categories.TECH3 * categories.MASSEXTRACTION, u) then
        return false
    end
    if u:GetWorkProgress() > 0 then
        return false
    end
    return true
end

---@param units UserUnit[]
---@return Vector3
local function referencePosition(units)
    local n = table.getn(units)
    if n > 0 then
        local sx, sy, sz = 0, 0, 0
        for _, u in units do
            local p = u:GetPosition()
            sx, sy, sz = sx + p[1], sy + p[2], sz + p[3]
        end
        local inv = 1 / n
        return { sx * inv, sy * inv, sz * inv }
    end
    return GetMouseWorldPos()
end

---@return UserUnit[]?
local function gatherOnScreenAllyMexes()
    SelectionUtils.EnableSelectionSound(false)
    local prior = GetSelectedUnits()
    UISelectionByCategory("MASSEXTRACTION", false, true, false, false)
    local raw = GetSelectedUnits()
    SelectUnits(prior)
    SelectionUtils.EnableSelectionSound(true)
    if not raw then
        return nil
    end
    local focusArmy = GetFocusArmy()
    local allies = {}
    for _, u in raw do
        if u:GetArmy() == focusArmy and EntityCategoryContains(CategoriesMex, u) and isEligibleMex(u) then
            table.insert(allies, u)
        end
    end
    if table.empty(allies) then
        return nil
    end
    return allies
end

---@param mex UserUnit
---@param priorSelection UserUnit[] | nil
local function appendMexToSelectionAndGroups(mex, priorSelection)
    if not priorSelection or table.empty(priorSelection) then
        SelectUnits({ mex })
        return
    end
    AddSelectUnits({ mex })
    local seenSets = {}
    for _, u in priorSelection do
        local sets = u:GetSelectionSets()
        if sets then
            for _, setName in sets do
                local key = tostring(setName)
                if not seenSets[key] then
                    seenSets[key] = true
                    SelectionUtils.AddUnitToSelectionSet(key, mex)
                end
            end
        end
    end
end

--- Picks the closest friendly on-screen mass extractor to `ref`, preferring lowest tech.
---@param ref Vector3
---@param allies UserUnit[]
---@return UserUnit | nil
local function pickNearestLowestTechMex(ref, allies)
    for _, techCat in TechCategories do
        local tier = EntityCategoryFilterDown(techCat, allies)
        if not table.empty(tier) then
            local best = tier[1]
            local bestDist = GetDistanceBetweenTwoVectors(ref, best:GetPosition())
            for i = 2, table.getn(tier) do
                local u = tier[i]
                local d = GetDistanceBetweenTwoVectors(ref, u:GetPosition())
                if d < bestDist then
                    best, bestDist = u, d
                end
            end
            return best
        end
    end
end

function SelectNearestLowestMexAndAddToGroup()
    local priorSelection = GetSelectedUnits()
    local ref = referencePosition(priorSelection or {})
    local allies = gatherOnScreenAllyMexes()
    if not allies then
        return
    end

    local already = {}
    if priorSelection then
        for _, u in priorSelection do
            if EntityCategoryContains(CategoriesMex, u) then
                already[u] = true
            end
        end
    end

    local pool = {}
    for _, u in allies do
        if not already[u] then
            table.insert(pool, u)
        end
    end
    if table.empty(pool) then
        return
    end

    local mex = pickNearestLowestTechMex(ref, pool)
    if not mex then
        return
    end

    appendMexToSelectionAndGroups(mex, priorSelection)
end
