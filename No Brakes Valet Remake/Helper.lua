--[[
#include Automatic.lua
#include Index.lua
]]

CarSelection = {
    'MOD/prefab/car1.xml',
}

function CreateVehicle()
    local loc = GetLocationTransform(CarSpawns[math.random(#CarSpawns)])
    
    Current_Vehicle = {}
    Current_Vehicle.body = Spawn(CarSelection[math.random(#CarSelection)], loc)[1]
    Current_Vehicle.vel = 50
end

function CurrentVehicleUpdate()
    if not Current_Vehicle then return end
    
    local trans = GetBodyTransform(Current_Vehicle.body)
    local center = AutoBodyBoundsCenter(Current_Vehicle.body)
    local vel = GetBodyVelocity(Current_Vehicle.body)
    local fwd = AutoTransformFwd(trans)
    local dot = AutoMap(VecDot(fwd, VecNormalize(vel)), -1, 1, 0, 0, true)

    local drive = math.max(Current_Vehicle.time / Current_Vehicle.max_time, 0) ^ 2
    local steer = -AutoPlayerInputDir(1).x
    local handbrake = InputDown('space')

    if not Current_Vehicle.control and IsPointInTrigger(CarControl, center) then
        Current_Vehicle.control = true
    end

    if not Current_Vehicle.control then
        drive = 1
        steer = 0
        handbrake = false
    end

    local rotation = QuatEuler(0, steer * 5)
    trans.rot = QuatRotateQuat(trans.rot, rotation)

    SetBodyVelocity(Current_Vehicle.body, Vec())
    SetBodyTra
    SetBodyTransform(Current_Vehicle.body, Transform(AutoVecSubsituteY(trans.pos, 2), trans.rot))

    Current_Vehicle.time = Current_Vehicle.time - GetTimeStep() * (handbrake and 5 or 1)

    if VecLength(AutoVecSubsituteY(vel, 0)) < 0.25 then
        Current_Vehicle = nil
    end
end