--[[
#include Automatic.lua
#include main.lua
]]

------------------------------------------------------------------------------------------------------------------------------------------------------

function InitializeLevel(index)
    AddLevelEntities(Spawn('level/' .. LvlBank[index] .. '.xml', Transform(Vec(0, 20, 0)), true, false))

    QueFunction("SetPlayerTransform(GetLocationTransform(FindLocation('Player', true)), true)", 0.0125)
    
    AllLights = FindLights(nil, true)
    for _, v in pairs(AllLights) do
        if HasTag(v, 'sight') then
            SightLights[#SightLights + 1] = {
                light = v,
                intensity = 0,
                seen = 0
            }
        end
    end
end

------------------------------------------------------------------------------------------------------------------------------------------------------

function QueFunction(funcstring, time)
    local count = #ListKeys('level.functionque')
    SetString('level.functionque.' .. count + 1 .. '.function', funcstring)
    SetFloat('level.functionque.' .. count + 1 .. '.time', time)
end

function ProccesFunctionQue()
    local dt = GetTimeStep()
    local keys = ListKeys('level.functionque')

    for _, index in ipairs(keys) do
        local t = GetFloat('level.functionque.' .. index .. '.time') - dt
        SetFloat('level.functionque.' .. index .. '.time', t)

        if t <= 0 then
            local f = GetString('level.functionque.' .. index .. '.function')
            loadstring(f)()
            -- AutoPrint(index, f)
            ClearKey('level.functionque.' .. index)
        end
    end
end

function AddLevelEntities(entities)
    for _, e in ipairs(entities) do
        if HasKey('level.entities') then
            local s = GetString('level.entities')
            SetString('level.entities', s .. ' ' .. e)
        else
            SetString('level.entities', e)
        end
    end
end

function DeleteLevel()
    if not HasKey('level.entities') then return end

    local list = AutoSplit(GetString('level.entities'), ' ')
    for _, s in pairs(list) do
        local n = tonumber(s)
        if n and IsHandleValid(n) then
            Delete(n)
        end
    end

    ClearKey('level.entities')
end

------------------------------------------------------------------------------------------------------------------------------------------------------

function DisableTools()
    local tools = ListKeys('game.tool')
    for _, tool in pairs(tools) do
        if AutoSplit(tool, ' ')[1] ~= "reality" then
            SetBool('game.tool.' .. tool .. '.enabled', false)
        end
    end

    SetString('game.player.tool', 'none')
end

function RemoveFlashLight()
    local lights = FindLights('', true)
    for i = 1, #lights do
        local light = lights[i]
        local trans = GetLightTransform(light)
        local pos = trans.pos
        local rot = trans.rot
        if (
            pos[1] == 0
                and pos[2] == 0
                and pos[3] == 0
                and rot[1] == 0
                and rot[2] == 0
                and rot[3] == 0
                and rot[4] == 1
            ) then
            SetLightIntensity(light, 0)
            break
        end
    end
end

------------------------------------------------------------------------------------------------------------------------------------------------------

function ClosestLight()
    local camera = GetCameraTransform()
    local dist = math.huge
    local best = 0

    for i, v in ipairs(AllLights) do
        local d = AutoVecDist(camera.pos, GetLightTransform(v).pos)
        if d < dist then
            best = i
            dist = d
        end
    end

    return best
end

------------------------------------------------------------------------------------------------------------------------------------------------------

function BoundsToPointArray(aa, bb, t, steps)
    transform = AutoDefault(transform, QuatEuler(0, 0, 0))
    steps = AutoDefault(steps, Vec(5, 5, 5))

    if table.concat(aa) == table.concat(bb) then return {} end

    local points = {}
    for z = -1, 1, 1 / math.max(1, steps[1]) * 2 do
        for y = -1, 1, 1 / math.max(1, steps[2]) * 2 do
            for x = -1, 1, 1 / math.max(1, steps[3]) * 2 do
                local p = AutoBoundsGetPos(aa, bb, Vec(x, y, z))
                p = TransformToLocalPoint(Transform(t.pos), p)
                points[#points+1] = p
            end
        end
    end

    return points
end

function ConvertLocalPointArray(points, trans)
    local translatedPoints = {}
    for _, p in pairs(points) do
        translatedPoints[#translatedPoints+1] = TransformToParentPoint(trans, p)
    end
    return translatedPoints
end

function CheckForSight(listofpoints, Params)
    if Params.Eyes then
        if GetFloat('level.wetfloors.eyes') <= 0 then
            return false
        end
    end
    
    if Params.Sight then
        for _, p in pairs(listofpoints) do
            local v = AutoPointInView(p, nil, GetFloat('level.wetfloors.fov'), true, Params.RayCastError)
            if Params.Debug then
                DebugCross(p, 1, v and 0 or 1, v and 0 or 1, 1)
            else
                if v then
                    return true
                end
            end
        end
    end

    return false
end

------------------------------------------------------------------------------------------------------------------------------------------------------

function PlayRandomSound(list)
    PlaySound(list[math.random(1, #list)])
end

------------------------------------------------------------------------------------------------------------------------------------------------------

function AnyKeyPressed()
    local lkp = InputLastPressedKey()
    if InputPressed(lkp) then
        return true, lkp
    end
    return false
end